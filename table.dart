import 'dart:core';
import 'dart:core' as core show print;
import 'dart:math' as math show Random;
import 'dart:io';

import 'ai.dart';
import 'card.dart';
import 'cards/actions.dart';
import 'cards/creepers.dart';
import 'cards/goals.dart';
import 'cards/keepers.dart';
import 'cards/rules.dart';

typedef GameOverHandler = void Function(Exception exception, StackTrace stack);

class GameOver implements Exception {
  static GameOverHandler _handler;

  static void terminate(Object exception) {
    _handler(exception, StackTrace.current);
  }
}

class _Tie implements GameOver {
  _Tie(this.message);
  final String message;
  String toString() => message;
}

class _GoalWin implements GameOver {
  _GoalWin(this.winner, this.goal);
  final AI winner;
  final GoalCard goal;
}

class RuleViolation implements GameOver {
  RuleViolation(this.error, this.ai);
  final String error;
  final AI ai;
  String toString() => error;
}

class _PlayerState extends PlayerState {
  const _PlayerState(this.hands, this.keepers, this.creepers, this.ai);
  final List<Set<Card>>/*?*/ hands;
  final Set<KeeperCard> keepers;
  final Set<CreeperCard> creepers;
  final AI ai;

  String get name => ai.name;
}

class _GameState extends GameState {
  const _GameState({
    this.thisPlayer, this.players,
    this.discard, this.rules,
    this.drawnThisTurn, this.playedThisTurn,
    this.drawRule, this.playRule,
    this.canDrawFromBottomOfDiscard,
    this.deckEmpty,
    this.goal,
  });

  final PlayerState thisPlayer;
  final List<PlayerState> players;
  final List<Card> discard;
  final List<NewRuleCard> rules;
  final int drawnThisTurn;
  final int playedThisTurn;
  final int drawRule;
  final int playRule;
  final bool canDrawFromBottomOfDiscard;
  final bool deckEmpty;
  final GoalCard goal;
}

typedef DrawCardHandler = Card Function(CardSource source);
typedef UseCardHandler = void Function(Card card);
typedef UseKeeperCardHandler = void Function(KeeperCard card);
typedef StateHandler = GameState Function();

class Game extends GameInterface {
  Game({
    this.drawHandler, 
    this.playFromHandHandler,
    this.discardFromHandHandler,
    this.discardFromKeepersHandler,
    this.stateHandler,
  });

  final DrawCardHandler/*?*/ drawHandler;
  final UseCardHandler/*?*/ playFromHandHandler;
  final UseCardHandler/*?*/ discardFromHandHandler;
  final UseKeeperCardHandler/*?*/ discardFromKeepersHandler;
  final StateHandler stateHandler;

  Card draw({ CardSource source = CardSource.deck }) {
    if (drawHandler == null) {
      GameOver.terminate(RuleViolation('${state.players.first.name} tried to draw a card when it was not approriate.', state.players.first.ai));
    }
    return drawHandler(source);
  }

  void playFromHand(Card card) {
    if (playFromHandHandler == null) {
      GameOver.terminate(RuleViolation('${state.players.first.name} tried to play a card ($card) when it was not approriate.', state.players.first.ai));
    }
    playFromHandHandler(card);
  }

  void discardFromHand(Card card) {
    if (discardFromHandHandler == null) {
      GameOver.terminate(RuleViolation('${state.players.first.name} tried to discard a card from their hand ($card) when it was not approriate.', state.players.first.ai));
    }
    discardFromHandHandler(card);
  }

  void discardFromKeepers(KeeperCard card) {
    if (discardFromKeepersHandler == null) {
      GameOver.terminate(RuleViolation('${state.players.first.name} tried to discard a keeper ($card) when it was not approriate.', state.players.first.ai));
    }
    discardFromKeepersHandler(card);
  }

  GameState get state => stateHandler();
}

