import { OrderItemStatus, OrderSessionStatus, PaymentStatus, UserRole } from "./enums";

/** Backend DTO sözleşmeleri (response şekilleri). */

export interface TokenResponse {
  accessToken: string;
  refreshToken: string;
  refreshTokenExpiresAt: string;
}

export interface NearbyRestaurant {
  id: string;
  slug: string;
  name: string;
  address: string;
  longitude: number;
  latitude: number;
  distanceMeters: number;
}

export interface RestaurantDetail {
  id: string;
  slug: string;
  name: string;
  address: string;
  longitude: number;
  latitude: number;
}

export interface AppUser {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  restaurantId?: string | null;
  isActive?: boolean;
}

export interface CreateUserInput {
  name: string;
  email: string;
  password: string;
  role: UserRole;
  restaurantId?: string | null;
}

export interface MenuItem {
  id: string;
  restaurantId: string;
  category: string;
  name: string;
  imageUrl: string;
  ingredients: string[];
  recipe: string | null;
  averagePreparationTime: number;
  /** Kuruş cinsinden (long). */
  price: number;
  isAvailable: boolean;
}

export interface OrderItem {
  orderItemId: string;
  menuItemId: string;
  name: string;
  price: number;
  orderedBy: string;
  status: OrderItemStatus;
  paymentStatus: PaymentStatus;
}

export interface Order {
  id: string;
  restaurantId: string;
  tableNo: number;
  sessionStatus: OrderSessionStatus;
  items: OrderItem[];
  totalAmount: number;
  remainingAmount: number;
}

export interface Bill {
  id: string;
  restaurantId: string;
  tableNo: number;
  sessionStatus: OrderSessionStatus;
  items: OrderItem[];
  totalAmount: number;
  remainingAmount: number;
}

/** Oturum açmış panel kullanıcısının kimliği (JWT'den çözümlenir). */
export interface AuthIdentity {
  userId: string;
  name: string;
  email: string;
  role: UserRole;
  restaurantId: string | null;
  accessToken: string;
}

/** Menü öğesi oluştur/güncelle form yükü. */
export interface MenuItemInput {
  category: string;
  name: string;
  imageUrl: string;
  ingredients: string[];
  recipe: string | null;
  averagePreparationTime: number;
  price: number;
  isAvailable: boolean;
}

export interface CreateRestaurantInput {
  name: string;
  slug: string;
  ownerId: string;
  longitude: number;
  latitude: number;
  address: string;
}
