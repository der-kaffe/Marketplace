class Seller {
  final String name;
  final String avatar;
  final String location;
  final double reputation;
  final int totalSales;
  final int activeListings;
  final int soldListings;

  Seller({
    required this.name,
    required this.avatar,
    required this.location,
    required this.reputation,
    required this.totalSales,
    required this.activeListings,
    required this.soldListings,
  });
}
