import 'dart:core' hide print;

import '../ai.dart';
import '../card.dart';
import '../table.dart';

abstract class CreeperCard extends Card {
  bool stopsWinning(Table table, Player player);

  void play(Table table, Player player) {
    GameOver.terminate(RuleViolation('${player.ai.name} cannot play $this, it\'s a creeper.', player.ai));
  }

  void goalChanged(Table table) { }
}

// CARDS

class RadioactivePotato extends CreeperCard {
  String get name => 'Radioactive Potato';

  bool stopsWinning(Table table, Player player) {
    return player.creepers.contains(this);
  }

  void goalChanged(Table table) {
    Player currentPlayer = table.players.firstWhere((Player player) => player.creepers.contains(this));
    int targetPlayerIndex = (table.players.indexOf(currentPlayer) - 1) % (table.players.length);
    currentPlayer.creepers.remove(this);
    Player nextPlayer = table.players[targetPlayerIndex];
    nextPlayer.creepers.add(this);
    table.log(this, '$name moved from ${currentPlayer.ai.name} to ${nextPlayer.ai.name}.');
  }
}