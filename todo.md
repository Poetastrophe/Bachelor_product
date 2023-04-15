

# Todo
[ ] - Run a simulation of the first round and check if it is feasible to do anything you want to do :)
	[ ] - Simulate the first round by simply giving the players cards randomly.
	[ ] - Investigate. do the generated state spaces seem realistic? Eventually make a mini version of the hanabi deal to sanity check
	[ ] - How slow is it with the fastest allocator you got? What if you throw out some cards and try to generate again? When is it tolerable (i.e. within a few minutes of waiting time)
	[ ] - Does it take too much memory? If so can you compact it using the compact array strategy? Do you lose too much speed by doing so?
	[ ] - check coherency of the arrays, are they nicely laid out in memory or do you hate it?

[x] - Implement hanabi game as a TUI and test it
	[x] - Interface
	I think it would be cool if the players used sockets and respected the
	interface, that way I know that it could not go wrong.
	WONT DO: sockets, networking is a nightmare and not interesting.
		hint_color(color, player) list of indices
		hint_value(value, player) list of indices
		discard(index) void!IllegalMove IndexOutOfBounds
		play(index) void!IndexOutOfBounds
		get_state() //returns whose turn it is, what are discarded, what
		is shown. Or if the game is over.
	struct{ 
		Players: list of hands
		current_player: index
		deck: list of cards
		discard_pile: list of cards
		hanabi_piles: list of cards
		blue_tokens: count
		black_tokens: count
	}

		


[x] - meeting with Nina
[x] - I feel like I recently began to understand how to use epistemic dynamic logic
for real. So if you want to give someone a first book on the topic, I suggest
Huth, Ryan and not 100 lightbulbs.
I was much in doubt whether I even could model it, the main reason being that
I was very overwhelmed by the notation of 100 lightbulbs.

[x] - I think I can begin to make some interesting code soon, but I have not written
anything new since we last met, due to finding it hard to find a problem, and
being very much in doubt how to engineer the logic to suit the domain.

[x] - Let's look at the example of the three wise men.

Is it correctly undestood that each island for a player, represents possibilites
depending on their knowledge?

It seems infeasible to me to use a strict logical language for hanabi, but I can
still use the principles of kripke structures on a more general state, like the
set of cards and the hands. Right?

I need to design the model sanely, without it being too much of a combinatorial
explosion.
For instance for 5 players, the 5th player knows all the other players hands nad
we get
	sage: 44*43*42*41 
		3258024 
combinations for their own hand (upper bound).
Then for each such hand, we have a set of deck, set of hand, set of discard
pile.

This would be how I model a state.

[x] - Strategy
So when I have modelled knowledge and make the agents deduce knowledge, my next
step is to make a strategy for actually playing the game.
A: see pseudocode arc

[x] - better upper bound for number of hands in the beginning

With no assumption about the first hand, there are this many possibilities.
>>> superarr = []
>>> for i in range(5):
...     for elem in arr:
...             superarr.append(elem+10*i)
>>> megaarr = list(more_itertools.distinct_combinations(superarr,4))
>>> len(megaarr)
18480
>>> len(megaarr)**2
341510400

[ ] - even better upper bound than the 18480, because there is also the
knowledge aspect.
	[ ] - simulate a couple of first rounds and see how many hands there is
	generated.



[ ] - Get direction on the project
	[x] - try to read about model-checking and program verification
		It does not seem to be any easier I think, I should really try
		to read more on monday about hanabi.	
	[ ] - Play hanabi and try to get a list of some simple strategies that
	work well (see wikipedia)
		I checked out hanabi, simple thoughts:
		You can give two types of information to a player. number of
		color/value and at what position these are found.
		Q: Can you play a card without knowing what it is in hanabi?
		A: yes men hvis den ikke bidrager til noget så mister man en
		fuse.
		Q: Is it feasible to generate every world. Where a world is the
		following:
		deck: set of cards
		h1: set of cards
		h2: set of cards
		.
		.
		.
		hn: set of cards
		discard pile: set of cards

		When should you update your model:
		The agent whose card is getting announced should update its
		model accordingly

		Everyone should update their model when a card is discarded.

		There can also be additional information, for instance, if there
		is a logical order to how people discard for instance. Lets say
		if a person has two ones, then if she discards the card instead
		of playing it, it would stand to reason that that person has
		another 1. If this was an agreed approach.
		I should find a better example but you get it.

		Better example: if someone does not continue a given firework,
		but from another players perspective is able to do so, then we
		know that that person does not know. So if this is
		an agreed strategy, then we can deduce that  in configuration:
		g r y w
		g r y
		  r
		that the player does not know that they have a blue1, or a
		yellow3 etc.

		How would I generate it:
		Look at your teammates hands and discard pile, as well as what
		you know about your own hand, and remove those
		cards from the deck. Then for each possible combination make a
		hand-deck relation as an internal model.


		Hvis man har 5 spillere, så kan man godt gå kombinatorisk til
		værks hvis man kun betragter sin egen hånd og ikke dækket, som
		vist forneden

		Konfiguration for 5 spillere:
		hånd
		====
		sage: 44*43*42*41 
		3258024 
		deck
		====
		sage: factorial(40) 
		815915283247897734345611269596115894272000000000 

		konfiguration for 2 spillere:
		hånd
		====
		sage: 55*54*53*52*51 
		417451320 
		deck
		====
		sage: factorial(50) 
		30414093201713378043612608166064768844377641568960512000000000000 
		
		
		Så statespacet er cirka 100 gange større hvis det er to spillere
		heheeeeeeeee.
		 men vi har ikke taget højde for distinguishability.



