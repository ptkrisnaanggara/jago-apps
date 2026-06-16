import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jago/features/bills/data/models/bill.dart';
import 'package:jago/features/bills/data/repositories/bills_repository.dart';
import 'package:jago/features/bills/presentation/bloc/bills_bloc.dart';

void main() {
  group('BillsBloc', () {
    blocTest<BillsBloc, BillsState>(
      'loads bills on start',
      build: () => BillsBloc(repository: MockBillsRepository()),
      act: (bloc) => bloc.add(const BillsStarted()),
      wait: const Duration(milliseconds: 800),
      expect: () => [
        isA<BillsState>()
            .having((s) => s.status, 'status', BillsStatus.loading),
        isA<BillsState>()
            .having((s) => s.status, 'status', BillsStatus.success)
            .having((s) => s.bills, 'bills', isNotEmpty),
      ],
    );

    blocTest<BillsBloc, BillsState>(
      'paying a bill moves it from upcoming to paid',
      build: () => BillsBloc(repository: MockBillsRepository()),
      act: (bloc) async {
        bloc.add(const BillsStarted());
        await Future<void>.delayed(const Duration(milliseconds: 800));
        bloc.add(const BillPaid('b1'));
      },
      wait: const Duration(milliseconds: 1600),
      verify: (bloc) {
        final paidIds = bloc.state.paidBills.map((b) => b.id);
        expect(paidIds, contains('b1'));
        expect(bloc.state.upcomingBills.any((b) => b.id == 'b1'), isFalse);
        expect(bloc.state.payingId, isNull);
      },
    );

    blocTest<BillsBloc, BillsState>(
      'scheduling a bill appends it to the list',
      build: () => BillsBloc(repository: MockBillsRepository()),
      act: (bloc) async {
        bloc.add(const BillsStarted());
        await Future<void>.delayed(const Duration(milliseconds: 800));
        bloc.add(BillScheduled(Bill(
          id: 'new1',
          biller: 'Spotify',
          category: 'Lainnya',
          amount: 54990,
          dueDate: DateTime.now().add(const Duration(days: 5)),
          recurrence: BillRecurrence.monthly,
        )));
      },
      wait: const Duration(milliseconds: 1600),
      verify: (bloc) {
        expect(bloc.state.bills.any((b) => b.id == 'new1'), isTrue);
      },
    );
  });
}
