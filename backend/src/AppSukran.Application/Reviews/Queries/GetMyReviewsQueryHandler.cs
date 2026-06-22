using AppSukran.Application.Abstractions.Persistence;
using AppSukran.Application.Abstractions.Security;
using AppSukran.Application.Common.Models;
using AppSukran.Domain.Entities;
using MediatR;

namespace AppSukran.Application.Reviews.Queries;

public sealed class GetMyReviewsQueryHandler(IUnitOfWork unitOfWork, ICurrentUserService currentUserService)
    : IRequestHandler<GetMyReviewsQuery, IReadOnlyCollection<ReviewResponse>>
{
    public async Task<IReadOnlyCollection<ReviewResponse>> Handle(GetMyReviewsQuery request, CancellationToken cancellationToken)
    {
        var userId = currentUserService.UserId ?? throw new InvalidOperationException("User is not authenticated.");
        var reviews = await unitOfWork.Repository<Review>().GetAllAsync(cancellationToken);
        return reviews
            .Where(review => review.UserId == userId)
            .OrderByDescending(review => review.CreatedAt)
            .Select(review => ReviewMapping.ToResponse(review, userId))
            .ToList();
    }
}
