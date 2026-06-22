using AppSukran.Application.Abstractions.Persistence;
using AppSukran.Domain.Entities;
using MediatR;

namespace AppSukran.Application.Menus.Commands;

public sealed class CreateMenuItemCommandHandler(IUnitOfWork unitOfWork) : IRequestHandler<CreateMenuItemCommand, string>
{
    public async Task<string> Handle(CreateMenuItemCommand request, CancellationToken cancellationToken)
    {
        var menuItem = new MenuItem
        {
            RestaurantId = request.RestaurantId,
            Category = request.Category.Trim(),
            Name = request.Name.Trim(),
            ImageUrl = request.ImageUrl.Trim(),
            Ingredients = request.Ingredients.Select(ingredient => ingredient.Trim()).Where(ingredient => !string.IsNullOrWhiteSpace(ingredient)).ToList(),
            Recipe = string.IsNullOrWhiteSpace(request.Recipe) ? null : request.Recipe.Trim(),
            AveragePreparationTime = request.AveragePreparationTime,
            Price = request.Price,
            IsAvailable = request.IsAvailable
        };

        await unitOfWork.Repository<MenuItem>().InsertAsync(menuItem, cancellationToken);
        return menuItem.Id;
    }
}