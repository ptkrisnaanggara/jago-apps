import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jago/features/kantong/data/repositories/pocket_repository.dart';
import 'package:jago/features/kantong/presentation/bloc/kantong_bloc.dart';

void main() {
  group('KantongBloc', () {
    blocTest<KantongBloc, KantongState>(
      'emits [loading, success] with a non-empty pocket list',
      build: () => KantongBloc(repository: MockPocketRepository()),
      act: (bloc) => bloc.add(const KantongStarted()),
      wait: const Duration(milliseconds: 900),
      expect: () => [
        isA<KantongState>()
            .having((s) => s.status, 'status', KantongStatus.loading),
        isA<KantongState>()
            .having((s) => s.status, 'status', KantongStatus.success)
            .having((s) => s.pockets.isNotEmpty, 'hasPockets', true),
      ],
    );

    test('totalBalance sums pocket balances', () async {
      final pockets = await MockPocketRepository().getPockets();
      final expected = pockets.fold<double>(0, (sum, p) => sum + p.balance);
      final state = KantongState(pockets: pockets);
      expect(state.totalBalance, expected);
    });
  });
}
