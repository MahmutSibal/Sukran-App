using Microsoft.AspNetCore.SignalR;

namespace AppSukran.Infrastructure.Realtime;

public sealed class OrderHub : Hub
{
	public async Task JoinRestaurantGroup(string restaurantId)
	{
		await Groups.AddToGroupAsync(Context.ConnectionId, restaurantId);
	}

	public async Task LeaveRestaurantGroup(string restaurantId)
	{
		await Groups.RemoveFromGroupAsync(Context.ConnectionId, restaurantId);
	}
}