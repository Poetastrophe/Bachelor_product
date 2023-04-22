const std = @import("std");
const Hanabi_game = @import("./hanabi_board_game.zig");
const AgentHelpers = @import("./multi_agent_solvers/agent.zig");
const Agent = AgentHelpers.Agent;
const World = AgentHelpers.World;
const Game = Hanabi_game.Game;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
pub const BytesPerGame = 400;
pub const SimulationRunner = struct {
    const Self = @This();
    agents: ArrayList(?Agent),
    game: Game,
    agent_allocator: Allocator,
    game_allocator: Allocator,
    is_first_round: bool,
    // Creates the agents, based on the state of game.
    // So the state of game indicates who starts etc.
    //Makes a deep copy so lifetime is independent of others
    pub fn init(game: Game, game_allocator: Allocator, agent_allocator: Allocator) Self {
        var res: Self = undefined;
        var agents = ArrayList(?Agent).initCapacity(agent_allocator, game.players.items.len) catch unreachable;
        for (game.players.items) |_| {
            agents.append(null) catch unreachable;
        }
        res.agents = agents;
        var buffer2: [500 * 2]u8 = undefined;
        var fba2 = std.heap.FixedBufferAllocator.init(&buffer2);
        const writer_allocator = fba2.allocator();

        {
            var string1 = game.to_string_alloc(writer_allocator);

            string1.deinit();
        }

        res.game = game.clone(game_allocator);

        {
            var string2 = res.game.to_string_alloc(writer_allocator);

            string2.deinit();
        }

        res.is_first_round = true;
        res.agent_allocator = agent_allocator;
        res.game_allocator = game_allocator;
        // TODO I should understand constness
        return res;
    }

    pub fn deinit(self: Self) void {
        for (self.agents.items) |a| {
            if (a) |agent| {
                agent.deinit();
            }
        }
        self.agents.deinit();
        self.game.deinit();
    }

    //Allocates a Game, should be cleaned up by the user
    //This way you can see an entire game list
    //if current_player has made its move, then the state moves to +1
    pub fn play_a_round(self: *Self, allocator: Allocator) Game {
        const current_player = self.game.current_player;
        var current_agent = self.agents.items[current_player];

        current_agent = Agent.init(current_player, self.game.get_current_player_view(self.agent_allocator), self.agent_allocator);
        defer current_agent.?.deinit();

        current_agent.?.make_move(&self.game);

        var totalbytesize: u64 = 0;
        totalbytesize += @sizeOf(ArrayList(ArrayList(ArrayList(World))));
        for (current_agent.?.pov_kripke_structure.worlds.items) |fixed_hand| {
            totalbytesize += @sizeOf(ArrayList(ArrayList(World)));
            for (fixed_hand.items) |player| {
                totalbytesize += @sizeOf(ArrayList(World));
                for (player.items) |_| {
                    totalbytesize += @sizeOf(World);
                }
            }
        }
        std.debug.print("\nnumber of bytes for kripkestructure is:{}\n", .{totalbytesize});

        std.debug.print("\n\n Initial time and space totalSpace in gigabytes:{}\n", .{@intToFloat(f128, totalbytesize) / 1E9});

        _ = self.game.next_turn();

        return self.game.clone(allocator);
    }
};