class Player {
  Player(this.ai);
  final List<Set<Card>>/*?*/ hands = [<Card>{}];
  final Set<KeeperCard> keepers = <KeeperCard>{};
  final Set<CreeperCard> creepers = <CreeperCard>{};
  final AI ai;

  bool canEat(KeeperCard food) {
    for (KeeperCard card in keepers) {
      if (card.preventsEating(food))
        return false;
    }
    return true;
  }

  _PlayerState toPlayerState(bool active) {
    return _PlayerState(
      active ? hands.map((x) => x.toSet()).toList() : null,
      keepers.toSet(),
      creepers.toSet(),
      ai,
    );
  }

  String toString() => ai.name;
}

class Table {
  Table._(this.random, this.deck, this.showGame);

  static void run(math.Random random, { List<Card> deck, List<AI> players = const <AI>[], bool showGame = true }) {
    Table table = Table._(random, deck, showGame);
    table.players.addAll(players.map((AI ai) => Player(ai)));
    GameOver._handler = (Exception e, StackTrace stack) {
      if (e is RuleViolation) {
        stderr.writeln('${e.error}');
        stderr.writeln('${e.ai.name} loses, everyone else wins.');
      } else if (e is UnimplementedError) {
        stderr.writeln('Unimplemented feature: $e');
      } else if (e is _GoalWin) {
        if (showGame) {
          print("Winner: ${e.winner.name}");
        } else {
          core.print('${e.winner.name.replaceAll(' ', "-")}');
        }
      } else if (e is _Tie) {
        stderr.writeln('$e');
        core.print("TIED");
      } else {
        stderr.writeln('Logic error detected: $e\n$stack');
      }
      exit(0);
    };
    table._play();
  }

  final math.Random random;

  final List<Player> players = [];
  int playedThisTurn;
  int drawnThisTurn;
  final bool showGame;

  static final Set<NewRuleCard> basicRules = {DrawRule(1), PlayRule(1)};
  final List<NewRuleCard> rules = basicRules.toList();
  final List<Card> deck;
  final List<Card> discard = [];
  GoalCard goal;

  static const int defaultHandSize = 3;

  void log(Object source, Object message) {
    if (showGame) {
      core.print('[$source] $message');
    }
  }

  void _play() {
    log(this, 'Starting game with ${deck.length} cards in the deck.');
    deck.shuffle(random);
    players.shuffle(random);
    log(this, 'Players: ${players.map<String>((Player player) => player.ai.name).join(", ")}');
    for (int index = 0; index < defaultHandSize; index += 1) {
      for (Player player in players) {
        Card card;
        do {
          if (deck.isEmpty) {
            GameOver.terminate(_Tie('Insufficient non-Creeper cards to start game.'));
          }
          card = drawCard(player, CardSource.deck);
          if (card is! CreeperCard) {
            player.hands.first.add(card);
          }
        } while (card is CreeperCard);
      }
    }
    while (true) {
      log(this, '');
      log(this, '${players.first.ai.name}\'s turn.');
      log(this, 'Deck size: ${deck.length}; Discard size: ${discard.length}; Draw $drawRule, Play $playRule, Hand Limit ${handLimitRule == -1 ? "unbounded" : handLimitRule}, Keeper Limit ${keeperLimitRule == -1 ? "unbounded" : keeperLimitRule}');
      log(this, 'Hand: ${players.first.hands.single.isEmpty ? "<empty>" : players.first.hands.single.join(", ")}');
      log(this, 'Keepers: ${players.first.keepers.isEmpty ? "<none>" : players.first.keepers.join(", ")}');
      log(this, 'Creepers: ${players.first.creepers.isEmpty ? "<none>" : players.first.creepers.join(", ")}');
      log(this, 'Rules: ${rules.join(", ")}');
      log(this, 'Goal: ${goal ?? "<none>"}');
      _playTurn(players.first);
      players.add(players.removeAt(0));
    }
  }

