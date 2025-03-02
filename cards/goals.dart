import 'dart:core' hide print;

import '../ai.dart';
import '../card.dart';
import '../table.dart';
import '../cards/keepers.dart';

abstract class GoalCard extends Card {
  void play(Table table, Player player) {
    table.setGoal(this);
  }

  Iterable<Player> findWinners(Table state);

  Iterable<KeeperCard> get keepers;
}

// CARDS

class SimpleGoal extends GoalCard {
  SimpleGoal(this.name, this.keepers);

  final String name;
  final Set<KeeperCard> keepers;

  Iterable<Player> findWinners(Table state) sync* {
    x: for (Player player in state.players) {
      for (KeeperCard card in keepers) {
        if (!player.keepers.contains(card)) {
          continue x;
        }
      }
      yield player;
    }
  }

  String toString() => name;
}

class ButNotGoal extends GoalCard {
  ButNotGoal(this.name, this.yes, this.no);

  final String name;
  final KeeperCard yes;
  final KeeperCard no;

  Iterable<KeeperCard> get keepers sync* { yield yes; yield no; }

  Iterable<Player> findWinners(Table state) sync* {
    player: for (Player player1 in state.players) {
      if (player1.keepers.contains(yes)) {
        for (Player player2 in state.players) {
          if (player2.keepers.contains(no)) {
            continue player;
          }
        }
        yield player1;
      }
    }
  }

  String toString() => '$name: $yes but not $no';
}

class NOfGoal extends GoalCard {
  NOfGoal(this.name, this.n, this.keepers);

  final String name;
  final int n;
  final Set<KeeperCard> keepers;

  Iterable<Player> findWinners(Table state) sync* {
    players: for (Player player in state.players) {
      int count = 0;
      for (KeeperCard card in keepers) {
        if (player.keepers.contains(card)) {
          count += 1;
          if (count >= n) {
            yield player;
            continue players;
          }
        }
      }
    }
  }

  String toString() => '$name: $n of ${keepers.join(", ")}';
}

class OneOfEachGoal extends GoalCard {
  OneOfEachGoal(this.name, this.keeperSets);

  final String name;
  final List<Set<KeeperCard>> keeperSets;

  Iterable<KeeperCard> get keepers => keeperSets.expand((Iterable<KeeperCard> s) => s);

  Iterable<Player> findWinners(Table state) sync* {
    players: for (Player player in state.players) {
      sets: for (Set<KeeperCard> keepers in keeperSets) {
        for (KeeperCard card in keepers) {
          if (player.keepers.contains(card)) {
            continue sets;
          }
        }
        continue players;
      }
      yield player;
    }
  }

  String toString() {
    return '$name: ${keeperSets.map<String>(
      (Set<KeeperCard> keepers) {
        if (keepers.length == 1)
          return keepers.single.toString();
        if (keepers.length == 2)
          return '(${keepers.join(" or ")})';
        return '(one of ${keepers.join(", ")})';
      }
    ).join(' + ')}';
  }
}

class EatGoal extends GoalCard {
  EatGoal(this.eater, this.foods);

  final KeeperCard eater;
  final Set<KeeperCard> foods;

  Iterable<KeeperCard> get keepers sync* { yield eater; yield* foods; }

  Iterable<Player> findWinners(Table state) sync* {
    players: for (Player player in state.players) {
      if (player.keepers.contains(eater)) {
        for (KeeperCard food in foods) {
          for (Player victim in state.players) {
            if (victim.keepers.contains(food) && victim.canEat(food)) {
              yield player;
              continue players;
            }
          }
        }
      }
    }
  }
  
  String get name => "$this";

  String toString() => '$eater eat ${foods.join(" or ")}';
}