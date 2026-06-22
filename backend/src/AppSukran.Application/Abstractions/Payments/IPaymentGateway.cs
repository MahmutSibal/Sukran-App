namespace AppSukran.Application.Abstractions.Payments;

/// <summary>Tahsilat için kullanılacak kart bilgileri (charge anında).</summary>
public sealed record PaymentCard(
    string CardHolderName,
    string CardNumber,
    int ExpiryMonth,
    int ExpiryYear,
    string? Cvc,
    string Brand,
    string Last4);

/// <summary>Bir ödeme sağlayıcısına yapılacak tahsilat isteği. Tutar kuruş (minor) cinsindendir.
/// Para birimi sağlayıcının kendi ayarından (PaymentSettings.Currency) okunur.</summary>
public sealed record ChargeRequest(
    string BillId,
    string RestaurantId,
    int TableNo,
    long AmountMinor,
    string PaidByUserId,
    PaymentCard Card);

/// <summary>Tahsilat sonucu. Başarısızsa <see cref="ErrorCode"/>/<see cref="ErrorMessage"/> doldurulur.</summary>
public sealed record ChargeResult(
    bool Success,
    string Status,
    string? TransactionId,
    string Provider,
    string? ErrorCode = null,
    string? ErrorMessage = null)
{
    public static ChargeResult Ok(string transactionId, string provider) =>
        new(true, "Success", transactionId, provider);

    public static ChargeResult Fail(string errorCode, string errorMessage, string provider) =>
        new(false, "Failed", null, provider, errorCode, errorMessage);
}

/// <summary>
/// Ödeme sağlayıcısı soyutlaması. Somut implementasyonlar Infrastructure katmanındadır
/// (FakePaymentGateway, IyzicoPaymentGateway). Handler'lar bu arayüzü kullanır,
/// sağlayıcıdan habersizdir.
/// </summary>
public interface IPaymentGateway
{
    string Provider { get; }

    Task<ChargeResult> ChargeAsync(ChargeRequest request, CancellationToken cancellationToken = default);
}
