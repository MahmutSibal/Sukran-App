import type { MenuItem, MenuItemInput } from "@/lib/types";
import { api } from "./apiClient";

export const menuService = {
  byRestaurant(restaurantId: string) {
    return api.get<MenuItem[]>(`/api/menuitems/restaurant/${restaurantId}`);
  },

  getById(menuItemId: string) {
    return api.get<MenuItem>(`/api/menuitems/${menuItemId}`);
  },

  create(restaurantId: string, input: MenuItemInput) {
    return api.post<string>("/api/menuitems", { restaurantId, ...input });
  },

  update(menuItemId: string, input: MenuItemInput) {
    return api.put<void>(`/api/menuitems/${menuItemId}`, input);
  },

  remove(menuItemId: string) {
    return api.delete<void>(`/api/menuitems/${menuItemId}`);
  },
};
