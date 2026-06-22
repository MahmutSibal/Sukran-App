using System.Linq.Expressions;
using AppSukran.Application.Abstractions.Persistence;
using AppSukran.Domain.Common;
using MongoDB.Driver;

namespace AppSukran.Infrastructure.Persistence;

public sealed class MongoGenericRepository<TDocument>(IMongoDbContext context) : IGenericRepository<TDocument>
    where TDocument : AggregateRoot
{
    private IMongoCollection<TDocument> Collection => context.Database.GetCollection<TDocument>(typeof(TDocument).Name);

    public async Task<TDocument?> GetByIdAsync(string id, CancellationToken cancellationToken = default)
    {
        var filter = Builders<TDocument>.Filter.Eq(document => document.Id, id);
        return await Collection.Find(filter).FirstOrDefaultAsync(cancellationToken);
    }

    public async Task<IReadOnlyCollection<TDocument>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return await Collection.Find(Builders<TDocument>.Filter.Empty).ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyCollection<TDocument>> FindAsync(Expression<Func<TDocument, bool>> predicate, CancellationToken cancellationToken = default)
    {
        return await Collection.Find(predicate).ToListAsync(cancellationToken);
    }

    public async Task<TDocument> InsertAsync(TDocument document, CancellationToken cancellationToken = default)
    {
        if (context.CurrentSession is null)
        {
            await Collection.InsertOneAsync(document, cancellationToken: cancellationToken);
        }
        else
        {
            await Collection.InsertOneAsync(context.CurrentSession, document, cancellationToken: cancellationToken);
        }

        return document;
    }

    public async Task<TDocument> ReplaceAsync(TDocument document, CancellationToken cancellationToken = default)
    {
        var currentVersion = document.Version;
        var versionFilter = currentVersion == 0
            ? Builders<TDocument>.Filter.Or(
                Builders<TDocument>.Filter.Eq(x => x.Version, currentVersion),
                Builders<TDocument>.Filter.Exists(x => x.Version, false))
            : Builders<TDocument>.Filter.Eq(x => x.Version, currentVersion);

        var filter = Builders<TDocument>.Filter.Eq(x => x.Id, document.Id) & versionFilter;
        document.Version = currentVersion + 1;

        ReplaceOneResult result;
        if (context.CurrentSession is null)
        {
            result = await Collection.ReplaceOneAsync(filter, document, new ReplaceOptions { IsUpsert = false }, cancellationToken);
        }
        else
        {
            result = await Collection.ReplaceOneAsync(context.CurrentSession, filter, document, new ReplaceOptions { IsUpsert = false }, cancellationToken);
        }

        if (result.MatchedCount == 0)
        {
            throw new InvalidOperationException("Concurrency conflict detected.");
        }

        return document;
    }

    public async Task DeleteAsync(string id, CancellationToken cancellationToken = default)
    {
        var filter = Builders<TDocument>.Filter.Eq(document => document.Id, id);
        await Collection.DeleteOneAsync(filter, cancellationToken);
    }
}