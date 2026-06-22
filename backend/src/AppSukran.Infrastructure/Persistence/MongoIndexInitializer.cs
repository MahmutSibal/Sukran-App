using AppSukran.Domain.Entities;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using MongoDB.Driver;

namespace AppSukran.Infrastructure.Persistence;

public sealed class MongoIndexInitializer(IServiceScopeFactory scopeFactory) : IHostedService
{
    public async Task StartAsync(CancellationToken cancellationToken)
    {
        using var scope = scopeFactory.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<IMongoDbContext>();

        await CreateUserIndexesAsync(cancellationToken);
        await CreateRefreshTokenIndexesAsync(cancellationToken);
        await CreateAuditLogIndexesAsync(cancellationToken);
        await CreateRestaurantIndexesAsync(cancellationToken);
        await CreateMenuIndexesAsync(cancellationToken);
        await CreateCustomerCardIndexesAsync(cancellationToken);
        await CreateOrderIndexesAsync<Order>(cancellationToken);
        await CreateOrderIndexesAsync<Bill>(cancellationToken);

        Task CreateUserIndexesAsync(CancellationToken ct)
        {
            var collection = context.Database.GetCollection<User>(nameof(User));
            var indexKeys = Builders<User>.IndexKeys.Ascending(x => x.Email);
            var options = new CreateIndexOptions<User> { Unique = true, Name = "ux_users_email" };
            return collection.Indexes.CreateOneAsync(new CreateIndexModel<User>(indexKeys, options), cancellationToken: ct);
        }

        async Task CreateRefreshTokenIndexesAsync(CancellationToken ct)
        {
            var collection = context.Database.GetCollection<RefreshToken>(nameof(RefreshToken));
            var tokenIndex = Builders<RefreshToken>.IndexKeys.Ascending(x => x.TokenHash);
            var userIndex = Builders<RefreshToken>.IndexKeys.Ascending(x => x.UserId).Ascending(x => x.ExpiresAt);

            await collection.Indexes.CreateOneAsync(new CreateIndexModel<RefreshToken>(tokenIndex, new CreateIndexOptions { Unique = true, Name = "ux_refresh_tokens_hash" }), cancellationToken: ct);
            await collection.Indexes.CreateOneAsync(new CreateIndexModel<RefreshToken>(userIndex, new CreateIndexOptions { Name = "ix_refresh_tokens_user_expiry" }), cancellationToken: ct);
        }

        Task CreateAuditLogIndexesAsync(CancellationToken ct)
        {
            var collection = context.Database.GetCollection<AuditLog>(nameof(AuditLog));
            var indexKeys = Builders<AuditLog>.IndexKeys.Ascending(x => x.CreatedAt).Ascending(x => x.EntityType).Ascending(x => x.EntityId);
            return collection.Indexes.CreateOneAsync(new CreateIndexModel<AuditLog>(indexKeys, new CreateIndexOptions { Name = "ix_auditlogs_entity_created" }), cancellationToken: ct);
        }

        async Task CreateRestaurantIndexesAsync(CancellationToken ct)
        {
            var collection = context.Database.GetCollection<Restaurant>(nameof(Restaurant));
            var locationIndex = Builders<Restaurant>.IndexKeys.Geo2DSphere(x => x.Location.Value);
            await collection.Indexes.CreateOneAsync(new CreateIndexModel<Restaurant>(locationIndex, new CreateIndexOptions { Name = "ix_restaurants_location_2dsphere" }), cancellationToken: ct);

            var ownerIndex = Builders<Restaurant>.IndexKeys.Ascending(x => x.OwnerId);
            await collection.Indexes.CreateOneAsync(new CreateIndexModel<Restaurant>(ownerIndex, new CreateIndexOptions { Name = "ix_restaurants_owner" }), cancellationToken: ct);

            var slugIndex = Builders<Restaurant>.IndexKeys.Ascending(x => x.Slug);
            var slugFilter = Builders<Restaurant>.Filter.Gt(x => x.Slug, string.Empty);
            await collection.Indexes.CreateOneAsync(new CreateIndexModel<Restaurant>(slugIndex, new CreateIndexOptions<Restaurant>
            {
                Name = "ux_restaurants_slug",
                Unique = true,
                PartialFilterExpression = slugFilter
            }), cancellationToken: ct);
        }

        async Task CreateMenuIndexesAsync(CancellationToken ct)
        {
            var collection = context.Database.GetCollection<MenuItem>(nameof(MenuItem));
            var restaurantIndex = Builders<MenuItem>.IndexKeys.Ascending(x => x.RestaurantId);
            var availabilityIndex = Builders<MenuItem>.IndexKeys.Ascending(x => x.RestaurantId).Ascending(x => x.IsAvailable);

            await collection.Indexes.CreateOneAsync(new CreateIndexModel<MenuItem>(restaurantIndex, new CreateIndexOptions { Name = "ix_menu_restaurant" }), cancellationToken: ct);
            await collection.Indexes.CreateOneAsync(new CreateIndexModel<MenuItem>(availabilityIndex, new CreateIndexOptions { Name = "ix_menu_restaurant_available" }), cancellationToken: ct);
        }

        async Task CreateCustomerCardIndexesAsync(CancellationToken ct)
        {
            var collection = context.Database.GetCollection<CustomerCard>(nameof(CustomerCard));
            var userIndex = Builders<CustomerCard>.IndexKeys.Ascending(x => x.UserId).Ascending(x => x.IsDefault).Ascending(x => x.CreatedAt);

            await collection.Indexes.CreateOneAsync(new CreateIndexModel<CustomerCard>(userIndex, new CreateIndexOptions { Name = "ix_customer_cards_user_default_created" }), cancellationToken: ct);
        }

        Task CreateOrderIndexesAsync<TDocument>(CancellationToken ct) where TDocument : Order
        {
            var collection = context.Database.GetCollection<TDocument>(typeof(TDocument).Name);
            var indexKeys = Builders<TDocument>.IndexKeys.Ascending(x => x.RestaurantId).Ascending(x => x.TableNo).Ascending(x => x.SessionStatus);
            return collection.Indexes.CreateOneAsync(new CreateIndexModel<TDocument>(indexKeys, new CreateIndexOptions { Name = $"ix_{typeof(TDocument).Name.ToLowerInvariant()}_restaurant_table_session" }), cancellationToken: ct);
        }
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}