class Seller {
  final String id; // ✅ AGREGAR
  final String name;
  final String? email; // ✅ CAMBIAR a nullable
  final String? avatar; // ✅ CAMBIAR a nullable
  final String location;
  final double reputation;
  final int totalSales;
  final int activeListings;
  final int soldListings;
  final String? campus; // ✅ AGREGAR

  Seller({
    required this.id, // ✅ AGREGAR
    required this.name,
    this.email, // ✅ CAMBIAR
    this.avatar, // ✅ CAMBIAR
    required this.location,
    required this.reputation,
    required this.totalSales,
    required this.activeListings,
    required this.soldListings,
    this.campus, // ✅ AGREGAR
  });
}