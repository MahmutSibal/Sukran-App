using AppSukran.Application.Abstractions.Persistence;
using AppSukran.Application.Abstractions.Security;
using AppSukran.Domain.Entities;
using AppSukran.Infrastructure.Settings;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.DependencyInjection;

namespace AppSukran.Infrastructure.Persistence;

public sealed class SuperAdminSeeder(IServiceScopeFactory scopeFactory, IOptions<SuperAdminSettings> options) : IHostedService
{
    public async Task StartAsync(CancellationToken cancellationToken)
    {
        var settings = options.Value;
        if (!settings.Enabled)
        {
            return;
        }

        if (string.IsNullOrWhiteSpace(settings.Email) || string.IsNullOrWhiteSpace(settings.Password))
        {
            return;
        }

        using var scope = scopeFactory.CreateScope();
        var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
        var passwordHashingService = scope.ServiceProvider.GetRequiredService<IPasswordHashingService>();

        var normalizedEmail = settings.Email.Trim().ToLowerInvariant();
        var users = await unitOfWork.Repository<User>().GetAllAsync(cancellationToken);
        if (users.Any(user => user.Email.Equals(normalizedEmail, StringComparison.OrdinalIgnoreCase)))
        {
            return;
        }

        var user = new User
        {
            Name = string.IsNullOrWhiteSpace(settings.Name) ? "Super Admin" : settings.Name.Trim(),
            Email = normalizedEmail,
            PasswordHash = passwordHashingService.HashPassword(settings.Password),
            Role = settings.Role,
            IsActive = true
        };

        await unitOfWork.Repository<User>().InsertAsync(user, cancellationToken);
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}