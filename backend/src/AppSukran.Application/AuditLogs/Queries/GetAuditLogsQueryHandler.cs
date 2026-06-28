using AppSukran.Application.Abstractions.Persistence;
using AppSukran.Application.Abstractions.Security;
using AppSukran.Application.Common.Models;
using AppSukran.Domain.Entities;
using AppSukran.Domain.Enums;
using MediatR;

namespace AppSukran.Application.AuditLogs.Queries;

public sealed class GetAuditLogsQueryHandler(
    IUnitOfWork unitOfWork,
    ICurrentUserService currentUserService)
    : IRequestHandler<GetAuditLogsQuery, IReadOnlyCollection<AuditLogResponse>>
{
    public async Task<IReadOnlyCollection<AuditLogResponse>> Handle(GetAuditLogsQuery request, CancellationToken cancellationToken)
    {
        var users = await unitOfWork.Repository<User>().GetAllAsync(cancellationToken);
        var userById = users.ToDictionary(u => u.Id, u => u);

        var logs = await unitOfWork.Repository<AuditLog>().GetAllAsync(cancellationToken);

        var isSuperAdmin = currentUserService.IsInRole(nameof(UserRole.SuperAdmin));
        if (!isSuperAdmin)
        {
            var restaurantId = currentUserService.RestaurantId;
            if (string.IsNullOrWhiteSpace(restaurantId))
            {
                throw new UnauthorizedAccessException("Current user is not associated with a restaurant.");
            }

            // Owner yalnızca kendi restoranındaki kullanıcıların (kendisi + personeli) loglarını görür.
            var allowedUserIds = users
                .Where(u => u.RestaurantId == restaurantId)
                .Select(u => u.Id)
                .ToHashSet();

            logs = logs
                .Where(l => l.ActorUserId != null && allowedUserIds.Contains(l.ActorUserId))
                .ToList();
        }

        return logs
            .OrderByDescending(l => l.CreatedAt)
            .Take(Math.Clamp(request.Limit, 1, 1000))
            .Select(l =>
            {
                User? actor = null;
                if (l.ActorUserId != null)
                {
                    userById.TryGetValue(l.ActorUserId, out actor);
                }

                return new AuditLogResponse(
                    l.Id,
                    l.Action,
                    l.EntityType,
                    l.EntityId,
                    l.Details,
                    l.ActorUserId,
                    actor?.Name,
                    actor?.Role,
                    l.CreatedAt);
            })
            .ToList();
    }
}
