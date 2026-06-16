import 'package:jago/core/network/api_client.dart';

import '../models/payment_card.dart';
import 'cards_repository.dart';

/// Backend-backed [CardsRepository]. `accentIndex` (a UI gradient pick) is
/// derived from list position since the API doesn't model it.
class ApiCardsRepository implements CardsRepository {
  final ApiClient _api;

  ApiCardsRepository(this._api);

  @override
  Future<List<PaymentCard>> getCards() async {
    final list = await _api.get('/cards') as List<dynamic>;
    return _mapCards(list);
  }

  @override
  Future<List<PaymentCard>> setFrozen(String id, {required bool frozen}) async {
    await _api.post('/cards/$id/freeze', body: {'frozen': frozen});
    return getCards();
  }

  List<PaymentCard> _mapCards(List<dynamic> list) {
    return [
      for (var i = 0; i < list.length; i++)
        _cardFromJson(list[i] as Map<String, dynamic>, i),
    ];
  }

  PaymentCard _cardFromJson(Map<String, dynamic> json, int index) {
    return PaymentCard(
      id: json['id'] as String,
      label: json['label'] as String,
      number: json['number'] as String,
      holderName: json['holderName'] as String,
      expiry: json['expiry'] as String,
      cvv: json['cvv'] as String,
      type: json['type'] == 'virtual' ? CardType.virtual : CardType.physical,
      isFrozen: json['isFrozen'] as bool? ?? false,
      accentIndex: index,
    );
  }
}
