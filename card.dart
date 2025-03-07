import 'dart:core' hide print;

import 'table.dart';

abstract class Card {
  String get name;

  void play(Table table, Player player);

  String toString() => name;
}