using AppSukran.Application.Abstractions.Persistence;
using AppSukran.Application.Common.Models;
using AppSukran.Application.Common.Security;
using AppSukran.Domain.Entities;
using MediatR;

namespace AppSukran.Application.Orders.Queries;

public sealed class GetOrdersByRestaurantQueryHandler(IUnitOfWork unitOfWork, IRestaurantAccessGuard restaurantAccessGuard) : IRequestHandler<GetOrdersByRestaurantQuery, IReadOnlyCollection<OrderResponse>>
{
    public async Task<IReadOnlyCollection<OrderResponse>> Handle(GetOrdersByRestaurantQuery request, CancellationToken cancellationToken)
    {
        restaurantAccessGuard.EnsureCanAccess(request.RestaurantId);
        var orders = await unitOfWork.Repository<Order>().GetAllAsync(cancellationToken);
        return orders.Where(order => order.RestaurantId == request.RestaurantId).Select(Map).ToList();
    }

    private static OrderResponse Map(Order order)
        => new(order.Id, order.RestaurantId, order.TableNo, order.SessionStatus, order.Items.Select(MapItem).ToList(), order.TotalAmount, order.RemainingAmount);

    private static OrderItemResponse MapItem(OrderItem item)
        => new(item.OrderItemId, item.MenuItemId, item.Name, item.Price, item.OrderedBy, item.Status, item.PaymentStatus);
}