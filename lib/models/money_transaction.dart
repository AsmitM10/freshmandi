/// Money received — Transactions is Money In only per approved scope
/// (Money Out / Expenses were removed, not just hidden).
class MoneyTransaction {
  final String id;
  final DateTime date;
  final String category;
  final String? partyId;
  final String? partyName;
  final double amount;
  final String method;
  final String? refType; // 'Order' | 'Manual'
  final String? refId;

  const MoneyTransaction({
    required this.id,
    required this.date,
    required this.category,
    this.partyId,
    this.partyName,
    required this.amount,
    required this.method,
    this.refType,
    this.refId,
  });

  factory MoneyTransaction.fromJson(Map<String, dynamic> json) => MoneyTransaction(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        category: json['category'] as String,
        partyId: json['party_id'] as String?,
        partyName: json['party_name'] as String?,
        amount: (json['amount'] as num).toDouble(),
        method: json['method'] as String,
        refType: json['ref_type'] as String?,
        refId: json['ref_id'] as String?,
      );

  Map<String, dynamic> toInsertJson() => {
        'category': category,
        'party_id': partyId,
        'party_name': partyName,
        'amount': amount,
        'method': method,
        'ref_type': refType ?? 'Manual',
        'ref_id': refId,
      };
}
