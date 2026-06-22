enum OrderItemStatus { pending, kitchen, preparing, ready, delivered }

enum PaymentStatus { unpaid, processing, paid }

enum OrderSessionStatus { active, closed }

OrderItemStatus parseOrderItemStatus(dynamic value) {
  if (value is int) {
    switch (value) {
      case 1:
        return OrderItemStatus.pending;
      case 2:
        return OrderItemStatus.kitchen;
      case 3:
        return OrderItemStatus.preparing;
      case 4:
        return OrderItemStatus.ready;
      case 5:
        return OrderItemStatus.delivered;
    }
  }

  final text = value?.toString().toLowerCase() ?? '';
  switch (text) {
    case 'pending':
      return OrderItemStatus.pending;
    case 'kitchen':
      return OrderItemStatus.kitchen;
    case 'preparing':
      return OrderItemStatus.preparing;
    case 'ready':
      return OrderItemStatus.ready;
    case 'delivered':
      return OrderItemStatus.delivered;
    default:
      return OrderItemStatus.pending;
  }
}

PaymentStatus parsePaymentStatus(dynamic value) {
  if (value is int) {
    switch (value) {
      case 1:
        return PaymentStatus.unpaid;
      case 2:
        return PaymentStatus.processing;
      case 3:
        return PaymentStatus.paid;
    }
  }

  final text = value?.toString().toLowerCase() ?? '';
  switch (text) {
    case 'unpaid':
      return PaymentStatus.unpaid;
    case 'processing':
      return PaymentStatus.processing;
    case 'paid':
      return PaymentStatus.paid;
    default:
      return PaymentStatus.unpaid;
  }
}

OrderSessionStatus parseOrderSessionStatus(dynamic value) {
  if (value is int) {
    switch (value) {
      case 1:
        return OrderSessionStatus.active;
      case 2:
        return OrderSessionStatus.closed;
    }
  }

  final text = value?.toString().toLowerCase() ?? '';
  return text == 'closed' ? OrderSessionStatus.closed : OrderSessionStatus.active;
}

class NearbyRestaurantDto {
  NearbyRestaurantDto({required this.id, required this.slug, required this.name, required this.address, required this.longitude, required this.latitude, required this.distanceMeters, this.averageRating = 0, this.reviewCount = 0});

