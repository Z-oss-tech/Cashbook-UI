class PersonModel {
  final String id;
  final String name;
  final String phone;
  final double balance;

  PersonModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.balance,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'balance': balance,
    };
  }

  factory PersonModel.fromMap(
      Map<String, dynamic> map,
      ) {
    return PersonModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      balance: (map['balance'] ?? 0).toDouble(),
    );
  }
}