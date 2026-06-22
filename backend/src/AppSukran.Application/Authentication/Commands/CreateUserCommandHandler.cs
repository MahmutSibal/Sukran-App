using AppSukran.Application.Abstractions.Logging;
using AppSukran.Application.Abstractions.Persistence;
using AppSukran.Application.Abstractions.Security;
using AppSukran.Domain.Entities;
using MediatR;

namespace AppSukran.Application.Authentication.Commands;

public sealed class CreateUserCommandHandler(
    IUnitOfWork unitOfWork,
    IPasswordHashingService passwordHashingService,
    IAuditLogService auditLogService,
    ICurrentUserService currentUserService) : IRequestHandler<CreateUserCommand, string>
{
    public async Task<string> Handle(CreateUserCommand request, CancellationToken cancellationToken)
    {
        var repository = unitOfWork.Repository<User>();
        var existingUsers = await repository.GetAllAsync(cancellationToken);
        if (existingUsers.Any(user => user.Email.Equals(request.Email, StringComparison.OrdinalIgnoreCase)))
        {
            throw new InvalidOperationException("Email already exists.");
        }

        var user = new User
        {
            Name = request.Name.Trim(),
            Email = request.Email.Trim().ToLowerInvariant(),
            PasswordHash = passwordHashingService.HashPassword(request.Password),
            Role = request.Role,
            RestaurantId = string.IsNullOrWhiteSpace(request.RestaurantId) ? null : request.RestaurantId.Trim(),
            IsActive = true
        };

        await repository.InsertAsync(user, cancellationToken);
        await auditLogService.RecordAsync("UserCreated", nameof(User), user.Id, $"User created with role {request.Role}.", currentUserService.UserId, cancellationToken);

        return user.Id;
    }
}
