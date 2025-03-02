import 'dart:core' hide print;
import 'dart:math' as math show max;

import '../ai.dart';
import '../card.dart';
import '../table.dart';
import '../cards/creepers.dart';
import '../cards/goals.dart';
import '../cards/keepers.dart';
import '../cards/rules.dart';

abstract class ActionCard extends Card { }

// CARDS

class Extinction extends ActionCard {
  String get name => 'Extinction';
  void play(Table table, Player player) {
    KeeperCard? keeper = player.ai.chooseLivingKeeperForExtinction(Game(stateHandler: () => table.stateForPlayer(player)));
    if (keeper != null && !keeper.isAlive) {
      GameOver.terminate(RuleViolation('$player chose non-living keeper for $name.', player.ai));
    }
    if (keeper == null) {
      table.log(this, '$player chose no card.');
      for (Player otherPlayer in table.players) {
        if (otherPlayer.keepers.any((KeeperCard card) => card.isAlive)) {
          GameOver.terminate(RuleViolation('$player failed to chose keeper for $name (could have chosen ${otherPlayer.keepers.firstWhere((KeeperCard card) => card.isAlive)} from $otherPlayer).', player.ai));
        }
      }
      table.discard.add(this);
      table.checkpoint();
    } else {
      table.log(this, '$player chose $keeper.');
      for (Player player in table.players) {
        if (player.keepers.contains(keeper)) {
          player.keepers.remove(keeper);
          table.checkpoint();
          return; // this and keeper are thrown into the garbage here
        }
      }
      GameOver.terminate(RuleViolation('$player returned invalid card for $name.', player.ai));
    }
  }
}

class LetsDoThatAgain extends ActionCard {
  String get name => 'Let\'s Do That Again';
  void play(Table table, Player player) {
    Card? card = player.ai.chooseCardForLetsDoThatAgain(Game(stateHandler: () => table.stateForPlayer(player)));
    if (card == null) {
      table.log(this, '$player chose no card.');
      if (table.discard.any((Card card) => card is ActionCard || card is NewRuleCard)) {
        GameOver.terminate(RuleViolation('$player failed to chose card for $name.', player.ai));
      }
    } else {
      table.log(this, '$player chose $card.');
      if ((card is! ActionCard && card is! NewRuleCard) || !table.discard.contains(card)) {
        GameOver.terminate(RuleViolation('$player returned invalid card for $name.', player.ai));
      }
      table.discard.remove(card);
      table.log(this, '$player is playing $card from the discard.');
      card.play(table, player);
    }
    table.discard.add(this);
    table.checkpoint();
  }
}

class StealAKeeper extends ActionCard {
  String get name => 'Steal a Keeper';
  void play(Table table, Player player) {
    KeeperCard? keeper = player.ai.chooseKeeperToSteal(Game(stateHandler: () => table.stateForPlayer(player)));
    if (keeper == null) {
      table.log(this, '$player chose no card.');
      for (Player otherPlayer in table.players) {
        if (otherPlayer != player && otherPlayer.keepers.isNotEmpty) {
          GameOver.terminate(RuleViolation('$player failed to choose keeper for $name.', player.ai));
        }
      }
      table.discard.add(this);
      table.checkpoint();
    } else {
      table.log(this, '$player chose $keeper.');
      for (Player otherPlayer in table.players) {
        if (otherPlayer != player && otherPlayer.keepers.contains(keeper)) {
          otherPlayer.keepers.remove(keeper);
          player.keepers.add(keeper);
          table.discard.add(this);
          table.checkpoint();
          return;
        }
      }
      GameOver.terminate(RuleViolation('$player returned invalid card for $name.', player.ai));
    }
  }
}

