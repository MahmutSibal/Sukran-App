using AppSukran.Application.Abstractions.Persistence;
using AppSukran.Application.Common.Models;
using AppSukran.Domain.Entities;
using MediatR;

namespace AppSukran.Application.Authentication.Queries;

public sealed class GetUsersQueryHandler(IUnitOfWork unitOfWork) : IRequestHandler<GetUsersQuery, IReadOnlyCollection<UserResponse>>
{
    public async Task<IReadOnlyCollection<UserResponse>> Handle(GetUsersQuery request, CancellationToken cancellationToken)
    {
        var users = await unitOfWork.Repository<User>().GetAllAsync(cancellationToken);
        return users
            .OrderBy(user => user.Name)
            .Select(Map)
            .ToList();
    }

    private static UserResponse Map(User user)
        => new(user.Id, user.Name, user.Email, user.Role, user.RestaurantId, user.IsActive);
}
