const std = @import("std");
const ArrayList = std.ArrayList;
const Writer = std.io.Writer;
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;
const eql = std.mem.eql;

const NUMBER_OF_CARDS = 5 * 3 + 5 * 2 * 3 + 5;
const INITIAL_BLUE_TOKENS = 8;
const INITIAL_BLACK_TOKENS = 4;
const NUMBER_HANABI_PILES = 5;
const DRAW_IF_LESS_THAN_4_PLAYERS = 5;
const DRAW_IF_MORE_THAN_3_PLAYERS = 4;
const Color = enum {
    red,
    blue,
    green,
    yellow,
    white,
    unknown,
    pub fn writeColor(self: Color, writer: anytype) void {
        _ = switch (self) {
            .red => writer.write("Red"),
            .blue => writer.write("Blue"),
            .green => writer.write("Green"),
            .yellow => writer.write("Yellow"),
            .white => writer.write("White"),
            .unknown => writer.write("Unknown"),
        } catch unreachable;
    }
};
const Value = enum {
    one,
    two,
    three,
    four,
    five,
    unknown,

    pub fn writeValue(self: Value, writer: anytype) void {
        _ = switch (self) {
            .one => writer.write("One"),
            .two => writer.write("Two"),
            .three => writer.write("Three"),
            .four => writer.write("Four"),
            .five => writer.write("Five"),
            .unknown => writer.write("Unknown"),
        } catch unreachable;
    }
};
const Card = struct {
    const Self = @This();
    color: Color,
    value: Value,
    pub fn writeCard(self: Self, writer: anytype) void {
        _ = switch (self.color) {
            .red => writer.write("r"),
            .blue => writer.write("b"),
            .green => writer.write("g"),
            .yellow => writer.write("y"),
            .white => writer.write("w"),
            .unknown => writer.write("u"),
        } catch unreachable;
        _ = switch (self.value) {
            .one => writer.write("1"),
            .two => writer.write("2"),
            .three => writer.write("3"),
            .four => writer.write("4"),
            .five => writer.write("5"),
            .unknown => writer.write("u"),
        } catch unreachable;
    }
};

const CardWithHints = struct {
    card: Card,
    hints: Card, // TODO: could be necessary to also hint about which player gave the hint and when. but alas that is too much. 4 me.
};

const Player = struct {
    const Self = @This();
    hand: ArrayList(CardWithHints),
    pub fn to_string_no_hints(self: Self, writer: anytype) void {
        for (self.hand.items) |card| {
            card.card.writeCard(writer);
            _ = writer.write(" ") catch unreachable;
        }
    }
    pub fn to_string(self: Self, writer: anytype) void {
        for (self.hand.items) |card| {
            card.card.writeCard(writer);
            _ = writer.write("|") catch unreachable;
            card.hints.writeCard(writer);
            _ = writer.write(" ") catch unreachable;
        }
    }
    pub fn deinit(self: *Self) void {
        self.hand.deinit();
    }
};

