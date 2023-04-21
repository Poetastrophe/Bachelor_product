const std = @import("std");
const Hanabi_game = @import("./hanabi_board_game.zig");
const AgentHelpers = @import("../multi_agent_solvers/src/agent.zig");
const Agent = AgentHelpers.Agent;
const Game = Hanabi_game.Game;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
pub const BytesPerGame = 400;
pub const SimulationRunner = struct {
    const Self = @This();
    agents: ArrayList(Agent),
    game: Game,
    agent_allocator: Allocator,
    game_allocator: Allocator,
    is_first_round: bool,
    // Creates the agents, based on the state of game.
    // So the state of game indicates who starts etc.
    //Makes a deep copy so lifetime is independent of others
    pub fn init(game: Game, game_allocator: Allocator, agent_allocator: Allocator) Self {
        var res: Self = undefined;
        var agents = ArrayList(Agent).initCapacity(agent_allocator, Game.players.items.len);
        for (game.players.items.len) |_| {
            agents.append(undefined);
        }
        res.agents = agents;
        res.game = game.clone(game_allocator);
        res.is_first_round = true;
        // TODO I should understand constness
    }
    pub fn deinit(self: *Self) void {
        for (self.agents.items) |a| {
            a.deinit();
        }
        self.game.deinit();
    }

    //Allocates a Game, should be cleaned up by the user
    //This way you can see an entire game list
    //if current_player has made its move, then the state moves to +1
    pub fn play_a_round(self: *Self, allocator: Allocator) Game {
        const current_player = self.game.current_player;
        var current_agent = self.agents.items[current_player];
        if (!self.is_first_round) {
            current_agent.deinit();
        } else {
            self.is_first_round = false;
        }

        var buffer: [BytesPerGame]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buffer);
        const fba_allocator = fba.allocator();
        current_agent = Agent.init(current_player, self.game.get_current_player_view(fba_allocator), self.agent_allocator);

        current_agent.make_a_move(&self.game);

        self.game.next_turn();

        return self.game.clone(allocator);
    }
};
