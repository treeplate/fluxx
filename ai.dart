import 'card.dart';
import 'cards/actions.dart';
import 'cards/creepers.dart';
import 'cards/goals.dart';
import 'cards/keepers.dart';
import 'cards/rules.dart';

abstract class PlayerState {
  const PlayerState();
  List<Set<Card>>? get hands; // null when the information is unknown
  Set<KeeperCard> get keepers;
  Set<CreeperCard> get creepers;
  AI get ai;
  String get name;
}

enum CardSource { deck, bottomOfDiscard }

String describeSource(CardSource source) {
  switch (source) {
    case CardSource.deck: return 'deck';
    case CardSource.bottomOfDiscard: return 'bottom of discard';
  }
}

abstract class GameState {
  const GameState();

  PlayerState get thisPlayer; // player for whom game state is being provided
  List<PlayerState> get players; // in order that they will play, current player is first
  List<Card> get discard; // top card is last
  List<NewRuleCard> get rules;

  int get drawnThisTurn;
  int get playedThisTurn;

  int get drawRule;
  int get playRule;
  // TODO: put the other limits here too and remove them from complyWithLimits
  bool get canDrawFromBottomOfDiscard;

  GoalCard? get goal;

  bool get deckEmpty;
}

abstract class GameInterface {
  GameInterface();

  Card draw({ CardSource source = CardSource.deck });
  void playFromHand(Card card); // will throw if you still need to draw
  void discardFromHand(Card card);
  void discardFromKeepers(KeeperCard card);

  GameState get state;
}

class ExchangeKeepersResult {
  const ExchangeKeepersResult(this.theirs, this.ours);
  final KeeperCard theirs;
  final KeeperCard ours;
}

class AI {
  const AI(this.name);

  final String name;

  String toString() => "AI $name";

  // if you don't play a valid full turn, you lose
  void play(GameInterface game) {
    do {
      final GameState state = game.state;
      if (state.drawnThisTurn < state.drawRule && !state.deckEmpty) {
        if (drawCard(game) != null) {
          continue;
        }
      }
      if (((state.playedThisTurn < state.playRule) || state.playRule == 0) && (state.thisPlayer.hands!.single.isNotEmpty)) {
        playCard(game);
        continue;
      }
      break;
    } while (true);
  }

  Card? drawCard(GameInterface game) {
    while (!game.state.deckEmpty) {
      Card card = game.draw();
      if (card is! CreeperCard) {
        return card;
      }
    }
    return null;
  }

  void playCard(GameInterface game) {
    game.playFromHand(game.state.thisPlayer.hands!.last.first);
  }

  void complyWithLimits(GameInterface game, int handLimit, int keeperLimit) {
    while (handLimit >= 0 && game.state.thisPlayer.hands!.first.length > handLimit) {
      Card card = game.state.thisPlayer.hands!.first.first;
      game.discardFromHand(card);
    }
    while (keeperLimit >= 0 && game.state.thisPlayer.keepers.length > keeperLimit) {
      KeeperCard card = game.state.thisPlayer.keepers.first;
      game.state.thisPlayer.keepers.remove(card);
      game.discardFromKeepers(card);
    }
  }

  void drawBonusCards(int count, GameInterface game) {
    for (int index = 0; index < count; index += 1) {
      if (drawCard(game) == null) {
        return;
      }
    }
  }

  KeeperCard? chooseLivingKeeperForExtinction(GameInterface game) {
    return game.state.players
        .expand((PlayerState player) => player.keepers)
        .cast<KeeperCard?>()
        .firstWhere((KeeperCard? card) => card != null && card.isAlive, orElse: () => null);
  }

  Card? chooseCardForLetsDoThatAgain(GameInterface game) {
    return game.state.discard.cast<Card?>().firstWhere((Card? card) {
      return card is ActionCard || card is NewRuleCard;
    }, orElse: () => null);
  }

  KeeperCard? chooseKeeperToSteal(GameInterface game) {
    GameState state = game.state;
    return state.players
        .where((PlayerState player) => player.ai != this)
        .expand((PlayerState player) => player.keepers)
        .cast<KeeperCard?>()
        .firstWhere((KeeperCard? card) => true, orElse: () => null);
  }

  List<Card?> chooseCardsForEverybodyGetsOne(GameInterface game) {
    List<Card?> cards = [];
    for (PlayerState _ in game.state.players) {
      GameState state = game.state;
      if (!state.deckEmpty) {
        cards.add(drawCard(game)!);
      } else {
        cards.add(null);
      }
    }
    return cards;
  }

  Card chooseCardForTaxation(PlayerState taxer, GameInterface game) {
    return game.state.thisPlayer.hands!.first.first;
  }

  ExchangeKeepersResult chooseCardsForExchangeKeepers(GameInterface game) {
    GameState state = game.state;
    return ExchangeKeepersResult(
      state.players
        .where((PlayerState player) => player.ai != this)
        .expand((PlayerState player) => player.keepers)
        .cast<KeeperCard>()
        .first,
      state.thisPlayer
        .keepers
        .first,
    );
  }

  void drawCardsForDNPM(int n, GameInterface game) {
    drawBonusCards(n, game);
  }

  void playCardsForDNPM(int m, GameInterface game) {
    for(; m > 0; m--) {
      playCard(game);
    }
  }

  int tradeHands(GameInterface game) {
    return 1;
  }
}