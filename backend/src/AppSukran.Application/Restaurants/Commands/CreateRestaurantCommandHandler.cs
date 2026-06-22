using System.Text.RegularExpressions;
using AppSukran.Application.Abstractions.Persistence;
using AppSukran.Domain.Common;
using AppSukran.Domain.Entities;
using MediatR;

namespace AppSukran.Application.Restaurants.Commands;

public sealed class CreateRestaurantCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<CreateRestaurantCommand, string>
{
    private static readonly Regex SlugAllowed = new("[^a-z0-9-]+", RegexOptions.Compiled);

    public async Task<string> Handle(CreateRestaurantCommand request, CancellationToken cancellationToken)
    {
        var restaurant = new Restaurant
        {
            Name = request.Name.Trim(),
            Slug = NormalizeSlug(request.Slug),
            OwnerId = request.OwnerId,
            Address = request.Address.Trim(),
            Location = GeoPoint.FromCoordinates(request.Longitude, request.Latitude)
        };

        await unitOfWork.Repository<Restaurant>().InsertAsync(restaurant, cancellationToken);
        return restaurant.Id;
    }

    private static string NormalizeSlug(string raw)
    {
        var lowered = (raw ?? string.Empty).Trim().ToLowerInvariant().Replace(' ', '-');
        return SlugAllowed.Replace(lowered, string.Empty);
    }
}