import 'package:jago/core/network/api_client.dart';

import '../models/transaction.dart';
import 'transaction_repository.dart';

/// Backend-backed [TransactionRepository].
class ApiTransactionRepository implements TransactionRepository {
  final ApiClient _api;

  ApiTransactionRepository(this._api);

  @override
  Future<List<TransactionItem>> getTransactions({String? type}) async {
    final list = await _api.get('/transactions',
        query: {if (type != null) 'type': type}) as List<dynamic>;
    return list
        .map((e) => _txFromJson(e as Map<String, dynamic>))
        .toList();
  }

  TransactionItem _txFromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      date: DateTime.parse(json['createdAt'] as String),
    );
  }
}
