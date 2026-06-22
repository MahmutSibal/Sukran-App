using AppSukran.Application.Abstractions.Notifications;
using AppSukran.Domain.Entities;
using Microsoft.AspNetCore.SignalR;

namespace AppSukran.Infrastructure.Realtime;

public sealed class MongoOrderRealtimePublisher(IHubContext<OrderHub> hubContext) : IOrderRealtimePublisher
{
    public Task PublishOrderCreatedAsync(Order order, CancellationToken cancellationToken = default)
        => hubContext.Clients.Group(order.RestaurantId).SendAsync("orderCreated", order, cancellationToken);

    public Task PublishOrderUpdatedAsync(Order order, CancellationToken cancellationToken = default)
        => hubContext.Clients.Group(order.RestaurantId).SendAsync("orderUpdated", order, cancellationToken);
}