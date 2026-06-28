using AppSukran.Domain.Enums;

namespace AppSukran.Application.Common.Models;

public sealed record AuditLogResponse(
    string Id,
    string Action,
    string EntityType,
    string EntityId,
    string Details,
    string? ActorUserId,
    string? ActorName,
    UserRole? ActorRole,
    DateTime CreatedAt);
