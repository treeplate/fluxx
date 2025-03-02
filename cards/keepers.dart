import 'dart:core' hide print;

import '../card.dart';
import '../table.dart';

class KeeperCard extends Card {
  KeeperCard(this.name, { this.isAlive = false });

  final String name;
  final bool isAlive;

  bool preventsEating(KeeperCard food) => false;

  void play(Table table, Player player) {
    player.keepers.add(this);
    table.checkpoint();
  }
}

// CARDS

final KeeperCard kWater = KeeperCard("Water");
final KeeperCard kDirt = KeeperCard("Dirt");
final KeeperCard kSunshine = KeeperCard("Sunshine");
final KeeperCard kAir = KeeperCard("Air");
final KeeperCard kFlowers = KeeperCard("Flowers", isAlive: true);
final KeeperCard kBirds = KeeperCard("Birds", isAlive: true);
final KeeperCard kSpiders = KeeperCard("Spiders", isAlive: true);
final KeeperCard kLeaves = KeeperCard("Leaves", isAlive: true);
final KeeperCard kTrees = KeeperCard("Trees", isAlive: true);
final KeeperCard kInsects = KeeperCard("Insects", isAlive: true);
final KeeperCard kMushrooms = KeeperCard("Mushrooms", isAlive: true);
final KeeperCard kWorms = KeeperCard("Worms", isAlive: true);
final KeeperCard kBears = KeeperCard("Bears", isAlive: true);
final KeeperCard kRabbits = KeeperCard("Rabbits", isAlive: true);
final KeeperCard kSnakes = KeeperCard("Snakes", isAlive: true);
final KeeperCard kFish = KeeperCard("Fish", isAlive: true);
final KeeperCard kMice = KeeperCard("Mice", isAlive: true);
final KeeperCard kTadpoles = KeeperCard("Tadpoles", isAlive: true);
final KeeperCard kFrogs = KeeperCard("Frogs", isAlive: true);
final KeeperCard kSeeds = KeeperCard("Seeds", isAlive: true);

class Poison extends KeeperCard {
  Poison() : super("Poison");
  bool preventsEating(KeeperCard food) => true;
}

final KeeperCard kPoison = Poison();