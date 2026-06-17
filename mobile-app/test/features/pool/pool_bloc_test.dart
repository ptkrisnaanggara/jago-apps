import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jago/features/pool/data/repositories/pool_repository.dart';
import 'package:jago/features/pool/presentation/bloc/pool_detail_bloc.dart';
import 'package:jago/features/pool/presentation/bloc/pools_bloc.dart';

void main() {
  group('PoolsBloc', () {
    blocTest<PoolsBloc, PoolsState>(
      'starts empty then creating a pool adds it',
      build: () => PoolsBloc(repository: MockPoolRepository()),
      act: (bloc) async {
        bloc.add(const PoolsStarted());
        await Future<void>.delayed(const Duration(milliseconds: 600));
        bloc.add(const PoolCreated(title: 'Kado', target: 500000));
      },
      wait: const Duration(milliseconds: 1400),
      verify: (bloc) {
        expect(bloc.state.pools.length, 1);
        expect(bloc.state.pools.first.title, 'Kado');
      },
    );
  });

  group('PoolDetailBloc', () {
    test('contribute then close updates collected + status', () async {
      final repo = MockPoolRepository();
      final pool = await repo.createPool(title: 'Trip', target: 400000);

      final bloc = PoolDetailBloc(repository: repo)
        ..add(PoolDetailStarted(pool.id));
      await Future<void>.delayed(const Duration(milliseconds: 600));

      bloc.add(const PoolContributed(name: 'Andi', amount: 150000));
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(bloc.state.detail!.pool.collected, 150000);
      expect(bloc.state.detail!.contributions.length, 1);

      bloc.add(const PoolClosed());
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(bloc.state.detail!.pool.isOpen, isFalse);
    });
  });
}
