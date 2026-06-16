import '../models/payment_card.dart';

/// Contract for the user's payment cards. UI/BLoC depend on this, not the mock.
abstract class CardsRepository {
  Future<List<PaymentCard>> getCards();

  /// Freezes/unfreezes a card and returns the updated list.
  Future<List<PaymentCard>> setFrozen(String id, {required bool frozen});
}

/// Temporary mock. Holds a mutable in-memory list so freeze toggles persist
/// for the session (a real impl would call an API).
class MockCardsRepository implements CardsRepository {
  static const _latency = Duration(milliseconds: 600);

  final List<PaymentCard> _cards = [
    const PaymentCard(
      id: 'card1',
      label: 'Kartu Utama',
      number: '4567 8901 2345 6789',
      holderName: 'SHANKARA ANGGARA',
      expiry: '08/27',
      cvv: '123',
      type: CardType.physical,
      accentIndex: 0,
    ),
    const PaymentCard(
      id: 'card2',
      label: 'Kartu Virtual',
      number: '5234 1122 8890 4521',
      holderName: 'SHANKARA ANGGARA',
      expiry: '11/26',
      cvv: '456',
      type: CardType.virtual,
      accentIndex: 1,
    ),
  ];

  @override
  Future<List<PaymentCard>> getCards() async {
    await Future<void>.delayed(_latency);
    return List.unmodifiable(_cards);
  }

  @override
  Future<List<PaymentCard>> setFrozen(String id, {required bool frozen}) async {
    await Future<void>.delayed(_latency);
    final i = _cards.indexWhere((c) => c.id == id);
    if (i != -1) _cards[i] = _cards[i].copyWith(isFrozen: frozen);
    return List.unmodifiable(_cards);
  }
}
