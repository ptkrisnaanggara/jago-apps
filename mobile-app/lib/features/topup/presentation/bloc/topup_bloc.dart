import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jago/core/errors/app_failure.dart';
import 'package:jago/features/kantong/data/models/pocket.dart';
import 'package:jago/features/kantong/data/repositories/pocket_repository.dart';

import '../../data/models/topup_models.dart';
import '../../data/repositories/topup_repository.dart';

part 'topup_event.dart';
part 'topup_state.dart';

/// Loads the prepaid catalog + payable pockets, then purchases a product.
class TopupBloc extends Bloc<TopupEvent, TopupState> {
  final TopupRepository _topup;
  final PocketRepository _pockets;

  TopupBloc({required TopupRepository topup, required PocketRepository pockets})
      : _topup = topup,
        _pockets = pockets,
        super(const TopupState()) {
    on<TopupStarted>(_onStarted);
    on<TopupPurchased>(_onPurchased);
  }

  Future<void> _onStarted(TopupStarted event, Emitter<TopupState> emit) async {
    emit(state.copyWith(status: TopupStatus.loading));
    try {
      final products = await _topup.products();
      final all = await _pockets.getPockets();
      final payable = all
          .where((p) =>
              p.type == PocketType.main || p.type == PocketType.spending)
          .toList();
      emit(state.copyWith(
        status: TopupStatus.ready,
        products: products,
        pockets: payable,
      ));
    } catch (_) {
      emit(state.copyWith(
          status: TopupStatus.failure, failure: AppFailure.topupFailed));
    }
  }

  Future<void> _onPurchased(
    TopupPurchased event,
    Emitter<TopupState> emit,
  ) async {
    emit(state.copyWith(status: TopupStatus.purchasing));
    try {
      final receipt = await _topup.purchase(
        productId: event.productId,
        phone: event.phone,
        pocketId: event.pocketId,
      );
      emit(state.copyWith(status: TopupStatus.success, receipt: receipt));
    } catch (_) {
      emit(state.copyWith(
          status: TopupStatus.ready, failure: AppFailure.topupFailed));
    }
  }
}
