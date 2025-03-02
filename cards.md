
# Cards

## Keepers (done)

- Flowers

- Water

- Birds

- Spiders

- Leaves

- Trees

- Insects

- Dirt

- Mushrooms

- Worms

- Bears

- Sunshine

- Rabbits

- Air

- Snakes

- Poison

  protects your other Keepers from being eaten once in play

- Fish

- Mice

- Tadpoles

- Frogs

- Seeds


## Goals (done)

### Simple Goals
- Photosynthesis (Sunshine and Leaves in the player's play area) (done)
- Mud (Dirt and Water in the player's play area) (done)
- Trees Clean the Air (Trees and Air in the player's play area) (done)
- Basking (Sunshine and Snakes in the player's play area) (done)
- Night Music (Insects and Frogs in the player's play area) (done)
- Earthworms (Dirt and Worms in the player's play area) (done)
- Decay (Mushrooms and Worms in the player's play area) (done)
- Clouds (Air and Water in the player's play area) (done)
- Rainbows (Sunshine and Water in the player's play area) (done)
- Metamorphsis (Tadpoles and Frogs in the player's play area) (done)
- Mighty Oaks from Tiny Acorns Grow (Seeds and Trees in the player's play area) (done)

### Eat Goals
- Mice Eat Seeds
- Insects Eat Leaves or Mushrooms
- Bears Eat Fish
- Frogs Eat Insects
- Spiders Eat Insects
- Birds Eat Insects or Worms or Seeds
- Rabbits Eat Leaves
- Snakes Eat Mice
- Fish Eat Worms

### Other Goals

- Invertabretes (2 of Worms, Spiders, Insects in the player's play area)
- Mammals (2 of Bears, Rabbits, Mice in the player's play area)

- Pollinators (Flowers + (one of Birds, Insects, Air) in the player's play area)
- Herpetology (Snakes + (Tadpoles or Frogs) in the player's play area)

- Ferns (Leaves in the player's play area, no Flowers in play)
- Deciduous Trees in Winter (Trees in the player's play area, no Leaves in play)

## Creepers (done)
- Radioactive Potato 
You cannot win if you have this card. Whenever the Goal changes, move this card in the counter-turn direction.

## Rules

### Draw Rules (done)
- 5
- 2
- 3
- 4
### Play Rules (done)
- 4
- All
- 2
- 3
### Hand Limit Rules (done)
- 1
- 4
- 3
- 2
- 0
### Keeper Limit Rules (done)
- 1
- 4
- 3
- 2
### Others
- *Borders Bonus*
If in a public place, and a stranger inquires about the game, all players draw a card.
- *1 2 5*
All 3s on cards (apart from this card) are treated as 5s (done)
- *Composting (x2)*
You can also draw from the bottom of the discard pile. (done)
- *No-Hand Bonus* 
If you have no cards at the start of your turn draw 3 cards. (done)
## Action Cards
- *Rules Reset* Discard all New Rule cards in play.
- *Discard & Draw* Discard your whole hand (of N cards), and then draw N cards.
- *Draw 3 Play 2* Draw three cards, discard 1, and play the rest of them. (This counts as 1 play total)
  - This can be implemented as a nested call to `AI.play()` with a slightly different `GameInterface` instance
- *Population Crash* Discard cards from the top of the deck until it's a goal. Discard all Keepers shown on the card if they are in play.
- *Pollution* Discard Air, Water, and Dirt if they are in play.
- *Let's Do That Again (x2)* Take any Action or New Rule card in the discard pile and play it. (Done)
- *Trash a Keeper* Take a Keeper from the play area and put it in the discard.
  - Maybe actions like this invoke `AI.handleCard()` which takes the game state (not game interface) and the card, and AIs just have to know all the cards that need special logic, and `AI.handleCard` has to return an object of a type specific to each card that describes the decision? in this case a Keeper, I guess. (But see *Mass Migration* below, maybe we should just have a method per special card.)
- *Extinction* Pick a Keeper in play that represents something living, and garbage-collect it along with this card. (done)
- *Share the Wealth* Shuffle the Keepers in play, and deal them the to the players (starting with you) 
- *Trade Hands* Trade hands with an opponent.
  - Similar to *Trash a Keeper*, except this time it has to identify an opponent.
- *Scavenger* Play the topmost Keeper of the discard pile.
- *Use What You Take* Play a random card from another player's hand.
  - Similar to *Trash a Keeper*, except this time it has to identify an opponent.
- *Trash a New Rule* Discard a New Rule card in play.
  - Similar to *Trash a Keeper*, except this time it has to identify a rule.
- *Mass Migration* Choose a direction. All players choose a keeper from their play area and pass it to that direction.
  - Similar to *Trash a Keeper*, except this time it has to identify a keeper, and everyone gets called even though it's not their turn. Except the current player also has to identify a direction, so maybe it's not the card that it receives, but some special type that identifies the message? OR maybe we just have a method per special card and this one has two methods.
- *Taxation* Each player must give one card from their hand to you. (done)
- *Everybody Gets 1* Draw 1 card for each player, and choose which player gets which card. (done)
- *Steal a Keeper* Play a Keeper from someone else's play area. (done)
- *Exchange Keepers* Trade a Keeper with an opponent's Keeper.
  - Similar to *Trash a Keeper*, but giving two keepers.