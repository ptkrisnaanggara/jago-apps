import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jago/features/kantong/data/models/pocket.dart';
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

    blocTest<KantongBloc, KantongState>(
      'creates a new pocket',
      build: () => KantongBloc(repository: MockPocketRepository()),
      act: (bloc) async {
        bloc.add(const KantongStarted());
        await Future<void>.delayed(const Duration(milliseconds: 700));
        bloc.add(const KantongPocketCreated(
            name: 'Jajan Harian', type: PocketType.spending));
      },
      wait: const Duration(milliseconds: 1400),
      verify: (bloc) {
        expect(bloc.state.pockets.any((p) => p.name == 'Jajan Harian'), isTrue);
      },
    );

    blocTest<KantongBloc, KantongState>(
      'moves money between pockets',
      build: () => KantongBloc(repository: MockPocketRepository()),
      act: (bloc) async {
        bloc.add(const KantongStarted());
        await Future<void>.delayed(const Duration(milliseconds: 700));
        bloc.add(const KantongMoneyMoved(
            fromId: 'p0', toId: 'p1', amount: 200000));
      },
      wait: const Duration(milliseconds: 1400),
      verify: (bloc) {
        final p0 = bloc.state.pockets.firstWhere((p) => p.id == 'p0');
        final p1 = bloc.state.pockets.firstWhere((p) => p.id == 'p1');
        expect(p0.balance, 800000);
        expect(p1.balance, 4700000);
      },
    );

    test('totalBalance sums pocket balances', () async {
      final pockets = await MockPocketRepository().getPockets();
      final expected = pockets.fold<double>(0, (sum, p) => sum + p.balance);
      final state = KantongState(pockets: pockets);
      expect(state.totalBalance, expected);
    });
  });
}
