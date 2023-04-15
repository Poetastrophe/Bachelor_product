const std = @import("std");
const combination_helpers = @import("combination_helpers.zig");
const CardSet = combination_helpers.CardSet;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

//A world simply represent what is in the players hands.
// Could possibly reduce it to a single hand since the way I represent it, it is obvious which hand that is fixed and which is not hmmm.
const World = struct {
    hand: CardSet,
};

//From POV of a specific agent \__shrug_/
const KripkeStructure = struct {
    const Self = @This();
    //Agent A: POV agent
    //Agent B: imagined knowledge for player B from the POV of A.
    //Encoding is worlds[specific_hand_of_pov_agent][agent_number][possible_hand_of_agent_B]
    //So from A POV there are of course worlds[1][A][0]. Will be the fixed card of worlds[1] because agent A can only imagine that A knows fixed world[1] given the fixed scenario of the hand.
    worlds: ArrayList(ArrayList(ArrayList(World))),
    // It should init based on the cards of the players and on the discard pile...
    pub fn init(allocator: Allocator, deck: CardSet, hanabi_pile: CardSet, discard_pile: CardSet, other_players: ArrayList(CardSet), hints_about_your_cards: anytype, handSize: u64, player_index: usize) Self {
        // _ = allocator;
        _ = hints_about_your_cards; // Unused until I know how
        var hand_pool = deck.setDifference(hanabi_pile).setDifference(discard_pile);
        for (other_players.items) |playerCardSet| {
            hand_pool = hand_pool.setDifference(playerCardSet);
        }
        const pov_player_possibilities = combination_helpers.distinct_combinations_assuming_encoding(hand_pool.card_encoding, handSize, allocator);
        //TODO: I am throwing a way a lot of memory in the end: Use arena allocator.
        defer pov_player_possibilities.deinit();
        var result: ArrayList(ArrayList(ArrayList(World))) = ArrayList(ArrayList(ArrayList(World))).init(allocator);

        for (pov_player_possibilities.items) |encoded_hand_for_pov_player| {
            var i: u64 = 0;
            const number_of_players: u64 = other_players.items.len + 1;
            var tmpLevel2: ArrayList(ArrayList(World)) = ArrayList(ArrayList(World)).initCapacity(number_of_players);
            while (i < number_of_players) : (i += 1) {
                var tmpLevel3: ArrayList(World) = ArrayList(World).init(allocator);
                if (player_index == i) {
                    tmpLevel3.append(CardSet{ .card_encoding = encoded_hand_for_pov_player });
                } else {
                    var hand_pool_for_ith_player = deck.setDifference(hanabi_pile).setDifference(discard_pile);
                    hand_pool_for_ith_player = hand_pool_for_ith_player.setDifference(CardSet{ .card_encoding = encoded_hand_for_pov_player });
                    var p = 0;
                    var k = 0;
                    while (p < number_of_players) : (p += 1) {
                        if (p == player_index or p == i) {
                            continue;
                        }
                        var current_player = other_players[k];
                        hand_pool_for_ith_player = hand_pool_for_ith_player.setDifference(current_player);
                        k += 1;
                    }

                    const other_player_possibilities = combination_helpers.distinct_combinations_assuming_encoding(hand_pool_for_ith_player.card_encoding, handSize, allocator);
                    defer other_player_possibilities.deinit();
                    for (other_player_possibilities) |other_player_hand_encoding| {
                        tmpLevel3.append(CardSet{ .card_encoding = other_player_hand_encoding });
                    }
                }
                tmpLevel2[i] = tmpLevel3;
            }
            result.append(tmpLevel2);
        }
    }
    // pub fn deinit() void {}
};

//TODO: run simulation and try not to cry
test "OMG WHAT" {
    const deck = CardSet.getWholeDeckSet();
    const hanabi_pile = CardSet.emptySet();
    const discard_pile = CardSet.emptySet();
    var allocator = std.testing.allocator;
    _ = hanabi_pile;
    _ = discard_pile;
    _ = allocator;

    const seed = [_]u8{1} ** 32;
    var generator = std.rand.DefaultCsprng.init(seed);
    var prng = generator.random();

    var getCardAt = prng.uintLessThan(u64, deck.card_encoding.len);

    _ = getCardAt;

    // pub fn init(allocator: Allocator, deck: CardSet, hanabi_pile: CardSet, discard_pile: CardSet, other_players: ArrayList(CardSet), hints_about_your_cards: anytype, handSize: u64, player_index: usize) Self {

    // var myNewKripkeStructure = KripkeStructure.init(allocator,deck,
}
