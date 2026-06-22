using AppSukran.Application.Common.Models;
using MediatR;

namespace AppSukran.Application.Orders.Queries;

public sealed record GetOrdersByRestaurantQuery(string RestaurantId) : IRequest<IReadOnlyCollection<OrderResponse>>;