import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jago/features/transfer/data/models/contact.dart';
import 'package:jago/features/transfer/data/repositories/transfer_repository.dart';
import 'package:jago/features/transfer/presentation/bloc/transfer_bloc.dart';

void main() {
  const contact = Contact(
    id: 'c1',
    name: 'Budi Santoso',
    bankName: 'Bank Jago',
    accountNumber: '100 8420 5566',
  );

  group('TransferBloc', () {
    blocTest<TransferBloc, TransferState>(
      'loads contacts on start',
      build: () => TransferBloc(repository: MockTransferRepository()),
      act: (bloc) => bloc.add(const TransferStarted()),
      wait: const Duration(milliseconds: 800),
      expect: () => [
        isA<TransferState>()
            .having((s) => s.status, 'status', TransferStatus.loading),
        isA<TransferState>()
            .having((s) => s.status, 'status', TransferStatus.success)
            .having((s) => s.contacts, 'contacts', isNotEmpty),
      ],
    );

    blocTest<TransferBloc, TransferState>(
      'full flow ends completed with a receipt',
      build: () => TransferBloc(repository: MockTransferRepository()),
      act: (bloc) async {
        bloc.add(const TransferStarted());
        await Future<void>.delayed(const Duration(milliseconds: 800));
        bloc.add(const TransferContactSelected(contact));
        bloc.add(const TransferDetailsEntered(amount: 50000, note: 'Makan'));
        bloc.add(const TransferConfirmed());
      },
      wait: const Duration(milliseconds: 1600),
      expect: () => [
        isA<TransferState>()
            .having((s) => s.status, 'status', TransferStatus.loading),
        isA<TransferState>()
            .having((s) => s.status, 'status', TransferStatus.success),
        isA<TransferState>()
            .having((s) => s.selectedContact, 'selectedContact', contact),
        isA<TransferState>().having((s) => s.amount, 'amount', 50000),
        isA<TransferState>()
            .having((s) => s.status, 'status', TransferStatus.submitting),
        isA<TransferState>()
            .having((s) => s.status, 'status', TransferStatus.completed)
            .having((s) => s.result, 'result', isNotNull),
      ],
    );

    blocTest<TransferBloc, TransferState>(
      'search narrows the contact list',
      build: () => TransferBloc(repository: MockTransferRepository()),
      act: (bloc) async {
        bloc.add(const TransferStarted());
        await Future<void>.delayed(const Duration(milliseconds: 800));
        bloc.add(const TransferSearchChanged('budi'));
      },
      wait: const Duration(milliseconds: 1000),
      verify: (bloc) {
        expect(bloc.state.filteredContacts.length, 1);
        expect(bloc.state.filteredContacts.first.name, 'Budi Santoso');
      },
    );
  });
}
