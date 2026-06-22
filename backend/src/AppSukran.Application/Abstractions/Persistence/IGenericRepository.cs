using System.Linq.Expressions;
using AppSukran.Domain.Common;

namespace AppSukran.Application.Abstractions.Persistence;

public interface IGenericRepository<TDocument> where TDocument : AggregateRoot
{
    Task<TDocument?> GetByIdAsync(string id, CancellationToken cancellationToken = default);
    Task<IReadOnlyCollection<TDocument>> GetAllAsync(CancellationToken cancellationToken = default);

    /// Sunucu (veritabanı) tarafında filtreleyerek yalnızca eşleşen kayıtları getirir.
    /// Tüm koleksiyonu belleğe çekmeden alt küme okumak için kullanılır.
    Task<IReadOnlyCollection<TDocument>> FindAsync(Expression<Func<TDocument, bool>> predicate, CancellationToken cancellationToken = default);
    Task<TDocument> InsertAsync(TDocument document, CancellationToken cancellationToken = default);
    Task<TDocument> ReplaceAsync(TDocument document, CancellationToken cancellationToken = default);
    Task DeleteAsync(string id, CancellationToken cancellationToken = default);
}