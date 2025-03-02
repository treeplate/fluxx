
import '../ai.dart';

class HixieAI extends AI {
  HixieAI() : super('Hixie');

  void playCard(GameInterface game) {
    GameState state = game.state;
    game.playFromHand(state.thisPlayer.hands!.last.last);
  }
}