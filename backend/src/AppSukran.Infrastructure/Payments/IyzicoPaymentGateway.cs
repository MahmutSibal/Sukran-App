using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using AppSukran.Application.Abstractions.Payments;
using AppSukran.Infrastructure.Settings;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace AppSukran.Infrastructure.Payments;

/// <summary>
/// iyzico (gerçek PSP) ödeme sağlayıcısı. iyzico hesabı geldiğinde:
///   1) appsettings: "Payment:Provider" = "Iyzico"
///   2) "Payment:Iyzico:ApiKey" / "SecretKey" / "BaseUrl" doldurulur
/// Kod değişikliği gerekmez. Kimlik bilgisi yoksa açık bir hata fırlatır;
/// asla sessizce "başarılı" dönmez.
///
/// Burada iyzico'nun dokümante ettiği IYZWSv2 (HMAC-SHA256) imzalama şeması ile
/// /payment/auth uç noktasına istek atılır. Canlıya almadan önce buyer/adres
/// alanlarının iyzico üye iş yeri gereksinimlerine göre doldurulması gerekir
/// (aşağıdaki TODO).
/// </summary>
public sealed class IyzicoPaymentGateway(
    HttpClient httpClient,
    IOptions<PaymentSettings> options,
    ILogger<IyzicoPaymentGateway> logger) : IPaymentGateway
{
    public string Provider => "Iyzico";

    public async Task<ChargeResult> ChargeAsync(ChargeRequest request, CancellationToken cancellationToken = default)
    {
        var settings = options.Value.Iyzico;
        if (!settings.IsConfigured)
        {
            // Sağlayıcı "Iyzico" seçilmiş ama anahtarlar girilmemiş — sessiz geçmek yerine net hata.
            throw new InvalidOperationException(
                "iyzico sağlayıcısı seçili ancak yapılandırılmamış. " +
                "appsettings içinde Payment:Iyzico:ApiKey ve SecretKey değerlerini girin.");
        }

        const string uriPath = "/payment/auth";
        var price = (request.AmountMinor / 100m).ToString("0.00", System.Globalization.CultureInfo.InvariantCulture);

        // TODO(iyzico): buyer/billingAddress alanlarını gerçek müşteri verisiyle doldurun.
        // iyzico üye iş yeri kuralları bu alanları zorunlu kılar; şu an türetilmiş/placeholder değerler kullanılıyor.
        var body = new
        {
            locale = "tr",
            conversationId = request.BillId,
            price,
            paidPrice = price,
            currency = options.Value.Currency,
            installment = 1,
            paymentChannel = "MOBILE",
            paymentGroup = "PRODUCT",
            paymentCard = new
            {
                cardHolderName = request.Card.CardHolderName,
                cardNumber = new string(request.Card.CardNumber.Where(char.IsDigit).ToArray()),
                expireMonth = request.Card.ExpiryMonth.ToString("00"),
                expireYear = request.Card.ExpiryYear.ToString(),
                cvc = request.Card.Cvc ?? string.Empty,
                registerCard = 0,
            },
            buyer = new
            {
                id = request.PaidByUserId,
                name = request.Card.CardHolderName,
                surname = request.Card.CardHolderName,
                identityNumber = "11111111111",
                email = $"{request.PaidByUserId}@appsukran.local",
                registrationAddress = "Masa " + request.TableNo,
                city = "Istanbul",
                country = "Turkey",
                ip = "0.0.0.0",
            },
            billingAddress = new
            {
                contactName = request.Card.CardHolderName,
                city = "Istanbul",
                country = "Turkey",
                address = "Masa " + request.TableNo,
            },
            basketItems = new[]
            {
                new
                {
                    id = request.BillId,
                    name = "Adisyon",
                    category1 = "Restoran",
                    itemType = "PHYSICAL",
                    price,
                },
            },
        };

        var json = JsonSerializer.Serialize(body);

        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, settings.BaseUrl.TrimEnd('/') + uriPath)
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json"),
        };
        AddIyziAuthHeaders(httpRequest, settings, uriPath, json);

        try
        {
            using var response = await httpClient.SendAsync(httpRequest, cancellationToken);
            var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);

            using var doc = JsonDocument.Parse(responseBody);
            var root = doc.RootElement;
            var status = root.TryGetProperty("status", out var s) ? s.GetString() : null;

            if (response.IsSuccessStatusCode && string.Equals(status, "success", StringComparison.OrdinalIgnoreCase))
            {
                var paymentId = root.TryGetProperty("paymentId", out var p) ? p.GetString() : null;
                return ChargeResult.Ok(paymentId ?? request.BillId, Provider);
            }

            var errorCode = root.TryGetProperty("errorCode", out var ec) ? ec.GetString() : "iyzico_error";
            var errorMessage = root.TryGetProperty("errorMessage", out var em) ? em.GetString() : "iyzico ödemesi reddedildi.";
            logger.LogWarning("[Iyzico] Charge failed bill={BillId} code={Code} msg={Msg}", request.BillId, errorCode, errorMessage);
            return ChargeResult.Fail(errorCode ?? "iyzico_error", errorMessage ?? "iyzico ödemesi reddedildi.", Provider);
        }
        catch (Exception ex) when (ex is not InvalidOperationException)
        {
            logger.LogError(ex, "[Iyzico] Charge request error bill={BillId}", request.BillId);
            return ChargeResult.Fail("iyzico_network_error", "iyzico'ya ulaşılamadı: " + ex.Message, Provider);
        }
    }

    /// <summary>iyzico IYZWSv2 (HMAC-SHA256) yetkilendirme başlıklarını ekler.</summary>
    private static void AddIyziAuthHeaders(HttpRequestMessage httpRequest, IyzicoSettings settings, string uriPath, string requestBody)
    {
        var randomKey = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() + Guid.NewGuid().ToString("N")[..8];
        var payload = randomKey + uriPath + requestBody;

        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(settings.SecretKey));
        var signatureBytes = hmac.ComputeHash(Encoding.UTF8.GetBytes(payload));
        var signature = Convert.ToHexString(signatureBytes).ToLowerInvariant();

        var authorizationParams = $"apiKey:{settings.ApiKey}&randomKey:{randomKey}&signature:{signature}";
        var encoded = Convert.ToBase64String(Encoding.UTF8.GetBytes(authorizationParams));

        httpRequest.Headers.TryAddWithoutValidation("Authorization", "IYZWSv2 " + encoded);
        httpRequest.Headers.TryAddWithoutValidation("x-iyzi-rnd", randomKey);
    }
}
