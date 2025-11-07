class Seller {
  final String id;
  final String name;
  final String? email;
  final String? avatar;
  final String location;
  final double reputation;
  final int totalSales;
  final int activeListings;
  final int soldListings;
  final String? campus;
  final DateTime? memberSince; // ✅ NUEVO: Fecha de registro

  Seller({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
    required this.location,
    required this.reputation,
    required this.totalSales,
    required this.activeListings,
    required this.soldListings,
    this.campus,
    this.memberSince, // ✅ NUEVO
  });
}