const CurrentPlayerView = struct {
    const Self = @This();
    players: ArrayList(Player),
    initial_deck: ArrayList(Card),
    discard_pile: ArrayList(Card),
    hanabi_piles: [NUMBER_HANABI_PILES]ArrayList(Card),
    current_player: u64,
    blue_tokens: u64,
    black_tokens: u64,
    game_is_over: bool,
    rounds_left: i64,
    //It will not show the current player, nor the deck, which are not visible from the players perspective
    pub fn init(allocator: Allocator, game: Game) Self {
        var discard_pile = ArrayList(Card).init(allocator);
        _ = discard_pile.appendSlice(game.discard_pile.items) catch unreachable;

        var hanabi_piles: [NUMBER_HANABI_PILES]ArrayList(Card) = undefined;
        var i: u64 = 0;
        while (i < NUMBER_HANABI_PILES) : (i += 1) {
            var tmp = ArrayList(Card).init(allocator);
            tmp.appendSlice(game.hanabi_piles[i].items);
            hanabi_piles[i] = tmp;
        }

        var players = ArrayList(Player).init(allocator);

        while (i < game.players.items.len) : (i += 1) {
            var tmp = ArrayList(CardWithHints).init(allocator);

            tmp.appendSlice(game.players.items[i].hand.items);
            players.append(Player{ .hand = tmp });
        }

        for (players[game.current_player]) |_, k| {
            players[game.current_player][k].card = Card{ .color = Color.unknown, .value = Value.unknown };
        }

        return Self{
            .players = players,
            .initial_deck = game.initial_deck,
            .discard_pile = discard_pile,
            .hanabi_piles = hanabi_piles,
            .current_player = game.current_player,
            .blue_tokens = game.blue_tokens,
            .black_tokens = game.black_tokens,
            .game_is_over = game.game_is_over,
            .rounds_left = game.rounds_left,
        };
    }
    pub fn deinit(self: *Self) void {
        for (self.players.items) |p| {
            p.deinit();
        }
        self.players.deinit();
        self.initial_deck.deinit();
        self.discard_pile.deinit();
        for (self.hanabi_piles) |list| {
            list.deinit();
        }
    }
};