Strategy: Using natural deduction, check if your teammate knows that he can
further any of the rows.

	[ ] - Read chapter 5 in about modal logic and agents. Take lots of notes
	so you can make sure you understand it and can nag Nina if you get
	depressed about it again.
		Ideas how to model it
		since we are dealing with equivalence classes, maybe we can have
		a disjoint set data structure, where each agent has a set of
		nodes that views as equivalent?
	[ ] - How would you model it without any code?
	[ ] - Simple implementation of EDL agents (EDL-solution)
	[ ] - Benchmark against a simple implementation of hanabi
	(brainlet-solution), from a simple
	strategy
	[ ] - Can you scale the problem as to make optimizations interesting?
	Such that ideally it becomes unfeasible by a brainlet-solution and
	feasible with a decent score for a EDL-solution.

[x] - Implement kripke structure - done, interactivity not needed
	[X] - Graph
	The graph will have outgoing and incoming edges - might in reality only need incoming edges, but hey let's see
	[X] - Set
	A simple set datastructure, due to the uncertain natura that I might
	need to modify the graph, I cannot assume a linear dense mapping.
	If I want to do a linear dense mapping optimization, then I might want
	to make sure each graph has its own bimap of atoms and bimap of States.
	Initially there will be no bimap
	[X] - SAT solver
	The sat solver will get an allocator that holds its calculations and an
	allocator which holds the result of the calculation. It returns an
	arraylist. In retrospect I wish I did not make a Set struct and just
	made it all arrays with the criteria that they have to be sorted, I have
	to do a lot of unpacking and repacking now.
		[ ] - Make it able to read txt files with specification for states,
	edges and atoms
	// Not necessary
	[!] - Run formulas interactively
		[!] - First iteration, make unambigous prefix notation
		AX(EX(AND(IMPLIES(...))))
			[x] - Make zig able to parse string into adequate formula
			[!] - make it run interactively
		Second iteration, make proper logic notation for user
		friendliness.

[ ] - User friendliness and user testing
	[ ] - Add edges interactively
	[ ] - Produce graphviz dot format files that can be made into graphs
		Can us below interactive link for it
		https://dreampuf.github.io/GraphvizOnline/#digraph%20G%20%7B%0A%0A%20%20subgraph%20%20%7B%0A%20%20%20%20style%3Dfilled%3B%0A%20%20%20%20color%3Dlightgrey%3B%0A%20%20%20%20node%20%5Bstyle%3Dfilled%2Ccolor%3Dwhite%5D%3B%0A%20%20%20%20a0%20-%3E%20a1%20-%3E%20a2%20-%3E%20a3%3B%0A%20%20%20%20label%20%3D%20%22process%20%231%22%3B%0A%20%20%7D%0A%0A%20%20subgraph%20%20%7B%0A%20%20%20%20node%20%5Bstyle%3Dfilled%5D%3B%0A%20%20%20%20b0%20-%3E%20b1%20-%3E%20b2%20-%3E%20b3%3B%0A%20%20%20%20label%20%3D%20%22process%20%232%22%3B%0A%20%20%20%20color%3Dblue%0A%20%20%7D%0A%20%20start%20-%3E%20a0%3B%0A%20%20start%20-%3E%20b0%3B%0A%20%20a1%20-%3E%20b3%3B%0A%20%20b2%20-%3E%20a3%3B%0A%20%20a3%20-%3E%20a0%3B%0A%20%20a3%20-%3E%20end%3B%0A%20%20b3%20-%3E%20end%3B%0A%0A%20%20start%20%5Bshape%3DMdiamond%5D%3B%0A%20%20end%20%5Bshape%3DMsquare%5D%3B%0A%7D
		or just install graphviz








# Questions
Q: How do I model the three wise men problem as a graph, and do computations on
the graph? Is it even possible? Check out one hundred lightbulbs.

Q: interesting to look into baltag2002 and see if there is anything that can be
used.

# Backlog

[ ] - rewrite the code such that it actually handles allocation failure and not just ignores it.

