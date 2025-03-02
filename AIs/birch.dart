library birch;

import '../ai.dart';
import '../card.dart';
import '../cards/actions.dart';
import '../cards/goals.dart';
import '../cards/keepers.dart';
import '../cards/rules.dart';

class Birch extends AI {
  Birch(String name) : super(name);

  void complyWithLimits(GameInterface game, int handLimit, int keeperLimit) {
    List<Card> hand = game.state.thisPlayer.hands!.first.toList();
    while (hand.length > handLimit && handLimit != -1) {
      hand.sort(compareCards(game));
      game.discardFromHand(hand.first);
      hand = game.state.thisPlayer.hands!.first.toList();
    }
    List<KeeperCard> keepers = game.state.thisPlayer.keepers.toList();
    while (keepers.length > keeperLimit && keeperLimit != -1) {
      keepers.sort(compareCards(game));
      game.discardFromKeepers(keepers.last);
      keepers = game.state.thisPlayer.keepers.toList();
    }
  }

  int Function(Card, Card) compareCards(GameInterface game) => (
    Card a,
    Card b,
  ) {
    return (scoreCard(b, game) - scoreCard(a, game));
  };

  int scoreCard(Card card, GameInterface game) {
    if (card is KeeperCard) {
      return scoreGoal(game.state.goal, game, card) -
          scoreGoal(
            game.state.goal,
            game,
            null,
          ); // TODO: score under goals a) in hand b) on table
    }
    if (card is GoalCard) {
      return scoreGoal(card, game, null) -
          scoreGoal(game.state.goal, game, null);
    }
    if (card is NewRuleCard) {
      return -1; // TODO: value card
    }
    if (card is Extinction) {
      return 10;
    }
    if (card is LetsDoThatAgain) {
      return 10;
    }
    if (card is StealAKeeper) {
      return 10;
    }
    if (card is EverybodyGetsOne) {
      return 10;
    }
    return 1000;
  }

  int scoreGoal(GoalCard? goal, GameInterface game, KeeperCard? newKeep) {
    if (goal == null) {
      return 0;
    }
    int runningTotal = 0;
    if (goal is EatGoal) {
      for (KeeperCard keeper in goal.foods) {
        if (game.state.thisPlayer.hands!.contains(keeper) &&
            newKeep != keeper) {
          runningTotal -= 1;
        }
        if (game.state.thisPlayer.keepers.contains(keeper) ||
            newKeep == keeper) {
          runningTotal -= 2;
        }
        if (game.state.players.skip(1).any((x) => x.keepers.contains(keeper))) {
          runningTotal += 2;
        }
      }
      if (game.state.thisPlayer.hands!.contains(goal.eater) &&
          newKeep != goal.eater) {
        runningTotal += 1;
      }
      if (game.state.thisPlayer.keepers.contains(goal.eater) ||
          newKeep == goal.eater) {
        runningTotal += 2;
      }
      return runningTotal;
    }
    if (goal is ButNotGoal) {
      if (game.state.thisPlayer.hands!.expand((x) => x).contains(goal.yes) &&
          newKeep != goal.yes) {
        runningTotal += 1;
      }
      if (game.state.thisPlayer.keepers.contains(goal.yes) ||
          newKeep == goal.yes) {
        runningTotal += 2;
      }
      if (game.state.players.skip(1).any((x) => x.keepers.contains(goal.yes))) {
        runningTotal -= 2;
      }
      return runningTotal;
    }
    if (goal is OneOfEachGoal) {
      return -10;
      /*
      for(Set<KeeperCard> keeps in goal.keeperSets) {
        for (KeeperCard keeper in keeps) {
          if (game.state.thisPlayer.hands!.expand((x) => x).contains(keeper) && newKeep != keeper) {
            runningTotal += 1;
          }
          if (game.state.thisPlayer.keepers.contains(keeper) || newKeep == keeper) {
            runningTotal += 2;
          }
          if (game.state.players.skip(1).any((x) => x.keepers.contains(keeper))) {
            runningTotal -= 2;
          }
        }
      }
      return runningTotal;
      */
    }
    if (goal is! SimpleGoal && goal is! NOfGoal) {
      throw UnimplementedError("type of goal called a '${goal.runtimeType}'");
    }
    // TODO: 3-keeper goal where we have 1 should be scored lower than a 2-keeper goal where we have 1
    for (KeeperCard keeper in (goal as dynamic).keepers) {
      if (game.state.thisPlayer.hands!.expand((x) => x).contains(keeper) &&
          newKeep != keeper) {
        runningTotal += 1;
      }
      if (game.state.thisPlayer.keepers.contains(keeper) || newKeep == keeper) {
        runningTotal += 2;
      }
      if (game.state.players.skip(1).any((x) => x.keepers.contains(keeper))) {
        runningTotal -= 2;
      }
    }
    return runningTotal;
  }

  void play(GameInterface game) {
    while (game.state.drawnThisTurn < game.state.drawRule &&
        !game.state.deckEmpty) {
      game.draw();
    }
    List<Card> hand = game.state.thisPlayer.hands!.first.toList();
    while (game.state.playedThisTurn < game.state.playRule ||
        game.state.playRule == 0) {
      if (hand.isEmpty) return;
      hand.sort(compareCards(game));
      game.playFromHand(hand.first);
      while (game.state.drawnThisTurn < game.state.drawRule &&
          !game.state.deckEmpty) {
        game.draw();
      }
      hand = game.state.thisPlayer.hands!.first.toList();
    }
  }
}
