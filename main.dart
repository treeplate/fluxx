import 'dart:math' as math show Random;
import 'dart:io';

import 'table.dart';
import 'ai.dart';
import 'card.dart';
import 'AIs/birch.dart';
import 'AIs/random.dart';
import 'AIs/anonymous_AI.dart';
import 'cards/actions.dart';
import 'cards/creepers.dart';
import 'cards/goals.dart';
import 'cards/keepers.dart';
import 'cards/rules.dart';

final List<Card> ecoFluxx = [
  kFlowers, kWater, kBirds, kSpiders, kLeaves, kTrees,
  kDirt, kWorms, kAir, kSunshine, kBears, kRabbits, kSnakes, kFish, kMice, kFrogs, kTadpoles,
  kSeeds, kMushrooms, kInsects,
  kPoison,
  DrawRule(2), DrawRule(3), DrawRule(4), DrawRule(5),
  PlayRule.all(), PlayRule(2), PlayRule(3), PlayRule(4),
  HandLimitRule(0), HandLimitRule(1), HandLimitRule(2), HandLimitRule(3), HandLimitRule(4),
  KeeperLimitRule(1), KeeperLimitRule(2), KeeperLimitRule(3), KeeperLimitRule(4),
  NoHandBonus(),
  SimpleGoal("Mud", {kDirt, kWater}),
  SimpleGoal("Trees Clean The Air", {kAir, kTrees}),
  SimpleGoal("Basking", {kSunshine, kSnakes}),
  SimpleGoal("Photosynthesis", {kLeaves, kSunshine}),
  SimpleGoal("Night Music", {kFrogs, kInsects}),
  SimpleGoal("Earthworms", {kDirt, kWorms}),
  SimpleGoal("Decay", {kMushrooms, kWorms}),
  SimpleGoal("Clouds", {kAir, kWater}),
  SimpleGoal("Rainbows", {kWater, kSunshine}),
  SimpleGoal("Metamorphosis", {kTadpoles, kFrogs}),
  SimpleGoal("Mighty Oaks from Tiny Acorns Grow", {kTrees, kSeeds}),
  EatGoal(kMice, {kSeeds}),
  EatGoal(kInsects, {kLeaves, kMushrooms}),
  EatGoal(kBears, {kFish}),
  EatGoal(kSpiders, {kInsects}),
  EatGoal(kBirds, {kInsects, kWorms, kSeeds}),
  EatGoal(kRabbits, {kLeaves}),
  EatGoal(kSnakes, {kMice}),
  EatGoal(kFish, {kWorms}),
  NOfGoal('Invertebrates', 2, {kWorms, kSpiders, kInsects}),
  NOfGoal('Mammals', 2, {kBears, kRabbits, kMice}),
  OneOfEachGoal('Pollinators', [{kFlowers}, {kBirds, kInsects, kAir}]),
  OneOfEachGoal('Herpetology', [{kSnakes}, {kTadpoles, kFrogs}]),
  ButNotGoal('Ferns', kLeaves, kFlowers),
  ButNotGoal('Deciduous Trees in Winter', kTrees, kLeaves),
  Extinction(),
  LetsDoThatAgain(), LetsDoThatAgain(),
  StealAKeeper(),
  EverybodyGetsOne(),
  Taxation(),
  ReinterpretNumeral('One, Two, Five!', 3, 5),
  Composting(), Composting(),
  RadioactivePotato(),
  ExchangeKeepers(),
  RulesReset(),
  DiscardAndDraw(),
  Draw3Play2(),
  PopulationCrash(),
  Pollution(),
  ShareTheWealth(),
  Scavenger(),
  TradeHands(),
];

final List<Card> testDeck = [
  kWater, kDirt, kAir,
  kFlowers, kBirds, kSpiders, kLeaves, kTrees,
  kWorms, kSunshine, kBears, kRabbits, kSnakes,
  kFish, kMice, kFrogs, kTadpoles, kSeeds, kMushrooms, kInsects,
  TradeHands(),
  SimpleGoal("Mud", {kDirt, kWater}),
  SimpleGoal("Trees Clean The Air", {kAir, kTrees}),
  SimpleGoal("Basking", {kSunshine, kSnakes}),
  SimpleGoal("Photosynthesis", {kLeaves, kSunshine}),
  SimpleGoal("Night Music", {kFrogs, kInsects}),
  SimpleGoal("Earthworms", {kDirt, kWorms}),
  SimpleGoal("Decay", {kMushrooms, kWorms}),
  SimpleGoal("Clouds", {kAir, kWater}),
  SimpleGoal("Rainbows", {kWater, kSunshine}),
  SimpleGoal("Metamorphosis", {kTadpoles, kFrogs}),
  SimpleGoal("Mighty Oaks from Tiny Acorns Grow", {kTrees, kSeeds}),
  EatGoal(kMice, {kSeeds}),
  EatGoal(kInsects, {kLeaves, kMushrooms}),
  EatGoal(kBears, {kFish}),
  EatGoal(kSpiders, {kInsects}),
  EatGoal(kBirds, {kInsects, kWorms, kSeeds}),
  EatGoal(kRabbits, {kLeaves}),
  EatGoal(kSnakes, {kMice}),
  EatGoal(kFish, {kWorms}),
  NOfGoal('Invertebrates', 2, {kWorms, kSpiders, kInsects}),
  NOfGoal('Mammals', 2, {kBears, kRabbits, kMice}),
  OneOfEachGoal('Pollinators', [{kFlowers}, {kBirds, kInsects, kAir}]),
  OneOfEachGoal('Herpetology', [{kSnakes}, {kTadpoles, kFrogs}]),
  ButNotGoal('Ferns', kLeaves, kFlowers),
  ButNotGoal('Deciduous Trees in Winter', kTrees, kLeaves),
];

void main(List<String> args) {
	Table.run(
    math.Random(args.isEmpty ? 0 : int.parse(args.single)),
    deck: ecoFluxx,
    //deck: testDeck,
    players: [
      AI('First Card Alice'),
      AI('First Card Bob'),
      RandomAI('Charlie', math.Random(0)),
      DaddyAI(),
      Birch('Eli (Birch)'),
    ],
    showGame: args.isEmpty,
  );
}