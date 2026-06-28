using AppSukran.Application.AuditLogs.Queries;
using AppSukran.Application.Common.Models;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AppSukran.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "SuperAdmin,RestaurantOwner")]
public sealed class AuditLogsController(IMediator mediator) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyCollection<AuditLogResponse>>> GetAll([FromQuery] int limit = 200, CancellationToken cancellationToken = default)
        => Ok(await mediator.Send(new GetAuditLogsQuery(limit), cancellationToken));
}