class EverybodyGetsOne extends ActionCard {
  String get name => 'Everybody Gets One';
  void play(Table table, Player player) {
    Set<Card> drawnCards = <Card>{};
    List<Card?> cards = player.ai.chooseCardsForEverybodyGetsOne(Game(
      drawHandler: (CardSource source) {
        Card card = table.drawCard(player, source);
        if (card is! CreeperCard) {
          drawnCards.add(card);
        }
        return card;
      },
      stateHandler: () => table.stateForPlayer(player),
    ));
    if (drawnCards.length > table.players.length) {
      GameOver.terminate(RuleViolation('$player drew too many cards for $name.', player.ai));
    }
    if (drawnCards.length < table.players.length && (table.deck.isNotEmpty || table.discard.isNotEmpty)) {
      GameOver.terminate(RuleViolation('$player drew too few cards for $name.', player.ai));
    }
    Set<Card> assignedCards = cards.whereType<Card>().toSet();
    if (assignedCards.length < drawnCards.length) {
      GameOver.terminate(RuleViolation('$player did not assign all drawn cards for $name.', player.ai));
    }
    if (assignedCards.length > drawnCards.length) {
      GameOver.terminate(RuleViolation('$player assigned non-drawn cards for $name.', player.ai));
    }
    if (!assignedCards.containsAll(drawnCards)) {
      GameOver.terminate(RuleViolation('$player assigned the wrong cards for $name.', player.ai));
    }
    if (cards.length != table.players.length) {
      GameOver.terminate(RuleViolation('$player did not assign cards to all players for $name.', player.ai));
    }
    for (int index = 0; index < table.players.length; index += 1) {
      if (cards[index] == null) {
        table.log(this, '$player assigned no card to ${table.players[index]}');
      } else {
        table.log(this, '$player assigned ${cards[index]} to ${table.players[index]}');
        table.players[index].hands!.first.add(cards[index]!);
      }
    }
    table.discard.add(this);
    table.checkpoint();
  }
}

class Taxation extends ActionCard {
  String get name => 'Taxation';
  void play(Table table, Player player) {
    for (Player otherPlayer in table.players) {
      if (otherPlayer == player) {
        continue;
      }
      if (otherPlayer.hands!.first.isEmpty) {
        continue;
      }
      Card card = otherPlayer.ai.chooseCardForTaxation(
        player.toPlayerState(false),
        Game(
          stateHandler: () => table.stateForPlayer(otherPlayer),
        ),
      );
      if (!otherPlayer.hands!.first.contains(card)) {
        GameOver.terminate(RuleViolation('$otherPlayer failed: chose invalid card for $name.', player.ai));
      }
      table.log(this, '$otherPlayer pays $card to $player.');
      player.hands!.first.add(card);
    }
    table.discard.add(this);
    table.checkpoint();
  }
}

class ExchangeKeepers extends ActionCard {
  String get name => 'Exchange Keepers';
  void play(Table table, Player player) {
    if (player.keepers.isEmpty) {
      table.discard.add(this);
      table.checkpoint();
      return;
    }
    Iterable<Player> otherPlayers = table.players.where((Player otherPlayer) => otherPlayer != player);
    if (otherPlayers.every((Player otherPlayer) => otherPlayer.keepers.isEmpty)) {
      table.discard.add(this);
      table.checkpoint();
      return;
    }
    ExchangeKeepersResult choices = player.ai.chooseCardsForExchangeKeepers(Game(stateHandler: () => table.stateForPlayer(player)));
    if (!player.keepers.contains(choices.ours)) {
      GameOver.terminate(RuleViolation('$player chose invalid keeper as own card for $name.', player.ai));
    }
    if (!otherPlayers.expand((Player otherPlayer) => otherPlayer.keepers).contains(choices.theirs)) {
      GameOver.terminate(RuleViolation('$player chose invalid keeper as opponent card for $name.', player.ai));
    }
    Player otherPlayer = otherPlayers.where((Player otherPlayer) => otherPlayer.keepers.contains(choices.theirs)).single;
    table.log(this, '$player exchanging their ${choices.ours} keeper for $otherPlayer\'s ${choices.theirs} keeper.');
    player.keepers.remove(choices.ours);
    player.keepers.add(choices.theirs);
    otherPlayer.keepers.remove(choices.theirs);
    otherPlayer.keepers.add(choices.ours);
    table.discard.add(this);
    table.checkpoint();
  }
}

