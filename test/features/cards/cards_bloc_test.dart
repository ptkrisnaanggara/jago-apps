import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jago/features/cards/data/repositories/cards_repository.dart';
import 'package:jago/features/cards/presentation/bloc/cards_bloc.dart';

void main() {
  group('CardsBloc', () {
    blocTest<CardsBloc, CardsState>(
      'loads cards on start',
      build: () => CardsBloc(repository: MockCardsRepository()),
      act: (bloc) => bloc.add(const CardsStarted()),
      wait: const Duration(milliseconds: 800),
      expect: () => [
        isA<CardsState>()
            .having((s) => s.status, 'status', CardsStatus.loading),
        isA<CardsState>()
            .having((s) => s.status, 'status', CardsStatus.success)
            .having((s) => s.cards, 'cards', isNotEmpty),
      ],
    );

    blocTest<CardsBloc, CardsState>(
      'freezing a card updates its state and clears togglingId',
      build: () => CardsBloc(repository: MockCardsRepository()),
      act: (bloc) async {
        bloc.add(const CardsStarted());
        await Future<void>.delayed(const Duration(milliseconds: 800));
        bloc.add(const CardFrozenToggled(id: 'card1', frozen: true));
      },
      wait: const Duration(milliseconds: 1600),
      verify: (bloc) {
        final card = bloc.state.cards.firstWhere((c) => c.id == 'card1');
        expect(card.isFrozen, isTrue);
        expect(bloc.state.togglingId, isNull);
      },
    );
  });
}