  _GameState stateForPlayer(Player player) {
    return _GameState(
      thisPlayer: player.toPlayerState(true),
      players: players.map<PlayerState>((Player player) => player.toPlayerState(false)).toList(),
      discard: discard.toList(),
      rules: rules.toList(),
      drawnThisTurn: drawnThisTurn,
      playedThisTurn: playedThisTurn,
      drawRule: drawRule,
      playRule: playRule,
      canDrawFromBottomOfDiscard: canDrawFromBottomOfDiscard,
      deckEmpty: deck.isEmpty && discard.isEmpty,
      goal: goal,
    );
  }

  void _playTurn(Player player) {
    playedThisTurn = 0;
    drawnThisTurn = 0;
   
    for (NewRuleCard rule in rules) {
      rule.turnStart(this);
    }

    GameInterface gameForPlayer = Game(
      drawHandler: (CardSource source) {
        for (NewRuleCard rule in rules) {
          if (!rule.canDraw(this)) {
            GameOver.terminate(RuleViolation('${player.ai.name} cannot draw at this time ($rule says no).', player.ai));
          }
        }
        Card card = drawCard(player, source);
        if (card is! CreeperCard) {
          player.hands.first.add(card);
          drawnThisTurn += 1;
        }
        checkpoint();
        return card;
      },
      playFromHandHandler: (Card card) {
        for (NewRuleCard rule in rules) {
          if (!rule.canPlay(this)) {
            GameOver.terminate(RuleViolation('${player.ai.name} cannot play at this time ($rule says no).', player.ai));
          }
        }
        playedThisTurn += 1;
        playCard(player, card);
      },
      stateHandler: () => stateForPlayer(player),
    );
    try {
      player.ai.play(gameForPlayer);
    } catch (e, stack) {
      if (e is GameOver)
        GameOver.terminate(e);
      GameOver.terminate(RuleViolation('${player.ai.name} threw an exception: $e\n$stack', player.ai));
    }

    for (NewRuleCard rule in rules) {
      rule.turnEnd(this);
    }

    enforceLimits(player);
    playedThisTurn = null;
    drawnThisTurn = null;
  }

  Card drawCard(Player player, CardSource source) {
    Card result;
    switch (source) {
      case CardSource.deck:
        if (deck.isEmpty) {
          if (discard.isEmpty) {
            GameOver.terminate(RuleViolation('${player.ai.name} tried to draw but deck and discard are both empty.', player.ai));
          }
          log(this, 'Deck is empty; shuffling discard back into deck.');
          deck.addAll(discard);
          discard.clear();
          deck.shuffle(random);
        }
        result = deck.removeAt(0);
        break;
      case CardSource.bottomOfDiscard:
        if (!canDrawFromBottomOfDiscard) {
          GameOver.terminate(RuleViolation('${player.ai.name} tried to draw from discard but that is not allowed.', player.ai));
        }
        if (discard.isEmpty) {
          GameOver.terminate(RuleViolation('${player.ai.name} tried to draw from discard but discard is empty.', player.ai));
        }
        result = discard.removeAt(0);
        break;
    }
    log(this, '${player.ai.name} drew $result from ${describeSource(source)}.');
    if (result is CreeperCard) {
      log(this, 'Placed creeper $result in front of ${player.ai.name}.');
      player.creepers.add(result);
    }
    return result;
  }

  void playCard(Player player, Card card) {
    if (!player.hands.last.remove(card)) {
      GameOver.terminate(RuleViolation('${player.ai.name} tried to play card $card which was not in their hand.', player.ai));
    }
    log(this, '${player.ai.name} played $card from their hand.');
    card.play(this, player);
  }

  void setGoal(GoalCard card) {
    // TODO: multigoal will need this changed
    if (goal != null) {
      log(this, 'Previous goal, $goal, discarded.');
      discard.add(goal);
    }
    goal = card;
    log(this, 'Goal changed to $goal.');
    List<CreeperCard> creepers = players
      .expand<CreeperCard>((Player player) => player.creepers)
      .toList();
    for (CreeperCard creeper in creepers) {
      creeper.goalChanged(this);
    }
    checkpoint();
  }

