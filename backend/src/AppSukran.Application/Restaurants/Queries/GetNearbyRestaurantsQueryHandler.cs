using AppSukran.Application.Abstractions.Persistence;
using AppSukran.Domain.Entities;
using MediatR;

namespace AppSukran.Application.Restaurants.Queries;

public sealed class GetNearbyRestaurantsQueryHandler(
    IRestaurantSearchService restaurantSearchService,
    IUnitOfWork unitOfWork)
    : IRequestHandler<GetNearbyRestaurantsQuery, IReadOnlyCollection<NearbyRestaurantDto>>
{
    public async Task<IReadOnlyCollection<NearbyRestaurantDto>> Handle(GetNearbyRestaurantsQuery request, CancellationToken cancellationToken)
    {
        var nearby = await restaurantSearchService.FindNearbyAsync(request.Longitude, request.Latitude, request.MaxDistanceMeters, cancellationToken);

        // Restoran başına ortalama puan ve yorum sayısını hesapla.
        var reviews = await unitOfWork.Repository<Review>().GetAllAsync(cancellationToken);
        var ratingByRestaurant = reviews
            .GroupBy(review => review.RestaurantId)
            .ToDictionary(
                group => group.Key,
                group => (Average: group.Average(r => r.Rating), Count: group.Count()));

        return nearby
            .Select(restaurant =>
            {
                if (ratingByRestaurant.TryGetValue(restaurant.Id, out var stats))
                {
                    return restaurant with
                    {
                        AverageRating = Math.Round(stats.Average, 1),
                        ReviewCount = stats.Count
                    };
                }
                return restaurant;
            })
            // Keşfette yüksek puanlılar öne çıksın; eşitlikte çok yorumlu, sonra yakın olan üstte.
            .OrderByDescending(restaurant => restaurant.AverageRating)
            .ThenByDescending(restaurant => restaurant.ReviewCount)
            .ThenBy(restaurant => restaurant.DistanceMeters)
            .ToList();
    }
}