class RulesReset extends ActionCard {
  String get name => 'Rules Reset';
  void play(Table table, Player player) {
    table.discard.addAll(table.rules.where((NewRuleCard card) => !card.isBasicRule));
    table.rules.clear();
    table.rules.addAll(Table.basicRules.toList());
    table.discard.add(this);
    table.checkpoint();
  }
}

class DiscardAndDraw extends ActionCard {
  String get name => 'Discard & Draw';
  void play(Table table, Player player) {
    int oldHandSize = player.hands!.first.length;
    if (oldHandSize > 0) {
      table.discard.addAll(player.hands!.first); // so we must be able to draw the right number of cards
      player.hands!.first.clear();
      table.log(this, '$player discarding and drawing $oldHandSize cards for $name.'); // TODO: plural
      int count = 0;
      player.ai.drawBonusCards(oldHandSize, Game(
        drawHandler: (CardSource source) {
          if (count >= oldHandSize) {
            GameOver.terminate(RuleViolation('${player.ai.name} drew too many cards for $name.', player.ai));
          }
          Card card = table.drawCard(player, source);
          if (card is! CreeperCard) {
            count += 1;
            player.hands!.first.add(card);
          }
          return card;
        },
        stateHandler: () => table.stateForPlayer(player),
      ));
      if (count < oldHandSize) {
        GameOver.terminate(RuleViolation('${player.ai.name} did not draw sufficient cards for $name (drew $count).', player.ai));
      }
    } else {
      table.log(this, '$player has nothing in hand to discard for $name.');
    }
    table.discard.add(this);
    table.checkpoint();
  }
}

class Draw3Play2 extends ActionCard {
  String get name => "Draw 3 Play 2";
  void play(Table table, Player player) {
    int count = 0;
    player.hands!.add({});
    int three = table.interpretNumeral(3);
    player.ai.drawCardsForDNPM(three,
      Game(
        drawHandler: (CardSource source) {
          if (count >= table.interpretNumeral(3)) {
            GameOver.terminate(RuleViolation('${player.ai.name} drew too many cards for $name.', player.ai));
          }
          Card card = table.drawCard(player, source);
          if (card is! CreeperCard) {
            count += 1;
            player.hands!.last.add(card);
          }
          return card;
        },
        stateHandler: () => table.stateForPlayer(player),
      ),
    );
    int two = table.interpretNumeral(2);
    player.ai.playCardsForDNPM(two, Game(
        playFromHandHandler: (Card card) {
          if (player.hands!.last.contains(card)) {
            table.playCard(player, card);
            table.checkpoint();
          } else {
            GameOver.terminate(RuleViolation('${player.ai.name} played card not in $name\'s pseudo-hand.', player.ai));
          }
        },
        stateHandler: () => table.stateForPlayer(player),
      ),
    );
    if (player.hands!.last.length != math.max(0, three - two)) {
      GameOver.terminate(RuleViolation('${player.ai.name} played the wrong amount of cards for $name (m $two n $three played ${three-player.hands!.last.length}).', player.ai));
    }
    table.discard.addAll(player.hands!.last);
    player.hands!.removeLast();
    table.discard.add(this);
    table.checkpoint();
  }
}

