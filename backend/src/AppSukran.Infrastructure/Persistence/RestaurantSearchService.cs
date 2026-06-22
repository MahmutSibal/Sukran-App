using AppSukran.Application.Restaurants.Queries;
using AppSukran.Domain.Entities;
using MongoDB.Bson;
using MongoDB.Driver;
using MongoDB.Driver.GeoJsonObjectModel;

namespace AppSukran.Infrastructure.Persistence;

public sealed class RestaurantSearchService(IMongoDbContext context) : IRestaurantSearchService
{
    public async Task<IReadOnlyCollection<NearbyRestaurantDto>> FindNearbyAsync(double longitude, double latitude, int maxDistanceMeters, CancellationToken cancellationToken = default)
    {
        var collection = context.Database.GetCollection<Restaurant>(nameof(Restaurant));

        var geoNear = new BsonDocument
        {
            { "near", new BsonDocument
                {
                    { "type", "Point" },
                    { "coordinates", new BsonArray { longitude, latitude } }
                }
            },
            { "distanceField", "distanceMeters" },
            { "maxDistance", maxDistanceMeters },
            { "spherical", true },
            { "key", "Location.Value" }
        };

        var pipeline = new[]
        {
            new BsonDocument("$geoNear", geoNear)
        };

        var cursor = await collection.AggregateAsync<BsonDocument>(pipeline, cancellationToken: cancellationToken);
        var documents = await cursor.ToListAsync(cancellationToken);

        return documents.Select(document =>
        {
            var coordinates = document["Location"]["Value"]["coordinates"].AsBsonArray;
            return new NearbyRestaurantDto(
                Id: document["_id"].AsString,
                Slug: document.GetValue("Slug", BsonString.Empty).AsString,
                Name: document.GetValue("Name", BsonString.Empty).AsString,
                Address: document.GetValue("Address", BsonString.Empty).AsString,
                Longitude: coordinates[0].ToDouble(),
                Latitude: coordinates[1].ToDouble(),
                DistanceMeters: document.GetValue("distanceMeters", new BsonDouble(0)).ToDouble());
        }).ToList();
    }

    public async Task<Restaurant?> FindBySlugAsync(string slug, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(slug))
        {
            return null;
        }

        var collection = context.Database.GetCollection<Restaurant>(nameof(Restaurant));
        var filter = Builders<Restaurant>.Filter.Eq(restaurant => restaurant.Slug, slug.Trim().ToLowerInvariant());
        return await collection.Find(filter).FirstOrDefaultAsync(cancellationToken);
    }
}
