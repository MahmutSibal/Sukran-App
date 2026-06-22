import '../models/backend_dtos.dart';

class DemoSeed {
  static const restaurantId = 'restaurant-demo-001';

  static final restaurants = <NearbyRestaurantDto>[
    NearbyRestaurantDto(
      id: restaurantId,
      slug: 'sukran-kadikoy',
      name: 'Sukran Kadikoy',
      address: 'Moda Caddesi No:18, Istanbul',
      longitude: 29.0293,
      latitude: 40.9867,
      distanceMeters: 320,
    ),
    NearbyRestaurantDto(
      id: 'restaurant-demo-002',
      slug: 'sukran-moda-sahil',
      name: 'Sukran Moda Sahil',
      address: 'Moda Sahili, Caferaga, Istanbul',
      longitude: 29.0246,
      latitude: 40.9802,
      distanceMeters: 940,
    ),
    NearbyRestaurantDto(
      id: 'restaurant-demo-003',
      slug: 'sukran-bahariye',
      name: 'Sukran Bahariye Kafe',
      address: 'Bahariye Caddesi No:42, Kadikoy',
      longitude: 29.0312,
      latitude: 40.9904,
      distanceMeters: 1240,
    ),
    NearbyRestaurantDto(
      id: 'restaurant-demo-004',
      slug: 'sukran-yeldegirmeni',
      name: 'Sukran Yeldegirmeni',
      address: 'Karakolhane Caddesi No:9, Kadikoy',
      longitude: 29.0341,
      latitude: 40.9951,
      distanceMeters: 1680,
    ),
    NearbyRestaurantDto(
      id: 'restaurant-demo-005',
      slug: 'sukran-fenerbahce',
      name: 'Sukran Fenerbahce',
      address: 'Bagdat Caddesi No:120, Istanbul',
      longitude: 29.0438,
      latitude: 40.9779,
      distanceMeters: 2100,
    ),
  ];

  static final restaurantDetail = RestaurantDetailResponse(
    id: restaurantId,
    slug: 'sukran-kadikoy',
    name: 'Sukran Kadikoy',
    address: 'Moda Caddesi No:18, Istanbul',
    longitude: 29.0293,
    latitude: 40.9867,
  );

  static final menuItems = <MenuItemResponse>[
    MenuItemResponse(
      id: 'menu-1',
      restaurantId: restaurantId,
      category: 'Kahvaltilik',
      name: 'Menemen',
      imageUrl: 'https://images.unsplash.com/photo-1604908176997-125f25cc500f?auto=format&fit=crop&w=900&q=80',
      ingredients: const ['Yumurta', 'Domates', 'Biber', 'Zeytinyagi'],
      recipe: 'Sicak tavada, bol domatesli ve taze biberli.',
      averagePreparationTime: 12,
      price: 17500,
      isAvailable: true,
    ),
    MenuItemResponse(
      id: 'menu-2',
      restaurantId: restaurantId,
      category: 'Kahveler',
      name: 'Latte',
      imageUrl: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=900&q=80',
      ingredients: const ['Double espresso', 'Buharda sut'],
      recipe: 'Kadifemsi sut dokusu ve yogun espresso.',
      averagePreparationTime: 4,
      price: 8900,
      isAvailable: true,
    ),
    MenuItemResponse(
      id: 'menu-3',
      restaurantId: restaurantId,
      category: 'Tatlilar',
      name: 'San Sebastian',
      imageUrl: 'https://images.unsplash.com/photo-1546017538-8d4b8b8d9fa4?auto=format&fit=crop&w=900&q=80',
      ingredients: const ['Cream cheese', 'Yumurta', 'Vanilya'],
      recipe: 'Yumusak merkez, hafif yanik yuzey.',
      averagePreparationTime: 9,
      price: 14500,
      isAvailable: true,
    ),
    MenuItemResponse(
      id: 'menu-4',
      restaurantId: restaurantId,
      category: 'Icekler',
      name: 'Taze Portakal Suyu',
      imageUrl: 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?auto=format&fit=crop&w=900&q=80',
      ingredients: const ['Taze portakal'],
      recipe: null,
      averagePreparationTime: 3,
      price: 6500,
      isAvailable: true,
    ),
    MenuItemResponse(
      id: 'menu-5',
      restaurantId: restaurantId,
      category: 'Kahveler',
      name: 'Americano',
      imageUrl: 'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?auto=format&fit=crop&w=900&q=80',
      ingredients: const ['Espresso', 'Sicak su'],
      recipe: null,
      averagePreparationTime: 3,
      price: 7200,
      isAvailable: true,
    ),
    MenuItemResponse(
      id: 'menu-6',
      restaurantId: restaurantId,
      category: 'Atistirmalik',
      name: 'Truflu Browni',
      imageUrl: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?auto=format&fit=crop&w=900&q=80',
      ingredients: const ['Kakao', 'Cikolata', 'Findik'],
      recipe: 'Paylasilabilir sicak servis.',
      averagePreparationTime: 7,
      price: 9800,
      isAvailable: true,
    ),
  ];

  static final orders = <OrderResponse>[
    OrderResponse(
      id: 'order-1',
      restaurantId: restaurantId,
      tableNo: 8,
      sessionStatus: OrderSessionStatus.active,
      items: [
        OrderItemResponse(orderItemId: 'oi-1', menuItemId: 'menu-2', name: 'Latte', price: 8900, orderedBy: 'Masa 8', status: OrderItemStatus.preparing, paymentStatus: PaymentStatus.unpaid),
        OrderItemResponse(orderItemId: 'oi-2', menuItemId: 'menu-4', name: 'Taze Portakal Suyu', price: 6500, orderedBy: 'Masa 8', status: OrderItemStatus.ready, paymentStatus: PaymentStatus.processing),
      ],
      totalAmount: 15400,
      remainingAmount: 8900,
    ),
    OrderResponse(
      id: 'order-2',
      restaurantId: restaurantId,
      tableNo: 3,
      sessionStatus: OrderSessionStatus.active,
      items: [
        OrderItemResponse(orderItemId: 'oi-3', menuItemId: 'menu-1', name: 'Menemen', price: 17500, orderedBy: 'Masa 3', status: OrderItemStatus.kitchen, paymentStatus: PaymentStatus.unpaid),
      ],
      totalAmount: 17500,
      remainingAmount: 17500,
    ),
  ];

  static final bills = <BillResponse>[
    BillResponse(id: 'bill-1', restaurantId: restaurantId, tableNo: 8, sessionStatus: OrderSessionStatus.active, items: orders.first.items, totalAmount: 15400, remainingAmount: 8900),
    BillResponse(id: 'bill-2', restaurantId: restaurantId, tableNo: 3, sessionStatus: OrderSessionStatus.active, items: orders.last.items, totalAmount: 17500, remainingAmount: 17500),
  ];
}