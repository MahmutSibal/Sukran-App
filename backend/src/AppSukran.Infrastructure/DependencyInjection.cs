using AppSukran.Application.Abstractions.Notifications;
using AppSukran.Application.Abstractions.Logging;
using AppSukran.Application.Abstractions.Integrations;
using AppSukran.Application.Abstractions.Payments;
using AppSukran.Application.Abstractions.Persistence;
using AppSukran.Application.Abstractions.Security;
using AppSukran.Application.Restaurants.Queries;
using AppSukran.Infrastructure.Payments;
using AppSukran.Infrastructure.Persistence;
using AppSukran.Infrastructure.Realtime;
using AppSukran.Infrastructure.Security;
using AppSukran.Infrastructure.Integrations;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using MongoDB.Driver;

namespace AppSukran.Infrastructure;

public static class DependencyInjection
{
        public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
        {
            services.Configure<Settings.MongoSettings>(configuration.GetSection("Mongo"));
            services.Configure<Settings.JwtSettings>(configuration.GetSection("Jwt"));
            services.Configure<Settings.SuperAdminSettings>(configuration.GetSection("SuperAdmin"));
            services.Configure<Settings.IntegrationSettings>(configuration.GetSection("Integration"));
            services.Configure<Settings.PaymentSettings>(configuration.GetSection("Payment"));

            // MongoClient is safe to keep as a singleton. MongoDbContext holds session state and must be scoped per request.
            services.AddSingleton<IMongoClient>(sp =>
            {
                var opts = sp.GetRequiredService<IOptions<Settings.MongoSettings>>();
                return new MongoClient(opts.Value.ConnectionString);
            });

            services.AddScoped<IMongoDbContext, MongoDbContext>();
        services.AddScoped(typeof(IGenericRepository<>), typeof(MongoGenericRepository<>));
        services.AddScoped<IUnitOfWork, MongoUnitOfWork>();
        services.AddScoped<ITokenService, Security.JwtTokenService>();
        services.AddScoped<ICurrentUserService, CurrentUserService>();
        services.AddScoped<IPasswordHashingService, PasswordHashingService>();
        services.AddScoped<ICardNumberProtectionService, CardNumberProtectionService>();
        services.AddScoped<IRefreshTokenService, RefreshTokenService>();
        services.AddScoped<IOrderRealtimePublisher, MongoOrderRealtimePublisher>();
        services.AddScoped<IAuditLogService, MongoAuditLogService>();
        services.AddHttpClient<IPosBridgeService, HttpPosBridgeService>();

        // Ödeme sağlayıcıları: ikisi de kayıtlı, hangisinin kullanılacağı
        // appsettings "Payment:Provider" değerine göre çalışma anında seçilir.
        services.AddScoped<FakePaymentGateway>();
        services.AddHttpClient<IyzicoPaymentGateway>();
        services.AddScoped<IPaymentGateway>(sp =>
        {
            var provider = sp.GetRequiredService<IOptions<Settings.PaymentSettings>>().Value.Provider;
            return string.Equals(provider, "Iyzico", StringComparison.OrdinalIgnoreCase)
                ? sp.GetRequiredService<IyzicoPaymentGateway>()
                : sp.GetRequiredService<FakePaymentGateway>();
        });

        services.AddScoped<IRestaurantSearchService, RestaurantSearchService>();
        services.AddHostedService<MongoIndexInitializer>();
        services.AddHostedService<SuperAdminSeeder>();

        return services;
    }
}