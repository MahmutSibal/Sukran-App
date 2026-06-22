namespace AppSukran.Infrastructure.Settings;

/// <summary>
/// Ödeme altyapısı ayarları. Sağlayıcı çalışma anında seçilir:
/// "Fake" (yerleşik simülasyon, varsayılan) veya "Iyzico" (gerçek PSP).
/// iyzico hesabı geldiğinde sadece appsettings'te Provider="Iyzico" yapıp
/// ApiKey/SecretKey girilmesi yeterlidir; kod değişikliği gerekmez.
/// </summary>
public sealed class PaymentSettings
{
    public string Provider { get; set; } = "Fake";

    /// <summary>ISO 4217 para birimi (TRY, USD, EUR...). Tutarlar kuruş (minor) cinsindendir.</summary>
    public string Currency { get; set; } = "TRY";

    public IyzicoSettings Iyzico { get; set; } = new();
}

public sealed class IyzicoSettings
{
    public string ApiKey { get; set; } = string.Empty;
    public string SecretKey { get; set; } = string.Empty;

    /// <summary>Sandbox: https://sandbox-api.iyzipay.com — Canlı: https://api.iyzipay.com</summary>
    public string BaseUrl { get; set; } = "https://sandbox-api.iyzipay.com";

    public bool IsConfigured => !string.IsNullOrWhiteSpace(ApiKey) && !string.IsNullOrWhiteSpace(SecretKey);
}
