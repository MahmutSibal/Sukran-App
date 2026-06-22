using AppSukran.Application.Common.Models;
using MediatR;

namespace AppSukran.Application.Authentication.Queries;

public sealed record GetUsersQuery() : IRequest<IReadOnlyCollection<UserResponse>>;
