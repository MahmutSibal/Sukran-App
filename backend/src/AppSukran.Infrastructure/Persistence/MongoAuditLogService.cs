using AppSukran.Application.Abstractions.Logging;
using AppSukran.Application.Abstractions.Persistence;
using AppSukran.Domain.Entities;

namespace AppSukran.Infrastructure.Persistence;

public sealed class MongoAuditLogService(IUnitOfWork unitOfWork) : IAuditLogService
{
    public async Task RecordAsync(string action, string entityType, string entityId, string details, string? actorUserId = null, CancellationToken cancellationToken = default)
    {
        var log = new AuditLog
        {
            ActorUserId = actorUserId,
            Action = action,
            EntityType = entityType,
            EntityId = entityId,
            Details = details
        };

        await unitOfWork.Repository<AuditLog>().InsertAsync(log, cancellationToken);
    }
}