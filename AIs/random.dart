import 'dart:math' as math;

import '../ai.dart';
import '../card.dart';
import '../cards/actions.dart';
import '../cards/creepers.dart';
import '../cards/goals.dart';
import '../cards/keepers.dart';
import '../cards/rules.dart';

class RandomAI extends AI {
  RandomAI(String name, this.random) : super('Random $name');

  final math.Random random;

  Card/*?*/ drawCard(GameInterface game) {
    CardSource source = CardSource.deck;
    GameState state = game.state;
    while (!state.deckEmpty) {
      if (state.canDrawFromBottomOfDiscard && state.discard.isNotEmpty) {
        if (random.nextBool())
          source = CardSource.bottomOfDiscard;
      }
      Card card = game.draw(source: source);
      if (card is! CreeperCard) {
        return card;
      }
      state = game.state;
    }
    return null;
  }

  void playCard(GameInterface game) {
    GameState state = game.state;
    game.playFromHand(state.thisPlayer.hands.last.toList()[random.nextInt(state.thisPlayer.hands.length)]);
  }

  void complyWithLimits(GameInterface game, int handLimit, int keeperLimit) {
    super.complyWithLimits(game, handLimit, keeperLimit);
  }

  KeeperCard/*?*/ chooseLivingKeeperForExtinction(GameInterface game) {
    return (game.state.players
        .expand((PlayerState player) => player.keepers)
        .cast<KeeperCard/*?*/>()
        .toList()..shuffle(random))
        .firstWhere((KeeperCard card) => card.isAlive, orElse: () => null);
  }

  Card/*?*/ chooseCardForLetsDoThatAgain(GameInterface game) {
    return (game.state.discard.cast<Card/*?*/>().toList()..shuffle(random)).firstWhere((Card card) {
      return card is ActionCard || card is NewRuleCard;
    }, orElse: () => null);
  }

  KeeperCard/*?*/ chooseKeeperToSteal(GameInterface game) {
    GameState state = game.state;
    return (state.players
        .where((PlayerState player) => player.ai != this)
        .expand((PlayerState player) => player.keepers)
        .cast<KeeperCard/*?*/>()
        .toList()
        ..shuffle(random))
        .firstWhere((KeeperCard card) => true, orElse: () => null);
  }

  Card chooseCardForTaxation(PlayerState taxer, GameInterface game) {
    return (game.state.thisPlayer.hands.single.toList()..shuffle(random)).first;
  }

  ExchangeKeepersResult chooseCardsForExchangeKeepers(GameInterface game) {
    GameState state = game.state;
    return ExchangeKeepersResult(
      (state.players
        .where((PlayerState player) => player.ai != this)
        .expand((PlayerState player) => player.keepers)
        .cast<KeeperCard/*?*/>()
        .toList()
        ..shuffle(random))
        .first,
      (state.thisPlayer
        .keepers
        .toList()
        ..shuffle)
        .first,
    );
  }

  int tradeHands(GameInterface game) {
    return random.nextInt(game.state.players.length - 1) + 1;
  }
}