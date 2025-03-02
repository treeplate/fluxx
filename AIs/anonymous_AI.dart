import 'dart:math' as math;

import '../ai.dart';
import '../card.dart';

class AnonymousAI1 extends AI {
  AnonymousAI1() : super('Anonymous1');

  void playCard(GameInterface game) {
    GameState state = game.state;
    game.playFromHand(state.thisPlayer.hands.last.last);
  }
}