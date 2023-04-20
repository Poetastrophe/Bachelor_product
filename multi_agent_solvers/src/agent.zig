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
const seed = [_]u8{1} ** 32;
var generator = std.rand.DefaultCsprng.init(seed);
var prng = generator.random();

//A world simply represent what is in the players hands.
// Could possibly reduce it to a single hand since the way I represent it, it is obvious which hand that is fixed and which is not hmmm.
pub const World = struct {
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
pub const KripkeStructure = struct {
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
        //TODO 1: I am throwing a way a lot of memory in the end: Use arena allocator.
        // Arena allocator would have the same problems, use a memory pool so that it can deallocate faster :)
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

//TODO 1: I could eventually make a count of how many configuration is the various things, but right now I am only interested in certainty so I will make sure that it treats this with certainty
const CardWithStates = struct {
    const Self = @This();
    card: Card,
    // Can be played right now!
    is_playable: bool, //There exists an assignment such that the card is immediately playable
    is_unplayable: bool, //There exists an assignment such that the card is not immediately playable

    // Is unique
    is_unique: bool, //There exists an assignment such that the card is dispensible (i.e. can be discarded)
    is_duplicate: bool, //There exists an assignment such that the card is indispesible (i.e. cannot be discarded)

    // Has already been played or needs to be played
    is_dead: bool, //There exists an assignment such that the card is dead (i.e. cannot be played under any circumstance)
    is_alive: bool, //There exists an assignment such that the card is dead (i.e. can be played at some point in the future)
    pub fn create(card: Card) Self {
        return Self{ .card = card, .is_playable = false, .is_unplayable = false, .is_unique = false, .is_duplicate = false, .is_dead = false, .is_alive = false };
    }
};
const Agent = struct {
    const Self = @This();
    player_id: u64,
    pov_kripke_structure: KripkeStructure,
    hand: ArrayList(CardWithStates), //It only sees what is hinted about its cards, indexes should match the game state :)
    view: CurrentPlayerView,

    // Should work for all hands
    // Should not remove anything
    pub fn updateCardStates(self: *Self) void {
        var buffer: [200]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buffer);
        const allocator = fba.allocator();

        // Go through all fixed scenarios
        // For each matching configuration with your hinthand, figure out
        // whether the card can satisfy the booleans above.
        // Initially the booleans should all be "false" until proven.
        for (self.hand.items) |_, i| {
            self.hand.items[i].is_playable = false;
            self.hand.items[i].is_unplayable = false;

            self.hand.items[i].is_unique = false;
            self.hand.items[i].is_duplicate = false;

            self.hand.items[i].is_dead = false;
            self.hand.items[i].is_alive = false;
        }
        // hinthand

        var hinthand = ArrayList(Card).init(allocator);
        for (self.hand) |cardwithstates| {
            hinthand.append(cardwithstates.card);
        }

        var i: usize = 0;
        while (i < self.pov_kripke_structure.worlds.len) : (i += 1) {
            //0. find a matching hand (there is always one)

            const handsize = self.hand.items.len;
            var permutation_iterator = PermutationIterator.HeapsAlgorithm.init(allocator, handsize);
            defer permutation_iterator.deinit();
            while (permutation_iterator.next()) |perm| {
                const fixed_scenario = self.world.access(i, self.player_id, 0).toCardList(allocator);
                defer fixed_scenario.deinit();
                if (KripkeStructure.is_matching_configuration(hinthand.items, fixed_scenario, perm)) {
                    var k: usize = 0;
                    while (k < handsize) : (k += 1) {
                        const kth_card = fixed_scenario.items[perm[k]];

                        // Decide whether it is playable
                        const last_index = self.view.hanabi_piles[@enumToInt(kth_card.color)].items.len;
                        if (last_index == @enumToInt(kth_card.value)) {
                            self.cardwithstates.items[k].is_playable = true;
                        } else {
                            self.cardwithstates.items[k].is_unplayable = true;
                        }

                        // Decide whether it is dispensible
                        // check first if it is the only one in the hand.
                        const fixed_scenario_cardset = CardSet.createUsingSliceOfCards(fixed_scenario);
                        var index_of_card = CardSet.cardToIdPosition(kth_card);
                        if (fixed_scenario_cardset.get(index_of_card) > 1) {
                            self.cardwithstates.items[k].is_unique = true;
                        } else { //get(index_of_card) == 1
                            const initial_deck = self.view.initial_deck;
                            const discard_pile = self.view.discard_pile;
                            const hanabi_pile = self.view.hanabi_pile;
                            const cards_left = initial_deck.setDifference(discard_pile).setDifference(hanabi_pile);
                            if (cards_left.get(index_of_card) == 1) {
                                self.cardwithstates.items[k].is_duplicate = true;
                            } else {
                                self.cardwithstates.items[k].is_unique = true;
                            }
                        }

                        //decide dead or alive
                        if (last_index <= @enumToInt(kth_card.value)) {
                            self.cardwithstates.items[k].is_alive = true;
                        } else {
                            self.cardwithstates.items[k].is_dead = true;
                        }
                    }
                }
            }
            // PermutationIterator.HeapsAlgorithm

        }
    }
    pub fn insert_cards_into_hand(self: *Self, current_player_view: CurrentPlayerView) void {
        std.debug.assert(current_player_view.current_player == self.player_id);
        self.view = current_player_view;
        self.cardwithstates.clearRetainingCapacity();
        for (self.view.players.items[self.player_id].hand) |cardwithhints| {
            self.cardwithstates.append(CardWithStates.create(cardwithhints.hints));
        }
    }

    // Super method
    //set game state,generate a new kripkestructure, simplify based on hints, update card states
    //It is fair to assume that every time a player needs to play she has to update her entire game state, since there has been played several cards or given some hints which significantly reduces the state space.
    // You could argue that if there has only been given hints then you don't need to generate anew, but if you expect to generate anew almost every round then that is not very justified and is therefore a premature optimization.
    pub fn init(player_id: u64, view: CurrentPlayerView, allocator: Allocator) Self {

        // unreachable;
        // player_id: u64,
        // pov_kripke_structure: KripkeStructure,
        // hand: ArrayList(CardWithStates), //It only sees what is hinted about its cards, indexes should match the game state :)
        // view: CurrentPlayerView,

        // pub fn init(allocator: Allocator, initial_deck: CardSet, hanabi_pile: CardSet, discard_pile: CardSet, other_players: []CardSet, pov_player_handsize: u64, pov_player_index: usize) Self {

        // var buffer: [200]u8 = undefined;
        // var fba = std.heap.FixedBufferAllocator.init(&buffer);
        // const allocator = fba.allocator();
        var other_players = ArrayList(CardSet).init(allocator);
        defer other_players.deinit();
        for (view.players.items) |player, i| {
            if (i == player_id) {
                continue;
            }
            var hand = ArrayList(Card).init(allocator);
            defer hand.deinit();
            for (player.hand.items) |cardwithhints| {
                const card = cardwithhints.card;
                hand.append(card);
            }
            other_players.append(CardSet.createUsingSliceOfCards(hand.items));
        }

        var pov_kripke_structure = KripkeStructure.init(allocator, view.initial_deck, view.hanabi_pile, view.discard_pile, other_players, view.players.items[player_id].items.len, player_id);

        // pub fn remove_worlds_based_on_hints(self: *Self, players: []Player, pov_player_index: usize) void {
        pov_kripke_structure.remove_worlds_based_on_hints(view.players.items, player_id);

        var res = Self{ .player_id = player_id, .pov_kripke_structure = pov_kripke_structure, .hand = undefined, .view = view };
        res.hand = ArrayList(CardWithStates).init(allocator);
        res.insert_cards_into_hand();
        res.updateCardStates();
        return res;
    }
    pub fn deinit(self: *Self) void {
        self.pov_kripke_structure.deinit();
        self.hand.deinit();
        self.view.deinit();
    }

    // Execute the strategy and modify game
    // you don't have to modify yourself given that you just take the game state
    // TODO 1: give an interface that you can interact with but not get the entire game state?
    pub fn make_move(self: Self, game: *Game) void {
        // 1. Play the playable card with lowest index.
        // It has to be beyond doubt that this card can be played
        var maybe_index_to_play: ?usize = null;
        for (self.hand.items) |cws, i| {
            if (cws.is_playable and !cws.is_unplayable and !cws.is_dead) {
                maybe_index_to_play = i;
                break;
            }
        }
        if (maybe_index_to_play) |index_to_play| {
            game.play(index_to_play);
            return;
        }

        // 2. If there are less than 5 cards in the discard pile, discard the dead card with lowest index
        if (self.view.discard_pile.items.len < 5 and self.view.blue_tokens != self.Hanabi_game.INITIAL_BLUE_TOKENS) {
            for (self.hand.items) |cws, i| {
                if (cws.is_dead and !cws.is_alive) {
                    maybe_index_to_play = i;
                    break;
                }
            }
            if (maybe_index_to_play) |index_to_play| {
                game.discard(index_to_play);
                return;
            }
        }

        // 3. If there are hint tokens available, give a hint.
        if (self.view.blue_tokens > 0) {
            if (self.hintRandomThatIsNotAlreadyKnown(game)) {
                return;
            }
        }

        // 4. Discard the dead card with lowest index.
        if (self.view.blue_tokens != Hanabi_game.INITIAL_BLUE_TOKENS) {
            for (self.hand.items) |cws, i| {
                if (cws.is_dead and !cws.alive) {
                    maybe_index_to_play = i;
                    break;
                }
            }
            if (maybe_index_to_play) |index_to_play| {
                game.discard(index_to_play);
                return;
            }
        }
        // 5. If a card in the player’s hand is the same as another card in any player’s hand, i.e.,
        // if (self.view.blue_tokens != Hanabi_game.INITIAL_BLUE_TOKENS) {
        //     for (self.hand.items) |cws, i| {
        //         if (cws.is_duplicate and !cws.is_unique and ) {
        //             maybe_index_to_play = i;
        //             break;
        //         }
        //     }
        //     if (maybe_index_to_play) |index_to_play| {
        //         game.discard(index_to_play);
        //         return;
        //     }
        // }
        // 6. Discard the dispensable card with lowest index.
        if (self.view.blue_tokens != Hanabi_game.INITIAL_BLUE_TOKENS) {
            for (self.hand.items) |cws, i| {
                if (cws.is_duplicate and !cws.is_unique) {
                    maybe_index_to_play = i;
                    break;
                }
            }
            if (maybe_index_to_play) |index_to_play| {
                game.discard(index_to_play);
                return;
            }
        }
        if (self.view.blue_tokens != Hanabi_game.INITIAL_BLUE_TOKENS) {
            // TODO 1:Should I skip turn if there are no cards to play?
            game.discard(0);
            return;
        }

        game.play(0);
        return;
    }

    const HintToGive = struct {
        to_player: usize,
        value_or_color: union(enum) {
            value: Value,
            color: Color,
        },
    };
    // True if you were able to give a hint,
    // false otherwise.
    pub fn hintRandomThatIsNotAlreadyKnown(self: *Self, game: *Game) bool {
        var buffer: [200]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buffer);
        const allocator = fba.allocator();

        var possible_hints = ArrayList(HintToGive).init(allocator);
        for (self.view.players.items) |p, i| {
            if (i == self.player_id) {
                continue;
            }
            for (p.cardwithhints.items) |cwh| {
                if (cwh.hints.color == Color.unknown) {
                    possible_hints.append(HintToGive{ .to_player = i, .value_or_color = cwh.card.color });
                }
                if (cwh.hints.value == Value.unknown) {
                    possible_hints.append(HintToGive{ .to_player = i, .value_or_color = cwh.card.value });
                }
            }
        }
        if (possible_hints.items.len == 0) {
            return false;
        }

        // I could try to remove duplicates but now I just pick a random one.
        // The method is not that good to begin with so no need to do extra work

        var hint_to_give = possible_hints.items[prng.uintLessThan(u64, possible_hints.items.len)];
        switch (hint_to_give.value_or_color) {
            .value => game.hint_value(hint_to_give.value_or_color.value, hint_to_give.to_player),
            .color => game.hint_color(hint_to_give.value_or_color.color, hint_to_give.to_player),
        }
        return true;
    }

    // A list of function pointers, that takes the Agent and the Game and returns true if it could perform the action specified by the list, otherwise it returns false and goes to next element. It is given that an action must be performed :)
    //Initially it can be just if else and not function pointers
};

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