pub const Game = struct {
    const Self = @This();
    current_player: u64,
    players: ArrayList(Player),
    discard_pile: ArrayList(Card),
    hanabi_piles: [NUMBER_HANABI_PILES]ArrayList(Card),
    initial_deck: ArrayList(Card),
    deck: ArrayList(Card),
    blue_tokens: u64,
    black_tokens: u64,
    game_is_over: bool,
    rounds_left: u64,

    pub fn init(allocator: Allocator, number_of_players: u3, seed: [32]u8) Self {
        const countarr = [_]u64{ 3, 2, 2, 2, 1 };
        const values = [_]Value{ Value.one, Value.two, Value.three, Value.four, Value.five };
        const colors = [_]Color{ Color.red, Color.blue, Color.green, Color.yellow, Color.white };

        var deck = ArrayList(Card).init(allocator);
        var i: u64 = 0;
        while (i < countarr.len) : (i += 1) {
            for (colors) |color| {
                var k: u64 = 0;
                while (k < countarr[i]) : (k += 1) {
                    _ = deck.append(Card{ .value = values[i], .color = color }) catch unreachable;
                }
            }
        }
        // std.debug.print("\n{any}\n", .{deck});

        // seed[0] = 13;
        var generator = std.rand.DefaultCsprng.init(seed);
        var prng = generator.random();

        i = 0;
        while (i < deck.items.len) : (i += 1) {
            var swapi = prng.uintLessThan(u64, deck.items.len);
            var tmp = deck.items[i];
            deck.items[i] = deck.items[swapi];
            deck.items[swapi] = tmp;
        }
        // std.debug.print("\n{any}\n", .{deck});

        var players = ArrayList(Player).init(allocator);
        i = 0;
        while (i < number_of_players) : (i += 1) {
            var tmp = ArrayList(CardWithHints).init(allocator);
            if (number_of_players < 4) {
                var k: u64 = 0;
                while (k < DRAW_IF_LESS_THAN_4_PLAYERS) : (k += 1) {
                    _ = tmp.append(CardWithHints{ .card = deck.popOrNull().?, .hints = Card{ .color = Color.unknown, .value = Value.unknown } }) catch unreachable;
                }
            } else {
                var k: u64 = 0;
                while (k < DRAW_IF_MORE_THAN_3_PLAYERS) : (k += 1) {
                    _ = tmp.append(CardWithHints{ .card = deck.popOrNull().?, .hints = Card{ .color = Color.unknown, .value = Value.unknown } }) catch unreachable;
                }
            }
            _ = players.append(Player{ .hand = tmp }) catch unreachable;
        }

        var discard_pile = ArrayList(Card).init(allocator);

        var hanabi_piles: [NUMBER_HANABI_PILES]ArrayList(Card) = undefined;
        i = 0;
        while (i < NUMBER_HANABI_PILES) : (i += 1) {
            var tmp = ArrayList(Card).init(allocator);
            hanabi_piles[i] = tmp;
        }

        return Self{
            .players = players,
            .current_player = 0,
            .deck = deck,
            .initial_deck = deck,
            .discard_pile = discard_pile,
            .hanabi_piles = hanabi_piles,
            .blue_tokens = INITIAL_BLUE_TOKENS,
            .black_tokens = INITIAL_BLACK_TOKENS,
            .game_is_over = false,
            .rounds_left = std.math.maxInt(u64),
        };
    }
    pub fn deinit(self: *Self) void {
        for (self.players.items) |p| {
            p.deinit();
        }
        self.players.deinit();
        self.initial_deck.deinit();
        self.discard_pile.deinit();
        for (self.hanabi_piles) |list| {
            list.deinit();
        }
        self.deck.deinit();
    }

    pub fn get_score(self: Self) u64 {
        var score: u64 = 0;
        for (self.hanabi_piles) |pile| {
            score += pile.items.len;
        }
        return score;
    }
    pub fn get_current_player_view(self: Self, allocator: Allocator) CurrentPlayerView {
        return CurrentPlayerView.init(allocator, self);
    }

    fn next_turn(self: *Self) u64 {
        self.current_player = (self.current_player + 1) % self.players.items.len;
        return self.current_player;
    }

    fn discard(self: *Self, index: u64) void {
        std.debug.assert(index < self.players.items[self.current_player].hand.items.len);
        std.debug.assert(self.blue_tokens < INITIAL_BLUE_TOKENS);
        std.debug.assert(!self.game_is_over);
        _ = self.discard_pile.append(self.players.items[self.current_player].hand.items[index].card) catch unreachable;
        _ = self.draw_card_or_remove_at(index);
        self.blue_tokens += 1;
    }

    fn draw_card_or_remove_at(self: *Self, index: u64) ?CardWithHints {
        var maybe_new_card = self.deck.popOrNull();
        if (maybe_new_card) |new_card| {
            const new_card_with_hints = CardWithHints{ .card = new_card, .hints = Card{ .color = Color.unknown, .value = Value.unknown } };
            self.players.items[self.current_player].hand.items[index] = new_card_with_hints;
            return new_card_with_hints;
        } else {
            if (self.rounds_left == std.math.maxInt(u64)) {
                self.rounds_left = self.players.items.len;
            } else {
                self.rounds_left -= 1;
            }
            if (self.rounds_left == 0) {
                self.game_is_over = true;
            }
            _ = self.players.items[self.current_player].hand.swapRemove(index);
            return null;
        }
    }

    fn play(self: *Self, index: u64) void {
        std.debug.assert(index < self.players.items[self.current_player].hand.items.len);
        std.debug.assert(!self.game_is_over);
        var old_card = self.players.items[self.current_player].hand.items[index];
        _ = self.draw_card_or_remove_at(index);

        var last_index = self.hanabi_piles[@enumToInt(old_card.card.color)].items.len;

        if (last_index == @enumToInt(old_card.card.value)) {
            _ = self.hanabi_piles[@enumToInt(old_card.card.color)].append(old_card.card) catch unreachable;
        } else {
            self.black_tokens -= 1;
            if (self.black_tokens == 0) {
                self.game_is_over = true;
            }
        }
    }

    const MAX_NUMBER_OF_CARDS_IN_HAND = 5;
    pub fn hint_color(self: *Self, color: Color, player: u64) void {
        std.debug.assert(player < self.players.items.len);
        std.debug.assert(player != self.current_player);
        std.debug.assert(self.blue_tokens > 0);
        std.debug.assert(!self.game_is_over);

        self.blue_tokens -= 1;

        var did_hint = false;

        var hand = self.players.items[player].hand;

        for (hand.items) |_, i| {
            if (hand.items[i].card.color == color) {
                hand.items[i].hints.color = color;
                did_hint = true;
            }
        }

        std.debug.assert(did_hint);
    }

    pub fn hint_value(self: *Self, value: Value, player: u64) void {
        std.debug.assert(player < self.players.items.len);
        std.debug.assert(player != self.current_player);
        std.debug.assert(self.blue_tokens > 0);
        std.debug.assert(!self.game_is_over);

        self.blue_tokens -= 1;

        var did_hint = false;

        var hand = self.players.items[player].hand;

        for (hand.items) |_, i| {
            if (hand.items[i].card.value == value) {
                hand.items[i].hints.value = value;
                did_hint = true;
            }
        }

        std.debug.assert(did_hint);
    }

    pub fn to_string(self: Self, writer: anytype) void {
        var i: u64 = 0;
        if (self.rounds_left != std.math.maxInt(u64)) {
            _ = writer.print("game is over:{},rounds left:{},current player:{}\n", .{ self.game_is_over, self.rounds_left, self.current_player }) catch unreachable;
        } else {
            _ = writer.print("game is over:{},current player index:{}\n", .{ self.game_is_over, self.current_player }) catch unreachable;
        }
        while (i < self.players.items.len) : (i += 1) {
            _ = writer.print("{}:", .{i}) catch unreachable;
            self.players.items[i].to_string(writer);
            _ = writer.write("\n") catch unreachable;
        }
        for (self.hanabi_piles) |pile| {
            _ = writer.print("{} ", .{pile.items.len}) catch unreachable;
        }
        _ = writer.write("\n") catch unreachable;
        _ = writer.print("blue:{}, black:{}", .{ self.blue_tokens, self.black_tokens }) catch unreachable;
        _ = writer.write("\n") catch unreachable;
        _ = writer.write("discard pile:") catch unreachable;
        for (self.discard_pile.items) |card| {
            card.writeCard(writer);
            _ = writer.write(" ") catch unreachable;
        }
        _ = writer.write("\n") catch unreachable;

        _ = writer.write("deck:") catch unreachable;
        for (self.deck.items) |card| {
            card.writeCard(writer);
            _ = writer.write(" ") catch unreachable;
        }
        _ = writer.write("\n") catch unreachable;
    }
    pub fn simulate(self: *Self, allocator: Allocator) void {
        while (!self.game_is_over) {
            var arena = std.heap.ArenaAllocator.init(allocator);
            defer arena.deinit();
            // var arr = ArrayList(u8).init(arena.allocator());
            const stdout = std.io.getStdOut();
            const stdin = std.io.getStdIn();
            var buffer: [100]u8 = undefined;
            var writer = stdout.writer();

            const clear = "\x1B[2J\x1B[H";
            while (true) {
                _ = stdout.writer().writeAll(clear) catch unreachable;
                self.to_string(writer);
                // std.debug.print("{s}", .{arr.items});
                stdout.writer().print("0:play\n", .{}) catch unreachable;
                stdout.writer().print("1:discard\n", .{}) catch unreachable;
                stdout.writer().print("2:hint color\n", .{}) catch unreachable;
                stdout.writer().print("3:hint value\n", .{}) catch unreachable;
                stdout.writer().print("Chose an option:", .{}) catch unreachable;

                switch (readNumber(stdin.reader(), &buffer, "\nInvalid input, try selecting an option again:", 4)) {
                    0 => {
                        self.simulate_play();
                        break;
                    },
                    1 => {
                        if (self.blue_tokens == INITIAL_BLUE_TOKENS) {
                            _ = stdout.writer().write("There are too many blue tokens, so you cannot discard\n") catch unreachable;
                            std.os.nanosleep(2, 0);
                            continue;
                        }
                        self.simulate_discard(); //TODO: it needs to refuse to execute if there are max tokens
                        break;
                    },
                    2 => {
                        if (self.blue_tokens == 0) {
                            _ = stdout.writer().write("There are no blue tokens, so you cannot hint\n") catch unreachable;
                            std.os.nanosleep(2, 0);
                            continue;
                        } else {
                            self.simulate_hint_color(); //TODO: need to refuse this if no tokens
                            break;
                        }
                    },
                    3 => {
                        self.simulate_hint_value();
                        break;
                    },
                    else => unreachable,
                }
            }
            _ = self.next_turn();
        }
    }

    fn simulate_play(self: *Self) void {

        // fn play(self: *Self, index: u64) void {
        const stdout = std.io.getStdOut();
        const stdin = std.io.getStdIn();
        var buffer: [100]u8 = undefined;

        stdout.writer().print("Select a card index to play:", .{}) catch unreachable;
        var selected_card = readNumber(stdin.reader(), &buffer, "\nInvalid input, select a card index again:", self.players.items[self.current_player].hand.items.len);
        self.play(selected_card);
    }

    fn simulate_discard(self: *Self) void {

        // fn discard(self: *Self, index: u64) void {
        const stdout = std.io.getStdOut();
        const stdin = std.io.getStdIn();
        var buffer: [100]u8 = undefined;

        stdout.writer().print("Select a card to discard:", .{}) catch unreachable;
        var selected_card = readNumber(stdin.reader(), &buffer, "\nInvalid input, select a card index again:", self.players.items[self.current_player].hand.items.len);
        self.discard(selected_card);
    }

    fn simulate_hint_value(self: *Self) void {
        const stdout = std.io.getStdOut();
        const stdin = std.io.getStdIn();
        var buffer: [100]u8 = undefined;

        while (true) {
            stdout.writer().print("Select a player index:", .{}) catch unreachable;
            // std.debug.print("\nShould be 5:{}\n", .{self.players.items.len});
            var selected_player = readNumber(stdin.reader(), &buffer, "\nInvalid Input,try selecting player index again:", self.players.items.len);
            if (selected_player == self.current_player) {
                stdout.writer().print("\nCannot give a hint to yourself! Try again:", .{}) catch unreachable;
                continue;
            }
            const player = self.players.items[selected_player];
            const values = [_]Value{ Value.one, Value.two, Value.three, Value.four, Value.five };
            var valueChoices = [_]bool{false} ** values.len;
            var noneFound = true;
            for (player.hand.items) |cardwithhints| {
                for (values) |value, i| {
                    if (value == cardwithhints.card.value) {
                        valueChoices[i] = true;
                        noneFound = false;
                    }
                }
            }
            if (noneFound) {
                stdout.writer().print("There are no cards in that players hand, try again\n", .{}) catch unreachable;
                continue;
            }
            // A value will always be chosen, so no worry
            var i: u64 = 0;
            for (valueChoices) |maybe_value, k| {
                if (maybe_value) {
                    stdout.writer().print("Enter {}: pick value ", .{i}) catch unreachable;
                    values[k].writeValue(stdout.writer());
                    stdout.writer().print("\n", .{}) catch unreachable;
                    i += 1;
                }
            }
            stdout.writer().print("Pick a value:", .{}) catch unreachable;
            var chosen_value_index = readNumber(stdin.reader(), &buffer, "\nInvalid input. Try again, select a value:", i);

            var chosen_value: Value = undefined;
            i = 0;
            for (valueChoices) |maybe_value, k| {
                if (maybe_value) {
                    if (chosen_value_index == i) {
                        chosen_value = values[k];
                    }
                    i += 1;
                }
            }

            // pub fn hint_color(self: *Self, color: Color, player: u64) void
            self.hint_value(chosen_value, selected_player);
            return;
        }
    }

    fn simulate_hint_color(self: *Self) void {
        const stdout = std.io.getStdOut();
        const stdin = std.io.getStdIn();
        var buffer: [100]u8 = undefined;

        while (true) {
            stdout.writer().print("Select a player index:", .{}) catch unreachable;
            // std.debug.print("\nShould be 5:{}\n", .{self.players.items.len});
            var selected_player = readNumber(stdin.reader(), &buffer, "\nInvalid Input,try selecting player index again:", self.players.items.len);
            if (selected_player == self.current_player) {
                stdout.writer().print("Cannot give a hint to yourself! Try again\n", .{}) catch unreachable;
                continue;
            }
            const player = self.players.items[selected_player];

            const colors = [_]Color{ Color.red, Color.blue, Color.green, Color.yellow, Color.white };
            var colorChoices = [_]bool{false} ** colors.len;
            var noneFound = true;
            for (player.hand.items) |cardwithhints| {
                for (colors) |color, i| {
                    if (color == cardwithhints.card.color) {
                        colorChoices[i] = true;
                        noneFound = false;
                    }
                }
            }
            if (noneFound) {
                stdout.writer().print("There are no cards in that players hand, try again\n", .{}) catch unreachable;
                continue;
            }
            // A color will always be chosen, so no worry
            var i: u64 = 0;
            for (colorChoices) |maybe_color, k| {
                if (maybe_color) {
                    stdout.writer().print("Enter {}: pick ", .{i}) catch unreachable;
                    colors[k].writeColor(stdout.writer());
                    stdout.writer().print("\n", .{}) catch unreachable;
                    i += 1;
                }
            }
            _ = stdout.writer().print("Pick a color:", .{}) catch unreachable;
            var chosen_color_index = readNumber(stdin.reader(), &buffer, "\nInvalid input, try again select a color:", i);

            var chosen_color: Color = undefined;
            i = 0;
            for (colorChoices) |maybe_color, k| {
                if (maybe_color) {
                    if (chosen_color_index == i) {
                        chosen_color = colors[k];
                    }
                    i += 1;
                }
            }

            // pub fn hint_color(self: *Self, color: Color, player: u64) void
            self.hint_color(chosen_color, selected_player);
            return;
        }
    }

    fn readNumber(reader: anytype, buffer: []u8, try_again_message: []const u8, lowerThan: u64) u64 {
        // _ = reader;
        while (true) {
            var buf = nextLine(reader, buffer) catch {
                _ = std.io.getStdOut().writer().write(try_again_message) catch unreachable;
                continue;
            };
            if (buf) |line| {
                var number = std.fmt.parseInt(u64, line, 10) catch {
                    _ = std.io.getStdOut().writer().write(try_again_message) catch unreachable;
                    continue;
                };
                if (number >= lowerThan) {
                    _ = std.io.getStdOut().writer().write(try_again_message) catch unreachable;
                    continue;
                }
                return number;
            }
        }
        unreachable;
    }
    fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
        var line = (try reader.readUntilDelimiterOrEof(
            buffer,
            '\n',
        )) orelse return null;
        // trim annoying windows-only carriage return character
        if (@import("builtin").os.tag == .windows) {
            return std.mem.trimRight(u8, line, "\r");
        } else {
            return line;
        }
    }
};

test "print card" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var card = Card{ .color = Color.red, .value = Value.one };
    var arr = ArrayList(u8).init(arena.allocator());
    var writer = arr.writer();
    card.writeCard(writer);
    try expect(eql(u8, arr.items, "r1"));
}

test "create game and print a player hand" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var seed = [_]u8{1} ** 32;
    var game = Game.init(arena.allocator(), 5, seed);
    var arr = ArrayList(u8).init(arena.allocator());
    var writer = arr.writer();
    game.players.items[0].to_string_no_hints(writer);
    std.debug.print("=========\n{s}\n========", .{arr.items});
}

test "print game state" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var seed = [_]u8{1} ** 32;
    var game = Game.init(arena.allocator(), 5, seed);
    var arr = ArrayList(u8).init(arena.allocator());
    var writer = arr.writer();
    game.to_string(writer);
    std.debug.print("{s}", .{arr.items});
}