  void checkpoint() {
    players.skip(1).forEach(enforceLimits);
    if (goal != null) {
      List<Player> winners = goal.findWinners(this).toList();
      List<CreeperCard> creepers = players
        .expand<CreeperCard>((Player player) => player.creepers)
        .toList();
      winners.removeWhere((Player player) {
        for (CreeperCard card in creepers) {
          if (card.stopsWinning(this, player)) {
            return true;
          }
        }
        return false;
      });
      if (winners.length == 1) {
        GameOver.terminate(_GoalWin(winners.single.ai, goal));
      }
    }
  }

  void enforceLimits(Player player) {
    GameInterface gameForPlayer = Game(
      discardFromHandHandler: (Card card) {
        bool discardValid = false;
        for (NewRuleCard rule in rules) {
          if (rule.shouldDiscardCardFromHand(this, player)) {
            discardValid = true;
          }
        }
        if (!discardValid) {
          GameOver.terminate(RuleViolation('${player.ai.name} tried to discard a card from their hand ($card) during the complying-with-limits phase even though they complied with the limits.', player.ai));
        }
        discardHandCard(player, card);
      },
      discardFromKeepersHandler: (KeeperCard card) {
        bool discardValid = false;
        for (NewRuleCard rule in rules) {
          if (rule.shouldDiscardKeeper(this, player)) {
            discardValid = true;
          }
        }
        if (!discardValid) {
          GameOver.terminate(RuleViolation('${player.ai.name} tried to discard a keeper ($card) during the complying-with-limits phase even though they complied with the limits.', player.ai));
        }
        discardKeeperCard(player, card);
      },
      stateHandler: () => stateForPlayer(player),
    );
    try {
      player.ai.complyWithLimits(gameForPlayer, handLimitRule, keeperLimitRule);
    } catch (e, stack) {
      if (e is GameOver)
        GameOver.terminate(e);
      GameOver.terminate(RuleViolation('${player.ai.name} threw an exception: $e\n$stack', player.ai));
    }
    for (NewRuleCard rule in rules) {
      rule.checkLimits(this, player);
    }
  }

  void discardHandCard(Player player, Card card) {
    if (player.hands.first.remove(card)) {
      log(this, '${player.ai.name} is discarding $card from their hand to comply with hand limits.');
      discard.add(card);
    } else {
      GameOver.terminate(RuleViolation('${player.ai.name} tried to discard card $card which was not in their hand.', player.ai));
    }
  }

  void discardKeeperCard(Player player, KeeperCard card) {
    if (player.keepers.remove(card)) {
      log(this, '${player.ai.name} is discarding $card from their keepers to comply with keeper limits.');
      discard.add(card);
    } else {
      GameOver.terminate(RuleViolation('${player.ai.name} tried to discard keeper $card but it was not one of their playedThisTurn keepers.', player.ai));
    }
  }

  Iterable<T> findRulesOf<T>() {
    return rules.where((NewRuleCard card) => card is T).cast<T>();
  }

  T/*?*/ findRuleOf<T>() {
    List<T> subrules = findRulesOf<T>().toList();
    if (subrules.isEmpty)
      return null;
    return subrules.single;
  }

  int get drawRule => findRuleOf<DrawRule>()/*!*/.value(this);

  int get playRule => findRuleOf<PlayRule>()/*!*/.value(this);

  int get handLimitRule => findRuleOf<HandLimitRule>()?.value(this) ?? -1;

  int get keeperLimitRule => findRuleOf<KeeperLimitRule>()?.value(this) ?? -1;

  bool get canDrawFromBottomOfDiscard => rules.any((NewRuleCard card) => card.canDrawFromBottomOfDiscard(this));

  int interpretNumeral(int number) {
    for (ReinterpretNumeral card in findRulesOf<ReinterpretNumeral>()) {
      if (card.oldNumber == number)
        return card.newNumber;
    }
    return number;
  }

  String toString() => 'table';
}