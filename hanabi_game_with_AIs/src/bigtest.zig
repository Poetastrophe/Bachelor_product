const std = @import("std");
const combination_helpers = @import("./multi_agent_solvers/combination_helpers.zig");
const Hanabi_game = @import("./hanabi_board_game.zig");
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
const PermutationIterator = @import("./multi_agent_solvers/PermutationIterator.zig");
const KripkeStructure = @import("./multi_agent_solvers/agent.zig").KripkeStructure;
const World = @import("./multi_agent_solvers/agent.zig").World;

test "Initial time and space feasibility" {
    var timer = try std.time.Timer.start();
    const deck = CardSet.getWholeDeckSet();
    const hanabi_pile = CardSet.emptySet();
    const discard_pile = CardSet.emptySet();
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);

    defer arena.deinit();
    var allocator = arena.allocator();

    const seed = [_]u8{1} ** 32;
    var generator = std.rand.DefaultCsprng.init(seed);
    var prng = generator.random();

    var other_players: [5]CardSet = undefined;
    for (&other_players) |*player| {
        player.* = CardSet.emptySet();
    }
    var buffer: [100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const fixedalloc = fba.allocator();
    var cardIndices = ArrayList(u5).init(fixedalloc);
    defer cardIndices.deinit();

    for (deck.card_encoding) |encoding, i| {
        var k: u64 = 0;

        while (k < encoding) : (k += 1) {
            cardIndices.append(@truncate(u5, i)) catch unreachable;
        }
    }
    var k: u64 = 0;
    while (k < 5) : (k += 1) {
        var j: u64 = 0;
        while (j < 4) : (j += 1) {
            var getCardAt = prng.uintLessThan(usize, cardIndices.items.len);
            const cardIndex = cardIndices.items[getCardAt];
            _ = cardIndices.swapRemove(getCardAt);

            other_players[k] = other_players[k].set(cardIndex, other_players[k].card_encoding[cardIndex] + 1);
        }
    }

    var myNewKripkeStructure = KripkeStructure.init(allocator, deck, hanabi_pile, discard_pile, other_players[1..5], 4, 0);
    defer myNewKripkeStructure.deinit();

    var totalbytesize: u64 = 0;

    totalbytesize += @sizeOf(ArrayList(ArrayList(ArrayList(World))));
    for (myNewKripkeStructure.worlds.items) |fixed_hand| {
        totalbytesize += @sizeOf(ArrayList(ArrayList(World)));
        for (fixed_hand.items) |player| {
            totalbytesize += @sizeOf(ArrayList(World));
            for (player.items) |_| {
                totalbytesize += @sizeOf(World);
            }
        }
    }

    // for (myNewKripkeStructure.worlds.items) |fixed_hand, fhi| {
    //     for (fixed_hand.items) |player, pi| {
    //         std.debug.print("for fixed hand:{}, player {}, has {} combinations\n", .{ fhi, pi, player.items.len });
    //     }
    // }

    var end_time = timer.read();
    _ = end_time;
    // std.debug.print("\n\n Initial time and space nanoseconds:{}\n", .{end_time});
    // std.debug.print("\n\n Initial time and space in seconds:{}\n", .{@intToFloat(f128, end_time) / 1E9});
    // std.debug.print("\n\n Initial time and space totalSpace in bytes:{}\n", .{totalbytesize});
    // std.debug.print("\n\n Initial time and space totalSpace in gigabytes:{}\n", .{@intToFloat(f128, totalbytesize) / 1E9});
}
