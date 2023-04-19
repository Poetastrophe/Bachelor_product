const std = @import("std");
const combination_helpers = @import("combination_helpers.zig");
const Hanabi_game = @import("./../../hanabi_game_with_AIs/src/hanabi_board_game.zig");
const CardWithHints = Hanabi_game.CardWithHints;
const CurrentPlayerView = Hanabi_game.CurrentPlayerView;
const CardSet = combination_helpers.CardSet;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Card = Hanabi_game.Card;
const Game = Hanabi_game.Game;
const Player = Hanabi_game.Player;
const Color = Hanabi_game.Color;
const Value = Hanabi_game.Value;
const PermutationIterator = @import("PermutationIterator.zig");

//A world simply represent what is in the players hands.
// Could possibly reduce it to a single hand since the way I represent it, it is obvious which hand that is fixed and which is not hmmm.
const World = struct {
    const Self = @This();
    hand: CardSet,
    pub fn toCardList(self: Self, allocator: Allocator) ArrayList(Card) {
        return self.hand.toCardList(allocator);
    }
};
//How to represent hints?
//Hints is something given to a card, so easiest thing is to use hand
//representation from hanabi game and let that be the hint

//From POV of a specific agent \__shrug_/
const KripkeStructure = struct {
    const Self = @This();
    //Agent A: POV agent
    //Agent B: imagined knowledge for player B from the POV of A.
    //Encoding is worlds[specific_hand_of_pov_agent][agent_number][possible_hand_of_agent_B]
    //So from A POV there are of course worlds[1][A][0]. Will be the fixed card of worlds[1] because agent A can only imagine that A knows fixed world[1] given the fixed scenario of the hand.
    worlds: ArrayList(ArrayList(ArrayList(World))),
    // It should init based on the cards of the players and on the discard pile...
    pub fn init(allocator: Allocator, initial_deck: CardSet, hanabi_pile: CardSet, discard_pile: CardSet, other_players: []CardSet, pov_player_handsize: u64, pov_player_index: usize) Self {
        // _ = allocator;
        var hand_pool = initial_deck.setDifference(hanabi_pile).setDifference(discard_pile);
        for (other_players) |playerCardSet| {
            hand_pool = hand_pool.setDifference(playerCardSet);
        }
        const pov_player_possibilities = combination_helpers.distinct_combinations_assuming_encoding(hand_pool.card_encoding, pov_player_handsize, allocator);
        //TODO: I am throwing a way a lot of memory in the end: Use arena allocator.
        defer pov_player_possibilities.deinit();
        var result: ArrayList(ArrayList(ArrayList(World))) = ArrayList(ArrayList(ArrayList(World))).init(allocator);

        for (pov_player_possibilities.items) |encoded_hand_for_pov_player| {
            var player_B: u64 = 0;
            const number_of_players: u64 = other_players.len + 1;
            var tmpLevel2: ArrayList(ArrayList(World)) = ArrayList(ArrayList(World)).initCapacity(allocator, number_of_players) catch unreachable;
            while (player_B < number_of_players) : (player_B += 1) {
                var tmpLevel3: ArrayList(World) = ArrayList(World).init(allocator);
                if (pov_player_index == player_B) {
                    tmpLevel3.append(World{ .hand = CardSet{ .card_encoding = encoded_hand_for_pov_player } }) catch unreachable;
                } else {
                    var hand_pool_for_ith_player = initial_deck.setDifference(hanabi_pile).setDifference(discard_pile);
                    hand_pool_for_ith_player = hand_pool_for_ith_player.setDifference(CardSet{ .card_encoding = encoded_hand_for_pov_player });
                    var p: usize = 0;

                    while (p < number_of_players) : (p += 1) {
                        if (p == pov_player_index or p == player_B) {
                            continue;
                        }
                        var current_player = other_players[correctedIndex(pov_player_index, p)];
                        hand_pool_for_ith_player = hand_pool_for_ith_player.setDifference(current_player);
                    }
                    // std.debug.print("other_player[1]:{any}\n", .{other_players[1].card_encoding});
                    // std.debug.print("i:{},povplayerpos:{any}, hand_pool_for_ith_player:{any}\n", .{ i, encoded_hand_for_pov_player, hand_pool_for_ith_player });

                    // FIX for handsize
                    const other_player_possibilities = combination_helpers.distinct_combinations_assuming_encoding(hand_pool_for_ith_player.card_encoding, other_players[correctedIndex(pov_player_index, player_B)].getSize(), allocator);
                    defer other_player_possibilities.deinit();
                    for (other_player_possibilities.items) |other_player_hand_encoding| {
                        tmpLevel3.append(World{ .hand = CardSet{ .card_encoding = other_player_hand_encoding } }) catch unreachable;
                    }
                }
                tmpLevel2.append(tmpLevel3) catch unreachable;
            }
            result.append(tmpLevel2) catch unreachable;
        }
        return KripkeStructure{ .worlds = result };
    }

    fn correctedIndex(pov_player_index: usize, player_B: usize) usize {
        if (pov_player_index > player_B) {
            return player_B;
        } else {
            return player_B - 1;
        }
    }

    pub fn remove_worlds_based_on_hints(self: *Self, players: []Player, pov_player_index: usize) void {
        // red1, red, blue, green, unknown
        // r1, ru, bu, gu, uu
        // pool = {red1,red2,blue1,green1}
        // red red blue green
        // Cases
        // Concrete cards that must be present
        // Just remove those
        // Vague color must be present
        // Remove those
        // Vague suit must be present
        // Remove those
        // And if any steps are unable to remove the specified card, then that state is invalid

        // }
        // _ = players;
        // _ = pov_player_index;
        // 0. Remove pov player states
        var pov_player_hand_raw = players[pov_player_index].hand;

        // 200 should be more than enough for representing 2 hands
        var buffer: [200]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buffer);
        const allocator = fba.allocator();

        var pov_player_hinthand = ArrayList(Card).init(allocator);
        defer pov_player_hinthand.deinit();

        for (pov_player_hand_raw) |card| {
            pov_player_hinthand.append(card.hints);
        }

        var i: usize = 0;
        while (i < self.worlds.len) : (i += 1) {
            const tail = self.worlds.len - i - 1;
            const fixed_scenario = self.access(tail, pov_player_index, 0).toCardList(allocator);
            defer fixed_scenario.deinit();
            if (!other_has_some_matching_configuration(pov_player_hinthand.items, fixed_scenario.items)) {
                //cleanup
                for (self.worlds.items[tail]) |pl| { //aaw
                    for (pl) |aw| {
                        aw.deinit();
                    }
                    pl.deinit();
                }
                self.worlds.items[tail].deinit();
                self.worlds.popOrNull();
            }
        }

        // 1. remove it for the other players
        // I know that I also go through the fixed scenarios, but I think it is ok (because there is only 1)
        i = 0;
        while (i < self.worlds.len) : (i += 1) {
            var player_index: usize = 0;
            while (player_index < players.len) : (player_index += 1) {
                var player_hand_raw = players[player_index].hand;
                var player_hinthand = ArrayList(Card).init(allocator);
                defer pov_player_hinthand.deinit();

                for (player_hand_raw) |card| {
                    player_hinthand.append(card.hints);
                }

                var k: usize = 0;

                while (k < self.worlds.items[i].items[player_index].len) {
                    const tail = self.worlds.items[i].items[player_index].len - k - 1;
                    const imagined_scenario = self.access(i, player_index, tail).toCardList(allocator);
                    defer imagined_scenario.deinit();
                    if (!other_has_some_matching_configuration(player_hinthand.items, imagined_scenario.items)) {
                        self.worlds.items[i].items[player_index].popOrNull();
                    }
                }
            }
        }

        //2. remove any configuration that resulted in an empty set

        i = 0;
        while (i < self.worlds.len) : (i += 1) {
            const tail = self.worlds.len - 1 - i;
            var player_index: usize = 0;
            while (player_index < players.len) : (player_index += 1) {
                if (self.worlds.items[i].items[player_index] == 0) {
                    for (self.worlds.items[tail]) |pl| { //aaw
                        for (pl) |aw| {
                            aw.deinit();
                        }
                        pl.deinit();
                    }
                    self.worlds.items[tail].deinit();
                    self.worlds.popOrNull();
                }
            }
        }
    }

    //hinthand is the hand containing only hints, so there might be color/value = unknown
    //other is a fully speficied hand with no unknowns

    pub fn other_has_some_matching_configuration(hinthand: []Card, other: []Card) bool {
        if (hinthand.len != other.len) {
            return false;
        }
        //A deck has at most 50 cards so the hands cannot be more than 100 cards big
        var buffer: [100]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buffer);
        const allocator = fba.allocator();
        var permutation_iterator = PermutationIterator.HeapsAlgorithm.init(allocator, hinthand.len);

        while (permutation_iterator.next()) |perm| {
            if (is_matching_configuration(hinthand, other, perm)) {
                return true;
            }
        }
        return false;
    }

    // Given that other has been moved about with permutation, does it match the hinthand?
    pub fn is_matching_configuration(hinthand: []Card, other: []Card, permutation: []u8) bool {
        var permutation_is_matching = true;
        for (hinthand) |_, i| {
            var current_card = hinthand[permutation[i]];
            if (current_card.color != Color.unknown) {
                if (current_card.color != other[i].color) {
                    permutation_is_matching = false;
                }
            }
            if (current_card.value != Color.unknown) {
                if (current_card.value != other[i].value) {
                    permutation_is_matching = false;
                }
            }
        }
        return permutation_is_matching;
    }

    pub fn deinit(self: *Self) void {
        for (self.worlds.items) |aaw| {
            for (aaw.items) |aw| {
                aw.deinit();
            }
            aaw.deinit();
        }
        self.worlds.deinit();
    }

    pub fn access(self: Self, fixed_card_world_index: usize, for_player: usize, equivalence: usize) World {
        return self.worlds.items[fixed_card_world_index].items[for_player].items[equivalence];
    }
};

