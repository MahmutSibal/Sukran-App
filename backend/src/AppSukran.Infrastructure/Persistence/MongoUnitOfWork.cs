using AppSukran.Application.Abstractions.Persistence;
using AppSukran.Domain.Common;
using Microsoft.Extensions.DependencyInjection;

namespace AppSukran.Infrastructure.Persistence;

public sealed class MongoUnitOfWork(IMongoDbContext context, IServiceProvider serviceProvider) : IUnitOfWork
{
    public IGenericRepository<TDocument> Repository<TDocument>() where TDocument : AggregateRoot
        => serviceProvider.GetRequiredService<IGenericRepository<TDocument>>();

    public async Task BeginTransactionAsync(CancellationToken cancellationToken = default)
    {
        if (context.CurrentSession is null)
        {
            await context.BeginSessionAsync(cancellationToken);
        }
    }

    public async Task CommitAsync(CancellationToken cancellationToken = default)
    {
        if (context.CurrentSession is not null)
        {
            await context.CurrentSession.CommitTransactionAsync(cancellationToken);
            context.SetSession(null);
        }
    }

    public async Task RollbackAsync(CancellationToken cancellationToken = default)
    {
        if (context.CurrentSession is not null)
        {
            await context.CurrentSession.AbortTransactionAsync(cancellationToken);
            context.SetSession(null);
        }
    }
}