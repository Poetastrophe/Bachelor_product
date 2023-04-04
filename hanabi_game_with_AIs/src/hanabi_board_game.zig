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
const Color = enum { red, blue, green, yellow, white, unknown };
const Value = enum { one, two, three, four, five, unknown };
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
};

const CurrentPlayerView = struct {
    const Self = @This();
    players: ArrayList(Player),
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
            .discard_pile = discard_pile,
            .hanabi_piles = hanabi_piles,
            .current_player = game.current_player,
            .blue_tokens = game.blue_tokens,
            .black_tokens = game.black_tokens,
            .game_is_over = game.game_is_over,
            .rounds_left = game.rounds_left,
        };
    }
};

const Game = struct {
    const Self = @This();
    current_player: u64,
    players: ArrayList(Player),
    discard_pile: ArrayList(Card),
    hanabi_piles: [NUMBER_HANABI_PILES]ArrayList(Card),
    deck: ArrayList(Card),
    blue_tokens: u64,
    black_tokens: u64,
    game_is_over: bool,
    rounds_left: i64,

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
            .discard_pile = discard_pile,
            .hanabi_piles = hanabi_piles,
            .blue_tokens = INITIAL_BLUE_TOKENS,
            .black_tokens = INITIAL_BLACK_TOKENS,
            .game_is_over = false,
            .rounds_left = -1,
        };
    }

    pub fn get_current_player_view(self: Self, allocator: Allocator) CurrentPlayerView {
        return CurrentPlayerView.init(allocator, self);
    }

    fn next_turn(self: *Self) u64 {
        self.current_player = (self.current_player + 1) % self.players.items.len;
        return self.current_player;
    }

    fn discard(self: *Self, index: u64) void {
        std.debug.assert(index < self.players[self.current_player].items.len);
        std.debug.assert(self.blue_tokens < INITIAL_BLUE_TOKENS);
        std.debug.assert(!self.game_is_over);
        self.discard_pile.append(self.players[self.current_player].items[index]);
        _ = self.draw_card_or_remove_at(index);
        self.blue_tokens += 1;
    }

    fn draw_card_or_remove_at(self: *Self, index: u64) ?CardWithHints {
        var maybe_new_card = self.deck.popOrNull();
        if (maybe_new_card) |new_card| {
            self.players[self.current_player].items[index] = new_card;
            return new_card;
        } else {
            if (self.rounds_left == -1) {
                self.rounds_left = self.players.len;
            } else {
                self.rounds_left -= 1;
            }
            if (self.rounds_left == 0) {
                self.game_is_over = true;
            }
            self.players[self.current_player].swap_remove(index);
            return null;
        }
    }

    fn play(self: *Self, index: u64) void {
        std.debug.assert(index < self.players[self.current_player].items.len);
        std.debug.assert(self.blue_tokens < INITIAL_BLUE_TOKENS);
        std.debug.assert(!self.game_is_over);
        var old_card = self.players[self.current_player].items[index];
        _ = self.draw_card_or_remove_at(index);

        var last_index = self.hanabi_piles[@enumToInt(old_card.color)].items.len;

        if (last_index == @enumToInt(old_card.value)) {
            self.hanabi_piles[@enumToInt(old_card.color)].items.append(old_card);
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

        var hand = self.players.items[player].items;

        for (hand) |_, i| {
            if (hand[i].color == color) {
                hand[i].hint.color = color;
                did_hint = true;
            }
        }

        std.debug.assert(!did_hint);
    }

    pub fn hint_value(self: *Self, value: Value, player: u64) void {
        std.debug.assert(player < self.players.items.len);
        std.debug.assert(player != self.current_player);
        std.debug.assert(self.blue_tokens > 0);
        std.debug.assert(!self.game_is_over);

        self.blue_tokens -= 1;

        var did_hint = false;

        var hand = self.players.items[player].items;

        for (hand) |_, i| {
            if (hand[i].value == value) {
                hand[i].hint.value = value;
                did_hint = true;
            }
        }

        std.debug.assert(!did_hint);
    }

    pub fn to_string(self: Self, writer: anytype) void {
        var i: u64 = 0;
        _ = writer.print("game is over:{},rounds left:{},current player:{}\n", .{ self.game_is_over, self.rounds_left, self.current_player }) catch unreachable;
        while (i < self.players.items.len) : (i += 1) {
            _ = writer.print("{}:", .{i}) catch unreachable;
            self.players.items[i].to_string_no_hints(writer);
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
            var writer = stdout.writer();
            self.to_string(writer);
            // std.debug.print("{s}", .{arr.items});

            std.debug.print("1:play");
            std.debug.print("2:discard");
            std.debug.print("3:hint color");
            std.debug.print("4:hint value");
            const stdin = std.io.getStdIn();
            var buffer: [100]u8 = undefined;
            var input = (try nextLine(stdin.reader(), &buffer)).?;
            _ = input;
            // if (eql(u8, input, "1")) {
            // input = (try nextLine(stdin.reader(), &buffer)).?;
            // if(
            // }
        }
    }
    fn readNumber(reader: anytype, buffer: []u8, lowerThan: u64) u64 {
        // _ = reader;
        _ = lowerThan;
        while (true) {
            var buf = nextLine(reader, buffer) catch {
                std.io.getStdOut().writer().write("try again\n");
                continue;
            };
            buf 
        }
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