//TODO: I could eventually make a count of how many configuration is the various things, but right now I am only interested in certainty so I will make sure that it treats this with certainty
const CardWithStates = struct {
    card: Card,
    // Can be played right now!
    is_playable: bool, //There exists an assignment such that the card is immediately playable
    is_unplayable: bool, //There exists an assignment such that the card is not immediately playable

    // Is unique and needs to be played
    is_dispensible: bool, //There exists an assignment such that the card is dispensible (i.e. can be discarded)
    is_indispensible: bool, //There exists an assignment such that the card is indispesible (i.e. cannot be discarded)

    // Has already been played
    is_dead: bool, //There exists an assignment such that the card is dead (i.e. cannot be played under any circumstance)
    is_alive: bool, //There exists an assignment such that the card is dead (i.e. can be played at some point in the future)
};
const Agent = struct {
    player_id: u64,
    pov_kripke_structure: KripkeStructure,
    hand: ArrayList(CardWithStates), //It only sees what is hinted about its cards, indexes should match the game state :)
    view: CurrentPlayerView,
    // pub fn updateCardStates(self:*Self) void {

    // Go through all fixed scenarios
    // For each matching configuration with your hinthand, figure out
    // whether the card can satisfy the booleans above.
    // Initially the booleans should all be "false" until proven.
    // }
    // A list of function pointers, that takes the Agent and the Game and returns true if it could perform the action specified by the list, otherwise it returns false and goes to next element. It is given that an action must be performed :)
    //Initially it can be just if else and not function pointers
};

