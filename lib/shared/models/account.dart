class Account {
  final int id;
  final String name;
  final bool isMain;
  final int sortOrder;
  final String currency;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.isMain,
    required this.sortOrder,
    required this.currency,
    required this.createdAt,
  });
}
