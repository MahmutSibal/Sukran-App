using AppSukran.Application.Abstractions.Persistence;
using AppSukran.Domain.Entities;
using MediatR;

namespace AppSukran.Application.Menus.Commands;

public sealed class DeleteMenuItemCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<DeleteMenuItemCommand, Unit>
{
    public async Task<Unit> Handle(DeleteMenuItemCommand request, CancellationToken cancellationToken)
    {
        await unitOfWork.Repository<MenuItem>().DeleteAsync(request.MenuItemId, cancellationToken);
        return Unit.Value;
    }
}