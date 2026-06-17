import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jago/features/kantong/data/repositories/pocket_repository.dart';
import 'package:jago/features/topup/data/repositories/topup_repository.dart';
import 'package:jago/features/topup/presentation/bloc/topup_bloc.dart';

void main() {
  TopupBloc build() => TopupBloc(
        topup: MockTopupRepository(),
        pockets: MockPocketRepository(),
      );

  group('TopupBloc', () {
    blocTest<TopupBloc, TopupState>(
      'loads products + payable pockets on start',
      build: build,
      act: (bloc) => bloc.add(const TopupStarted()),
      wait: const Duration(milliseconds: 1500),
      verify: (bloc) {
        expect(bloc.state.status, TopupStatus.ready);
        expect(bloc.state.products, isNotEmpty);
        expect(bloc.state.pockets, isNotEmpty);
      },
    );

    blocTest<TopupBloc, TopupState>(
      'purchase produces a receipt',
      build: build,
      act: (bloc) async {
        bloc.add(const TopupStarted());
        await Future<void>.delayed(const Duration(milliseconds: 1300));
        bloc.add(const TopupPurchased(productId: 'pulsa-50', phone: '81234567890'));
      },
      wait: const Duration(milliseconds: 2000),
      verify: (bloc) {
        expect(bloc.state.status, TopupStatus.success);
        expect(bloc.state.receipt!.amount, 50000);
        expect(bloc.state.receipt!.phone, '81234567890');
      },
    );
  });
}