  factory NearbyRestaurantDto.fromJson(Map<String, dynamic> json) {
    return NearbyRestaurantDto(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String slug;
  final String name;
  final String address;
  final double longitude;
  final double latitude;
  final double distanceMeters;
  final double averageRating;
  final int reviewCount;
}

class RestaurantDetailResponse {
  RestaurantDetailResponse({required this.id, required this.slug, required this.name, required this.address, required this.longitude, required this.latitude});

  factory RestaurantDetailResponse.fromJson(Map<String, dynamic> json) {
    return RestaurantDetailResponse(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String slug;
  final String name;
  final String address;
  final double longitude;
  final double latitude;
}

class TokenResponse {
  TokenResponse({required this.accessToken, required this.refreshToken, required this.refreshTokenExpiresAt});

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      refreshTokenExpiresAt: DateTime.tryParse(json['refreshTokenExpiresAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String accessToken;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
}

class QrSessionResponse {
  QrSessionResponse({required this.accessToken, required this.expiresAt, required this.restaurantId, required this.tableNo, required this.tableSessionId});

  factory QrSessionResponse.fromJson(Map<String, dynamic> json) {
    return QrSessionResponse(
      accessToken: json['accessToken']?.toString() ?? '',
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ?? DateTime.now(),
      restaurantId: json['restaurantId']?.toString() ?? '',
      tableNo: (json['tableNo'] as num?)?.toInt() ?? 0,
      tableSessionId: json['tableSessionId']?.toString() ?? '',
    );
  }

  final String accessToken;
  final DateTime expiresAt;
  final String restaurantId;
  final int tableNo;
  final String tableSessionId;
}

class MenuItemResponse {
  MenuItemResponse({required this.id, required this.restaurantId, required this.category, required this.name, required this.imageUrl, required this.ingredients, required this.recipe, required this.averagePreparationTime, required this.price, required this.isAvailable});

  factory MenuItemResponse.fromJson(Map<String, dynamic> json) {
    return MenuItemResponse(
      id: json['id']?.toString() ?? '',
      restaurantId: json['restaurantId']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      ingredients: (json['ingredients'] as List<dynamic>? ?? const []).map((item) => item.toString()).toList(growable: false),
      recipe: json['recipe']?.toString(),
      averagePreparationTime: (json['averagePreparationTime'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toInt() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  final String id;
  final String restaurantId;
  final String category;
  final String name;
  final String imageUrl;
  final List<String> ingredients;
  final String? recipe;
  final int averagePreparationTime;
  final int price;
  final bool isAvailable;
}

class OrderItemResponse {
  OrderItemResponse({required this.orderItemId, required this.menuItemId, required this.name, required this.price, required this.orderedBy, required this.status, required this.paymentStatus});

  factory OrderItemResponse.fromJson(Map<String, dynamic> json) {
    return OrderItemResponse(
      orderItemId: json['orderItemId']?.toString() ?? '',
      menuItemId: json['menuItemId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      orderedBy: json['orderedBy']?.toString() ?? '',
      status: parseOrderItemStatus(json['status']),
      paymentStatus: parsePaymentStatus(json['paymentStatus']),
    );
  }

  final String orderItemId;
  final String menuItemId;
  final String name;
  final int price;
  final String orderedBy;
  final OrderItemStatus status;
  final PaymentStatus paymentStatus;
}

class OrderResponse {
  OrderResponse({required this.id, required this.restaurantId, required this.tableNo, required this.sessionStatus, required this.items, required this.totalAmount, required this.remainingAmount});

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      id: json['id']?.toString() ?? '',
      restaurantId: json['restaurantId']?.toString() ?? '',
      tableNo: (json['tableNo'] as num?)?.toInt() ?? 0,
      sessionStatus: parseOrderSessionStatus(json['sessionStatus']),
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderItemResponse.fromJson)
          .toList(growable: false),
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      remainingAmount: (json['remainingAmount'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String restaurantId;
  final int tableNo;
  final OrderSessionStatus sessionStatus;
  final List<OrderItemResponse> items;
  final int totalAmount;
  final int remainingAmount;
}

class BillResponse {
  BillResponse({required this.id, required this.restaurantId, required this.tableNo, required this.sessionStatus, required this.items, required this.totalAmount, required this.remainingAmount});

  factory BillResponse.fromJson(Map<String, dynamic> json) {
    return BillResponse(
      id: json['id']?.toString() ?? '',
      restaurantId: json['restaurantId']?.toString() ?? '',
      tableNo: (json['tableNo'] as num?)?.toInt() ?? 0,
      sessionStatus: parseOrderSessionStatus(json['sessionStatus']),
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderItemResponse.fromJson)
          .toList(growable: false),
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      remainingAmount: (json['remainingAmount'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String restaurantId;
  final int tableNo;
  final OrderSessionStatus sessionStatus;
  final List<OrderItemResponse> items;
  final int totalAmount;
  final int remainingAmount;
}

class PaymentResultDto {
  PaymentResultDto({required this.billId, required this.paidAmount, required this.remainingAmount, required this.status});

  factory PaymentResultDto.fromJson(Map<String, dynamic> json) {
    return PaymentResultDto(
      billId: json['billId']?.toString() ?? '',
      paidAmount: (json['paidAmount'] as num?)?.toInt() ?? 0,
      remainingAmount: (json['remainingAmount'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
    );
  }

  final String billId;
  final int paidAmount;
  final int remainingAmount;
  final String status;
}

class CustomerCardResponse {
  CustomerCardResponse({required this.id, required this.cardholderName, required this.brand, required this.last4, required this.expiryMonth, required this.expiryYear, required this.isDefault, required this.isActive, required this.createdAt});

  factory CustomerCardResponse.fromJson(Map<String, dynamic> json) {
    return CustomerCardResponse(
      id: json['id']?.toString() ?? '',
      cardholderName: json['cardholderName']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      last4: json['last4']?.toString() ?? '',
      expiryMonth: (json['expiryMonth'] as num?)?.toInt() ?? 0,
      expiryYear: (json['expiryYear'] as num?)?.toInt() ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String cardholderName;
  final String brand;
  final String last4;
  final int expiryMonth;
  final int expiryYear;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
}

class CustomerCardVerificationResponse {
  CustomerCardVerificationResponse({required this.isValid, required this.brand, required this.last4, required this.message});

  factory CustomerCardVerificationResponse.fromJson(Map<String, dynamic> json) {
    return CustomerCardVerificationResponse(
      isValid: json['isValid'] as bool? ?? false,
      brand: json['brand']?.toString() ?? '',
      last4: json['last4']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }

  final bool isValid;
  final String brand;
  final String last4;
  final String message;
}

/// Bir restoran yorumunu temsil eder. `myReaction` çağıran kullanıcının bu
/// yoruma verdiği tepkidir: 'like', 'dislike' veya null.
class ReviewResponse {
  ReviewResponse({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.rating,
    required this.likeCount,
    required this.dislikeCount,
    required this.myReaction,
    required this.isMine,
    required this.createdAt,
    required this.replies,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      id: json['id']?.toString() ?? '',
      restaurantId: json['restaurantId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      dislikeCount: (json['dislikeCount'] as num?)?.toInt() ?? 0,
      myReaction: json['myReaction']?.toString(),
      isMine: json['isMine'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      replies: (json['replies'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ReviewReplyResponse.fromJson)
          .toList(growable: false),
    );
  }

  final String id;
  final String restaurantId;
  final String userId;
  final String userName;
  final String comment;
  final int rating;
  final int likeCount;
  final int dislikeCount;
  final String? myReaction; // 'like' | 'dislike' | null
  final bool isMine;
  final DateTime createdAt;
  final List<ReviewReplyResponse> replies;

  bool get likedByMe => myReaction == 'like';
  bool get dislikedByMe => myReaction == 'dislike';
}

/// Bir yoruma yapılan yanıt. `mentionedUserName` @ ile etiketlenen kişidir.
class ReviewReplyResponse {
  ReviewReplyResponse({
    required this.id,
    required this.userId,
    required this.userName,
    required this.mentionedUserName,
    required this.comment,
    required this.isMine,
    required this.createdAt,
  });

  factory ReviewReplyResponse.fromJson(Map<String, dynamic> json) {
    return ReviewReplyResponse(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      mentionedUserName: json['mentionedUserName']?.toString(),
      comment: json['comment']?.toString() ?? '',
      isMine: json['isMine'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String userId;
  final String userName;
  final String? mentionedUserName;
  final String comment;
  final bool isMine;
  final DateTime createdAt;
}

/// Oturum açan kullanıcının profil bilgisi (`/api/profile/me`).
class UserProfileResponse {
  UserProfileResponse({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.restaurantId,
    required this.isActive,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      restaurantId: json['restaurantId']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  final String id;
  final String name;
  final String email;
  final String role;
  final String? restaurantId;
  final bool isActive;
}

extension IterableFirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}