//TODO: run simulation and try not to cry
// test "Initial time and space feasibility" {
//     var timer = try std.time.Timer.start();
//     const deck = CardSet.getWholeDeckSet();
//     const hanabi_pile = CardSet.emptySet();
//     const discard_pile = CardSet.emptySet();
//     var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
//     // var allocator = std.testing.allocator;
//     defer arena.deinit();
//     var allocator = arena.allocator();

//     // _ = hanabi_pile;
//     // _ = discard_pile;
//     // _ = allocator;

//     const seed = [_]u8{1} ** 32;
//     var generator = std.rand.DefaultCsprng.init(seed);
//     var prng = generator.random();

//     var other_players: [5]CardSet = undefined;
//     for (&other_players) |*player| {
//         player.* = CardSet.emptySet();
//     }
//     var buffer: [100]u8 = undefined;
//     var fba = std.heap.FixedBufferAllocator.init(&buffer);
//     const fixedalloc = fba.allocator();
//     var cardIndices = ArrayList(u5).init(fixedalloc);
//     defer cardIndices.deinit();

//     for (deck.card_encoding) |encoding, i| {
//         var k: u64 = 0;
//         // std.debug.print("\nencoding:{any}\n", .{encoding});
//         while (k < encoding) : (k += 1) {
//             cardIndices.append(@truncate(u5, i)) catch unreachable;
//         }
//     }
//     var k: u64 = 0;
//     while (k < 5) : (k += 1) {
//         var j: u64 = 0;
//         while (j < 4) : (j += 1) {
//             // std.debug.print("\nCardindices.items.len:{any}\n", .{cardIndices.items.len});
//             var getCardAt = prng.uintLessThan(usize, cardIndices.items.len);
//             const cardIndex = cardIndices.items[getCardAt];
//             _ = cardIndices.swapRemove(getCardAt);

//             other_players[k] = other_players[k].set(cardIndex, other_players[k].card_encoding[cardIndex] + 1);
//         }
//     }

