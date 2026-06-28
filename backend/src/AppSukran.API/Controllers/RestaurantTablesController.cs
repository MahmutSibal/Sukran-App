using AppSukran.Application.Restaurants.Commands;
using AppSukran.Application.Restaurants.Dtos;
using AppSukran.Application.Restaurants.Queries;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AppSukran.API.Controllers;

[ApiController]
[Route("api/restaurants/{restaurantId}/tables")]
[Authorize(Roles = "SuperAdmin,RestaurantOwner")]
public sealed class RestaurantTablesController(IMediator mediator) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyCollection<RestaurantTableSessionDto>>> GetTables(string restaurantId, CancellationToken cancellationToken)
        => Ok(await mediator.Send(new GetRestaurantTablesQuery(restaurantId), cancellationToken));

    [HttpPost]
    public async Task<ActionResult<RestaurantTableSessionDto>> AddTable(string restaurantId, [FromBody] AddRestaurantTableRequest? request, CancellationToken cancellationToken)
        => Ok(await mediator.Send(new AddRestaurantTableCommand(restaurantId, request?.TableNo), cancellationToken));

    [HttpDelete("{tableNo:int}")]
    public async Task<IActionResult> RemoveTable(string restaurantId, int tableNo, CancellationToken cancellationToken)
    {
        await mediator.Send(new RemoveRestaurantTableCommand(restaurantId, tableNo), cancellationToken);
        return NoContent();
    }

    [HttpPost("{tableNo:int}/session/open")]
    public async Task<ActionResult<RestaurantTableSessionDto>> OpenSession(string restaurantId, int tableNo, CancellationToken cancellationToken)
        => Ok(await mediator.Send(new OpenRestaurantTableSessionCommand(restaurantId, tableNo), cancellationToken));

    [HttpPost("{tableNo:int}/session/close")]
    public async Task<ActionResult<RestaurantTableSessionDto>> CloseSession(string restaurantId, int tableNo, CancellationToken cancellationToken)
        => Ok(await mediator.Send(new CloseRestaurantTableSessionCommand(restaurantId, tableNo), cancellationToken));
}

public sealed record AddRestaurantTableRequest(int? TableNo);