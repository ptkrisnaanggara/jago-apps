part of 'topup_bloc.dart';

sealed class TopupEvent extends Equatable {
  const TopupEvent();

  @override
  List<Object?> get props => [];
}

class TopupStarted extends TopupEvent {
  const TopupStarted();
}

class TopupPurchased extends TopupEvent {
  final String productId;
  final String phone;
  final String? pocketId;

  const TopupPurchased({
    required this.productId,
    required this.phone,
    this.pocketId,
  });

  @override
  List<Object?> get props => [productId, phone, pocketId];
}
