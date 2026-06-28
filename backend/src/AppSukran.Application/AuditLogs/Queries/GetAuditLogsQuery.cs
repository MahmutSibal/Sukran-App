using AppSukran.Application.Common.Models;
using MediatR;

namespace AppSukran.Application.AuditLogs.Queries;

public sealed record GetAuditLogsQuery(int Limit = 200) : IRequest<IReadOnlyCollection<AuditLogResponse>>;
