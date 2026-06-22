using MongoDB.Driver;

namespace AppSukran.Infrastructure.Persistence;

public interface IMongoDbContext
{
    IMongoDatabase Database { get; }
    IClientSessionHandle? CurrentSession { get; }
    Task<IClientSessionHandle> BeginSessionAsync(CancellationToken cancellationToken = default);
    void SetSession(IClientSessionHandle? session);
}