const std = @import("std");
const ArrayList = @import("std").ArrayList;
const Hanabi_game = @import("./../hanabi_board_game.zig");
const PermutationIterator = @import("PermutationIterator.zig");
const Card = Hanabi_game.Card;

pub const test_is_on = true;
pub const KripkeStructure_init_time = true;
pub const KripkeStructure_remove_worlds_based_on_hints_time = true;
pub const KripkeStructure_deinit_time = true;

pub const Agent_other_has_some_matching_configuration_number_of_unique_hands = true;

pub fn countCombinations(hinthand: []Card) void {
    var buffer: [1600]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var permutation_iterator = PermutationIterator.HeapsAlgorithm.init(allocator, hinthand.len);
    defer permutation_iterator.deinit();

    var arr_hand_count = ArrayList(ArrayList(Card)).initCapacity(allocator, 25) catch unreachable;

    while (permutation_iterator.next()) |perm| {
        var someHand = ArrayList(Card).initCapacity(allocator, 6) catch unreachable;
        for (hinthand) |_, k| {
            someHand.append(hinthand[perm[k]]) catch unreachable;
        }
        arr_hand_count.append(someHand) catch unreachable;
    }

    // std.debug.print("Agent.other_has_some_matching_configuration.number_of_unique_hands B4 REMOVAL:{}\n", .{arr_hand_count.items.len});

    var total = arr_hand_count.items.len;
    var ik: usize = 0;
    while (ik < total) : (ik += 1) {
        const n = arr_hand_count.items.len;
        var j: usize = 0;
        while (j < n) : (j += 1) {
            const tail = n - j - 1;
            if (tail == ik) {
                break;
            }
            var is_identical = true;
            for (arr_hand_count.items[ik].items) |_, k| {
                const card_A = arr_hand_count.items[ik].items[k];
                const card_B = arr_hand_count.items[tail].items[k];
                if (card_A.color != card_B.color or card_A.value != card_B.value) {
                    is_identical = false;
                }
            }

            if (is_identical) {
                _ = arr_hand_count.swapRemove(tail);
                total -= 1;
            }
        }
    }
    std.debug.print("Agent.other_has_some_matching_configuration.number_of_unique_hands:{}\n", .{arr_hand_count.items.len});
}
