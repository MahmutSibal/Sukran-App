using AppSukran.Infrastructure.Settings;
using Microsoft.Extensions.Options;
using MongoDB.Driver;

namespace AppSukran.Infrastructure.Persistence;

public sealed class MongoDbContext : IMongoDbContext
{
    private readonly IMongoClient _client;
    private IClientSessionHandle? _currentSession;

    public MongoDbContext(IMongoClient client, IOptions<MongoSettings> options)
    {
        var settings = options.Value;
        _client = client;
        Database = _client.GetDatabase(settings.DatabaseName);
    }

    public IMongoDatabase Database { get; }
    public IClientSessionHandle? CurrentSession => _currentSession;

    public async Task<IClientSessionHandle> BeginSessionAsync(CancellationToken cancellationToken = default)
    {
        _currentSession = await _client.StartSessionAsync(cancellationToken: cancellationToken);
        _currentSession.StartTransaction();
        return _currentSession;
    }

    public void SetSession(IClientSessionHandle? session)
    {
        _currentSession = session;
    }
}