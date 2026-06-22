using AppSukran.Application.Abstractions.Persistence;
using AppSukran.Application.Abstractions.Security;
using AppSukran.Domain.Entities;
using MediatR;

namespace AppSukran.Application.Authentication.Commands;

public sealed class RevokeRefreshTokenCommandHandler(IUnitOfWork unitOfWork, IRefreshTokenService refreshTokenService)
    : IRequestHandler<RevokeRefreshTokenCommand>
{
    public async Task Handle(RevokeRefreshTokenCommand request, CancellationToken cancellationToken)
    {
        var refreshTokenHash = refreshTokenService.HashRefreshToken(request.RefreshToken);
        var refreshTokens = await unitOfWork.Repository<RefreshToken>().GetAllAsync(cancellationToken);
        var storedRefreshToken = refreshTokens.FirstOrDefault(token => token.TokenHash == refreshTokenHash);
        if (storedRefreshToken != null && !storedRefreshToken.IsRevoked)
        {
            storedRefreshToken.RevokedAt = DateTime.UtcNow;
            await unitOfWork.Repository<RefreshToken>().ReplaceAsync(storedRefreshToken, cancellationToken);
        }
    }
}
