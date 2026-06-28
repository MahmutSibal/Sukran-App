using AppSukran.Application.Abstractions.Logging;
using AppSukran.Application.Abstractions.Persistence;
using AppSukran.Application.Abstractions.Security;
using AppSukran.Domain.Entities;
using MediatR;

namespace AppSukran.Application.Staff.Commands;

public sealed class CreateStaffCommandHandler(
    IUnitOfWork unitOfWork,
    IPasswordHashingService passwordHashingService,
    IAuditLogService auditLogService,
    ICurrentUserService currentUserService) : IRequestHandler<CreateStaffCommand, string>
{
    public async Task<string> Handle(CreateStaffCommand request, CancellationToken cancellationToken)
    {
        var restaurantId = currentUserService.RestaurantId;
        if (string.IsNullOrWhiteSpace(restaurantId))
        {
            throw new UnauthorizedAccessException("Current user is not associated with a restaurant.");
        }

        if (!StaffRoles.IsStaffRole(request.Role))
        {
            throw new InvalidOperationException("Only Kitchen or Waiter roles can be assigned to staff.");
        }

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
            RestaurantId = restaurantId,
            IsActive = true
        };

        await repository.InsertAsync(user, cancellationToken);
        await auditLogService.RecordAsync("StaffCreated", nameof(User), user.Id, $"Staff created with role {request.Role}.", currentUserService.UserId, cancellationToken);

        return user.Id;
    }
}