class PopulationCrash extends ActionCard {
  String get name => "Population Crash";
  void play(Table table, Player player) {
    // We're interpreting this as: "Draw a card and place it on the discard
    // pile. Repeat until the discarded card is a Goal or the deck has been
    // depleted twice." that way there's no infinite loop...
    if (table.deck.isEmpty && table.discard.isEmpty) {
      table.discard.add(this);
      table.checkpoint();
      return;
    }
    int depleted = 0;
    while (true) {
      if (table.deck.isEmpty) {
        depleted += 1;
        if (depleted >= 2) {
          table.log(this, 'Could not find a goal despite depleting the deck (twice).');
          table.discard.add(this);
          table.checkpoint();
          return;
        }
      }
      Card card = table.drawCard(player, CardSource.deck);
      if (card is! CreeperCard) {
        table.discard.add(card);
        if (card is GoalCard) {
          table.log(this, 'Discarding any and all keepers shown on $card if in play.');
          keepers: for (KeeperCard keeper in card.keepers) {
            for (Player player in table.players) {
              if (player.keepers.contains(keeper)) {
                table.log(this, 'Discarding $keeper from $player\'s keepers.');
                table.discard.add(keeper);
                player.keepers.remove(keeper);
                continue keepers;
              }
            }
            table.log(this, 'Could not find $keeper.');
          }
          break;
        }
      }
    }
    table.discard.add(this);
    table.checkpoint();
  }
}

class Pollution extends ActionCard {
  String get name => "Pollution";
  void play(Table table, Player player) {
    int count = 0;
    for (Player player in table.players) {
      count += _tryDiscard(table, kAir, player);
      count += _tryDiscard(table, kWater, player);
      count += _tryDiscard(table, kDirt, player);
    }
    table.log(this, 'Discarded $count total cards.');
    table.discard.add(this);
    table.checkpoint();
  }

  int _tryDiscard(Table table, KeeperCard keeper, Player player) {
    if (player.keepers.contains(keeper)) {
      table.log(this, 'Discarding $keeper from $player\'s keepers.');
      table.discard.add(keeper);
      player.keepers.remove(keeper);
      return 1;
    }
    return 0;
  }
}

class ShareTheWealth extends ActionCard {
  String get name => "Share the Wealth";
  void play(Table table, Player player) {
    List<KeeperCard> keepers = table.players.expand((x) => x.keepers).toList()..shuffle(table.random);
    table.players.forEach((x) => x.keepers.clear());
    for (int x = 0; keepers.isNotEmpty; x = (x + 1) % table.players.length) {
      table.players[x].keepers.add(keepers.last);
      keepers.removeLast();
    }
    table.log(this, "New keepers: ${table.players.map((x) => "${x.ai.name}: ${x.keepers}")}");
    table.discard.add(this);
    table.checkpoint();
  }
}

class Scavenger extends ActionCard {
  String get name => "Scavenger";
  void play(Table table, Player player) {
    int indexOfKeeper = table.discard.lastIndexWhere((x) => x is KeeperCard);
    if (indexOfKeeper != -1) {
      KeeperCard? keeper = table.discard[indexOfKeeper] as KeeperCard;
      table.discard.removeAt(indexOfKeeper);
      table.log(this, "$player playing $keeper");
      keeper.play(table, player);
    } else {
      table.log(this, "There is no keeper in discard, doing nothing");
    }
    table.discard.add(this);
    table.checkpoint();
  }
}

class TradeHands extends ActionCard {
  String get name => 'Trade Hands';
  void play(Table table, Player player) {
    int otherPlayerIndex = player.ai.tradeHands(Game(
      stateHandler: () => table.stateForPlayer(player),
    ));
    if (otherPlayerIndex <= 0 || otherPlayerIndex >= table.players.length) {
      GameOver.terminate(RuleViolation('${player.ai.name} identified invalid player ($otherPlayerIndex).', player.ai));
    }
    Player otherPlayer = table.players[otherPlayerIndex];
    table.log(this, '${player.ai.name} trading hands with ${otherPlayer.ai.name}.');
    if (player.hands!.first.isEmpty && otherPlayer.hands!.first.isNotEmpty) {
      table.log(this, '${player.ai.name} got something for nothing.');
    }
    Set<Card> oldPlayerHand = player.hands!.removeAt(0);
    Set<Card> oldOtherPlayerHand = otherPlayer.hands!.removeAt(0);
    player.hands!.insert(0, oldOtherPlayerHand);
    otherPlayer.hands!.insert(0, oldPlayerHand);
    table.discard.add(this);
    table.checkpoint();
  }
}
