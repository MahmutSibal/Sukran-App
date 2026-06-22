enum AppUserRole {
  superAdmin,
  customer,
  restaurantOwner,
}

extension AppUserRoleX on AppUserRole {
  int get apiValue {
    switch (this) {
      case AppUserRole.superAdmin:
        return 1;
      case AppUserRole.restaurantOwner:
        return 2;
      case AppUserRole.customer:
        return 4;
    }
  }

  String get label {
    switch (this) {
      case AppUserRole.superAdmin:
        return 'Süper Admin';
      case AppUserRole.customer:
        return 'Müşteri';
      case AppUserRole.restaurantOwner:
        return 'İşletme';
    }
  }
}

/// Backend JWT'sinden ya da yerel depodan gelen rol değerini esnek biçimde
/// çözer. Hem metinsel (customer, RestaurantOwner, SuperAdmin) hem de sayısal
/// (1..4) gösterimleri destekler.
AppUserRole? appUserRoleFromStorage(String? value) {
  if (value == null) return null;
  switch (value.toLowerCase().trim()) {
    case 'superadmin':
    case 'super_admin':
    case 'admin':
    case '1':
      return AppUserRole.superAdmin;
    case 'restaurantowner':
    case 'owner':
    case 'isletme':
    case '2':
      return AppUserRole.restaurantOwner;
    case 'customer':
    case 'musteri':
    case '4':
      return AppUserRole.customer;
    default:
      return null;
  }
}
