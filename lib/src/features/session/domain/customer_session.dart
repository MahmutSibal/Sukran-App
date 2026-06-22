class CustomerSession {
  const CustomerSession({required this.restaurantId, required this.tableNo, required this.tableSessionId, required this.accessToken, this.refreshToken});

  final String restaurantId;
  final int tableNo;
  final String tableSessionId;
  final String accessToken;
  final String? refreshToken;

  CustomerSession copyWith({String? restaurantId, int? tableNo, String? tableSessionId, String? accessToken, String? refreshToken}) {
    return CustomerSession(
      restaurantId: restaurantId ?? this.restaurantId,
      tableNo: tableNo ?? this.tableNo,
      tableSessionId: tableSessionId ?? this.tableSessionId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}