//     // std.debug.print("\nother_playres:{any}\n", .{other_players});

//     // _ = getCardAt;

//     // pub fn init(allocator: Allocator, deck: CardSet, hanabi_pile: CardSet, discard_pile: CardSet, other_players: ArrayList(CardSet), hints_about_your_cards: anytype, pov_player_handsize: u64, player_index: usize) Self {

//     var myNewKripkeStructure = KripkeStructure.init(allocator, deck, hanabi_pile, discard_pile, other_players[1..5], 4, 0);
//     defer myNewKripkeStructure.deinit();

//     var totalbytesize: u64 = 0;
//     std.debug.print("\n\n byte size of aaaw:{}\n", .{@sizeOf(ArrayList(ArrayList(ArrayList(World))))});
//     std.debug.print("\n\n byte size of aaw:{}\n", .{@sizeOf(ArrayList(ArrayList(World)))});
//     std.debug.print("\n\n byte size of aw:{}\n", .{@sizeOf(ArrayList(World))});
//     std.debug.print("\n\n byte size of w:{}\n", .{@sizeOf(World)});
//     totalbytesize += @sizeOf(ArrayList(ArrayList(ArrayList(World))));
//     for (myNewKripkeStructure.worlds.items) |fixed_hand| {
//         totalbytesize += @sizeOf(ArrayList(ArrayList(World)));
//         for (fixed_hand.items) |player| {
//             totalbytesize += @sizeOf(ArrayList(World));
//             for (player.items) |_| {
//                 totalbytesize += @sizeOf(World);
//             }
//         }
//     }

//     std.debug.print("\nsomeworld:{any}\n", .{myNewKripkeStructure.access(0, 0, 0)});

//     std.debug.print("\nworld length:{}\n", .{myNewKripkeStructure.worlds.items.len});
//     var end_time = timer.read();
//     std.debug.print("\n\n Initial time and space nanoseconds:{}\n", .{end_time});
//     std.debug.print("\n\n Initial time and space in seconds:{}\n", .{@intToFloat(f128, end_time) / 1E9});
//     std.debug.print("\n\n Initial time and space totalSpace in bytes:{}\n", .{totalbytesize});
//     std.debug.print("\n\n Initial time and space totalSpace in gigabytes:{}\n", .{@intToFloat(f128, totalbytesize) / 1E9});
// }

test "Three wise men simulation :)" {
    // 3 red, and 2 white
    const hatpool = CardSet{ .card_encoding = [_]u2{ 3, 2 } ++ [_]u2{0} ** 23 };

    var allocator = std.testing.allocator;
    {
        var wise_men = [_]CardSet{CardSet.emptySet()} ** 3;
        //RWR
        wise_men[0].card_encoding[0] = 1;
        wise_men[1].card_encoding[1] = 1;
        wise_men[2].card_encoding[0] = 1;

        // wise man index 2, sees RW_

        var myNewKripkeStructure = KripkeStructure.init(allocator, hatpool, CardSet.emptySet(), CardSet.emptySet(), wise_men[0..2], 1, 2);
        defer myNewKripkeStructure.deinit();
        std.debug.print("\n", .{});
        for (myNewKripkeStructure.worlds.items) |fixed_scenario, i| {
            for (fixed_scenario.items) |player, pi| {
                for (player.items) |imagined, ii| {
                    std.debug.print("given fixed scenario:{}, player:{}, can imagine possibility number: {} that:{any}\n", .{ i, pi, ii, imagined.hand.card_encoding });
                }
            }
        }
    }
    {
        std.debug.print("\n================ wisemen2 =================\n", .{});
        // RWW from 0 POV
        // So 0 sees _WW
        var wise_men2 = [_]CardSet{CardSet.emptySet()} ** 3;
        wise_men2[0].card_encoding[0] = 1;
        wise_men2[1].card_encoding[1] = 1;
        wise_men2[2].card_encoding[1] = 1;

        var myNewKripkeStructure2 = KripkeStructure.init(allocator, hatpool, CardSet.emptySet(), CardSet.emptySet(), wise_men2[1..3], 1, 0);
        defer myNewKripkeStructure2.deinit();
        std.debug.print("\n", .{});
        for (myNewKripkeStructure2.worlds.items) |fixed_scenario, i| {
            for (fixed_scenario.items) |player, pi| {
                for (player.items) |imagined, ii| {
                    std.debug.print("given fixed scenario:{}, player:{}, can imagine possibility number: {} that:{any}\n", .{ i, pi, ii, imagined.hand.card_encoding });
                }
            }
        }
    }
}
