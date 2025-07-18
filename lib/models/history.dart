enum HistoryStatus {
  borrowed,
  returned,
}

class History {
  final String id;
  final String itemId;
  final String itemName;
  final String borrowerName;
  final String responsiblePerson;
  final int quantity;
  final HistoryStatus status;
  final DateTime createdAt;
  final DateTime? returnedAt;

  History({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.borrowerName,
    required this.responsiblePerson,
    required this.quantity,
    required this.status,
    required this.createdAt,
    this.returnedAt,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      id: json['id'] ?? '',
      itemId: json['item_id'] ?? '',
      itemName: json['item_name'] ?? '',
      borrowerName: json['borrower_name'] ?? '',
      responsiblePerson: json['responsible_person'] ?? '',
      quantity: json['quantity'] ?? 1,
      status: HistoryStatus.values.firstWhere(
        (e) => e.toString() == 'HistoryStatus.${json['status']}',
        orElse: () => HistoryStatus.borrowed,
      ),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      returnedAt: json['returned_at'] != null 
          ? DateTime.parse(json['returned_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'item_name': itemName,
      'borrower_name': borrowerName,
      'responsible_person': responsiblePerson,
      'quantity': quantity,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'returned_at': returnedAt?.toIso8601String(),
    };
  }

  History copyWith({
    String? id,
    String? itemId,
    String? itemName,
    String? borrowerName,
    String? responsiblePerson,
    int? quantity,
    HistoryStatus? status,
    DateTime? createdAt,
    DateTime? returnedAt,
  }) {
    return History(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      borrowerName: borrowerName ?? this.borrowerName,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      returnedAt: returnedAt ?? this.returnedAt,
    );
  }
}
