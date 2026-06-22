import type { CreateRestaurantInput, NearbyRestaurant, RestaurantDetail } from "@/lib/types";
import type { OrderSessionStatus } from "@/lib/enums";
import { api } from "./apiClient";

export interface TableSession {
  restaurantId: string;
  tableNo: number;
  tableSessionId: string;
  status: OrderSessionStatus | number;
  token?: string;
}

export const restaurantService = {
  nearby(longitude: number, latitude: number, maxDistanceMeters = 50000) {
    return api.get<NearbyRestaurant[]>("/api/restaurants/nearby", {
      query: { longitude, latitude, maxDistanceMeters },
    });
  },

  /** SuperAdmin: tüm restoranları listeler (panel restoran seçici için). */
  all() {
    return api.get<RestaurantDetail[]>("/api/restaurants");
  },

  getById(restaurantId: string) {
    return api.get<RestaurantDetail>(`/api/restaurants/${restaurantId}`);
  },

  create(input: CreateRestaurantInput) {
    return api.post<{ restaurantId: string }>("/api/restaurants", input);
  },

  /** Masa oturumunu manuel kapat (kasa aksiyonu). */
  closeTableSession(restaurantId: string, tableNo: number) {
    return api.post<TableSession>(
      `/api/restaurants/${restaurantId}/tables/${tableNo}/session/close`,
    );
  },

  openTableSession(restaurantId: string, tableNo: number) {
    return api.post<TableSession>(
      `/api/restaurants/${restaurantId}/tables/${tableNo}/session/open`,
    );
  },
};
