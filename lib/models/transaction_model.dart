class CashbookModel {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;

  CashbookModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory CashbookModel.fromMap(Map<String, dynamic> map) {
    return CashbookModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}

class RecordModel {
  final String id;
  final String cashbookId;
  final String title;
  final double amount;
  final String type; // 'income' or 'expense'
  final String? category;
  final String? paymentMethod;
  final String note;
  final DateTime date;
  final String? cashbookName;
  final String? attachmentUrl;

  // Computed properties for UI backwards compatibility
  String get personName => title;
  bool get isGiven => type == 'expense';

  RecordModel({
    required this.id,
    required this.cashbookId,
    required this.title,
    required this.amount,
    required this.type,
    this.category,
    this.paymentMethod,
    required this.note,
    required this.date,
    this.cashbookName,
    this.attachmentUrl,
  });

  factory RecordModel.fromMap(Map<String, dynamic> map) {
    return RecordModel(
      id: map['id'] ?? '',
      cashbookId: map['cashbookId'] ?? '',
      title: map['title'] ?? map['personName'] ?? 'Unknown',
      amount: double.tryParse(map['amount'].toString()) ?? 0.0,
      type: map['type'] ?? (map['isGiven'] == true ? 'expense' : 'income'),
      category: map['category'],
      paymentMethod: map['paymentMethod'],
      note: map['note'] ?? '',
      date: map['transactionDate'] != null
          ? DateTime.parse(map['transactionDate'])
          : (map['date'] != null
                ? DateTime.parse(map['date'])
                : DateTime.now()),
      cashbookName: map['cashbookName'] ?? 'TestBook',
      attachmentUrl: map['attachmentUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cashbookId': cashbookId,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'paymentMethod': paymentMethod,
      'note': note,
      'transactionDate': date.toIso8601String(),
      'cashbookName': cashbookName,
      'attachmentUrl': attachmentUrl,
    };
  }
}
