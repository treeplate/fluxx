import 'dart:core' hide print;

import '../ai.dart';
import '../card.dart';
import '../table.dart';
import '../cards/creepers.dart';

abstract class NewRuleCard extends Card {
  NewRuleCard();

  bool get isBasicRule => false;

  void play(Table table, Player player) {
    NewRuleCard? oldCard = findOldRule(table);
    replaceCard(table, oldCard);
    table.checkpoint();
  }

  NewRuleCard? findOldRule(Table table) {
    List<NewRuleCard> cards = table.rules.where((NewRuleCard card) => card.runtimeType == this.runtimeType).toList();
    if (cards.length > 1) {
      GameOver.terminate(StateError('Rules had multiple ${this.runtimeType} cards: $cards'));
    }
    if (cards.isEmpty)
      return null;
    return cards.single;
  }

  void replaceCard(Table table, covariant NewRuleCard? oldRule) {
    if (oldRule != null) {
      table.rules.remove(oldRule);
      if (!oldRule.isBasicRule) {
        table.discard.add(oldRule);
      }
    }
    table.rules.add(this);
  }

  void turnStart(Table table) {}
  bool canDrawFromBottomOfDiscard(Table table) => false;
  bool canDraw(Table table) => true;
  bool canPlay(Table table) => true;
  void turnEnd(Table table) {}
  bool shouldDiscardCardFromHand(Table state, Player player) => false;
  bool shouldDiscardKeeper(Table state, Player player) => false;
  void checkLimits(Table state, Player player) {}
}

// CARDS

class DrawRule extends NewRuleCard {
  DrawRule(this._n);

  final int _n;

  int value(Table table) => table.interpretNumeral(_n);

  bool get isBasicRule => _n == 1;

  String get name => "Draw $_n";

  bool canDraw(Table table) {
    return table.drawnThisTurn! < value(table);
  }

  bool canPlay(Table table) {
    return table.drawnThisTurn! >= value(table) || (table.deck.isEmpty && table.discard.isEmpty);
  }

  void turnEnd(Table table) {
    if ((table.drawnThisTurn! < value(table)) && (!(table.deck.isEmpty && table.discard.isEmpty))) {
      GameOver.terminate(RuleViolation('${table.players.first.ai.name} did not draw sufficient cards on their turn (drew ${table.drawnThisTurn}, needed to draw ${value(table)}).', table.players.first.ai));
    }
  }
}

class PlayRule extends NewRuleCard {
  PlayRule(this._n);
  PlayRule.all() : _n = 0;
  
  final int _n;

  bool get all => _n == 0;

  int value(Table table) => all ? 0 : table.interpretNumeral(_n);

  bool get isBasicRule => _n == 1;

  String get name => "Play ${all ? "All" : _n}";

  bool canPlay(Table table) {
    return all || table.playedThisTurn! < value(table);
  }

  void turnEnd(Table table) {
    if ((all || table.playedThisTurn! < value(table)) && (table.players.first.hands!.first.isNotEmpty)) {
      GameOver.terminate(RuleViolation('${table.players.first.ai.name} did not play sufficient cards on their turn (played ${table.playedThisTurn}, needed to play ${all ? "all" : value(table)}).', table.players.first.ai));
    }
  }
}

class HandLimitRule extends NewRuleCard {
  HandLimitRule(this._n);
  
  final int _n;

  int value(Table table) => table.interpretNumeral(_n);

  String get name => "Hand Limit $_n";

  bool shouldDiscardCardFromHand(Table table, Player thisPlayer) => thisPlayer.hands!.first.length > value(table);

  void checkLimits(Table table, Player thisPlayer) {
    if (thisPlayer.hands!.single.length > value(table)) {
      GameOver.terminate(RuleViolation('${thisPlayer.ai.name} did not correctly discard cards during the complying-with-limits phase (hand size ${thisPlayer.hands!.single.length}, hand limit ${value(table)}).', thisPlayer.ai));
    }
  }
}

class KeeperLimitRule extends NewRuleCard {
  KeeperLimitRule(this._n);
  
  final int _n;

  int value(Table table) => table.interpretNumeral(_n);

  String get name => "Keeper Limit $_n";

  bool shouldDiscardKeeper(Table table, Player thisPlayer) => thisPlayer.keepers.length > value(table);

  void checkLimits(Table table, Player thisPlayer) {
    if (thisPlayer.keepers.length > value(table)) {
      GameOver.terminate(RuleViolation('${thisPlayer.ai.name} did not correctly discard keepers during the complying-with-limits phase (keepers ${thisPlayer.keepers.length}, keeper limit ${value(table)}).', thisPlayer.ai));
    }
  }
}

class NoHandBonus extends NewRuleCard {
  NoHandBonus();
  String get name => "No-Hand Bonus";

  void turnStart(Table table) {
    int n = table.interpretNumeral(3);
    final Player player = table.players.first;
    if (player.hands!.single.isEmpty) {
      table.log(this, '$player drawing $n cards for $name.'); // TODO: plural
      int count = 0;
      player.ai.drawBonusCards(n, Game(
        drawHandler: (CardSource source) {
          if (count >= n) {
            GameOver.terminate(RuleViolation('${player.ai.name} drew too many cards for $name.', player.ai));
          }
          Card card = table.drawCard(player, source);
          if (card is! CreeperCard) {
            count += 1;
            player.hands!.single.add(card);
          }
          table.checkpoint();
          return card;
        },
        stateHandler: () => table.stateForPlayer(player),
      ));
      if (count < n && (table.deck.isNotEmpty || table.discard.isNotEmpty)) {
        GameOver.terminate(RuleViolation('${player.ai.name} did not draw sufficient cards for $name (drew $count).', player.ai));
      }
    }
  }
}

class ReinterpretNumeral extends NewRuleCard {
  ReinterpretNumeral(this.name, this.oldNumber, this.newNumber);

  final String name;
  final int oldNumber;
  final int newNumber;

  NewRuleCard? findOldRule(Table table) {
    List<NewRuleCard> cards = table.findRulesOf<ReinterpretNumeral>().where((ReinterpretNumeral card) => card.oldNumber == oldNumber).toList();
    if (cards.length > 1) {
      GameOver.terminate(StateError('Rules had multiple ReinterpretNumeral($oldNumber) cards: $cards'));
    }
    if (cards.isEmpty)
      return null;
    return cards.single;
  }  
}

class Composting extends NewRuleCard {
  Composting();

  String get name => 'Composting';

  bool canDrawFromBottomOfDiscard(Table table) => true;
}