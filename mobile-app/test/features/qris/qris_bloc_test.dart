import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jago/features/kantong/data/repositories/pocket_repository.dart';
import 'package:jago/features/qris/data/repositories/qris_repository.dart';
import 'package:jago/features/qris/presentation/bloc/qris_bloc.dart';

void main() {
  QrisBloc build() => QrisBloc(
        qris: MockQrisRepository(),
        pockets: MockPocketRepository(),
      );

  group('QrisBloc', () {
    blocTest<QrisBloc, QrisState>(
      'loads payable pockets on start',
      build: build,
      act: (bloc) => bloc.add(const QrisStarted()),
      wait: const Duration(milliseconds: 800),
      verify: (bloc) {
        expect(bloc.state.status, QrisStatus.ready);
        expect(bloc.state.pockets, isNotEmpty);
      },
    );

    blocTest<QrisBloc, QrisState>(
      'parse → pay produces a receipt',
      build: build,
      act: (bloc) async {
        bloc.add(const QrisStarted());
        await Future<void>.delayed(const Duration(milliseconds: 700));
        bloc.add(const QrisParseRequested('demo-payload'));
        await Future<void>.delayed(const Duration(milliseconds: 600));
        bloc.add(const QrisPaid(amount: 30000));
      },
      wait: const Duration(milliseconds: 1500),
      verify: (bloc) {
        expect(bloc.state.status, QrisStatus.success);
        expect(bloc.state.receipt, isNotNull);
        expect(bloc.state.receipt!.amount, 30000);
      },
    );
  });
}
