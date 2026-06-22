namespace AppSukran.Application.Abstractions.Security;

public interface ICurrentUserService
{
    string? UserId { get; }
    string? Email { get; }
    string? Role { get; }

    /// Kullanıcının bağlı olduğu restoran (RestaurantOwner access token'ı veya
    /// QrSession token'ı bu claim'i taşır). Çapraz-restoran erişim kontrolünde kullanılır.
    string? RestaurantId { get; }

    bool IsAuthenticated { get; }
    bool IsInRole(string role);
}