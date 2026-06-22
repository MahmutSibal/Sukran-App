using AppSukran.Application.Restaurants.Commands;
using AppSukran.Application.Restaurants.Dtos;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AppSukran.API.Controllers;

[ApiController]
[Route("api/restaurants/{restaurantId}/tables")]
[Authorize(Roles = "SuperAdmin,RestaurantOwner")]
public sealed class RestaurantTablesController(IMediator mediator) : ControllerBase
{
    [HttpPost("{tableNo:int}/session/open")]
    public async Task<ActionResult<RestaurantTableSessionDto>> OpenSession(string restaurantId, int tableNo, CancellationToken cancellationToken)
        => Ok(await mediator.Send(new OpenRestaurantTableSessionCommand(restaurantId, tableNo), cancellationToken));

    [HttpPost("{tableNo:int}/session/close")]
    public async Task<ActionResult<RestaurantTableSessionDto>> CloseSession(string restaurantId, int tableNo, CancellationToken cancellationToken)
        => Ok(await mediator.Send(new CloseRestaurantTableSessionCommand(restaurantId, tableNo), cancellationToken));
}