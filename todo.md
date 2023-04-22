[ ] - Clean up code comments
[ ] - Time different methods based on global boolean.
	Format is:
	time.method.submethod = timespent
	
	that way it is easy to grep

[ ] - Write  
There are two augmenting strategies to the game, use Cox's recommendation strategy in order to simplify the knowledge base.
Or use use the information strategy to simplify knowledge base.

# Todo
[X] - Decide on some strategies - write them here first
Jeg kan tage Cox informations strategien og skrive en rapport at en udvidelse dertil vil være at jeg også laver disse partition tables, og ydermere kan jeg komme med meget nøjagtige estimater for den mest "playable" hånd, idet jeg generere alle muligheder.

I think that this strategy would suffice (from the Cox article regarding information strategy):

Action algorithm
A player will act using her private information with the following
priority:
1. Play the playable card with lowest index.
2. If there are less than 5 cards in the discard pile, discard the dead card with lowest
index.
3. If there are hint tokens available, give a hint.
4. Discard the dead card with lowest index.
5. If a card in the player’s hand is the same as another card in any player’s hand, i.e.,
it is a duplicate, discard that card.
6. Discard the dispensable card with lowest index.
7. Discard card C1.

Each of these actions depends on whether the agent can deduce that it truly has some knowledge so
1. Do I have a playable card and where is it?
2. Do I have a dead card and where is it?
3. - / Just hint a random card :)
	This is probably the most interesting aspect
	Because you can either simply make use of the Cox information strategy
	in addition to whatever your knowledge base gives you and that would
	probably be powerful. Where you also can infer better probability distributions due to the knowledge base structure.

	Or another interesting aspect is to use your knowledge base to see
	whether the other player already knows which cards are playable and
	discardable. In this way, if you know that there are some of their
	cards they don't know how to play, you can simply simulate each
	available hint and see which one that most simplifies they play
	options. Either that or see which hint that most simplifies their
	number of imagined hands. Either way, lots of interesting stuff
	This could also be combined with coxs information strategy. In the
	sense that if some player already know that a card is playable, then it
	is not interesting to hint about that card.

	If player A knows that player B knows that they have a playable card at position 2
	does player C know that B knows that?

	Player A would only be able to give hints properly, if it is common
	knowledge that player B position 2 card is playable.
	So I am back to, what is common knowledge?
	Otherwise the information strategy partition table would not be able to
	know which card to target. Here we of course target cards which are not
	known whether they are discardable or playable. If it is common
	knowledge that position 2 card is playable, then of course, you
	wouldn't need to hint about that
	- On the top of my head, I think I would need to extend the graph even more...
	-- A strategy would be to
		For every hand player A imagines C imagines they have
		initialdeck - world[fixed_scenario_A][A][0] - world[fixed_scenario_A][C].fixed_C - hanabi_pile - discard pile - all_hands_except_the_B_C_A_hand
		generate every hand for B and see if there is any certainty
		related to any of them. And if C is certain about any of the
		cards, lets call this set of certain cards C, then I claim that
		this set has less or equal number of certain cards to As idea
		of what B is certain about. 
		If you do this for all, and find out which they all are
		uncertain about, can this generation match all the agents idea
		of what is uncertain?
		Would probably require some tests to know for sure.
	





4. Do I have a dead card and where is it?
5. Do I have a duplicate and where is it?
6. Do I have a dispensable card and where is it?
7. OK I discard it.

I steal the categories
1. dead  (card already played)
1. alive (card not played yet)

2. indispensible (last copy that needs to be played)
2. dispensible (not last copy that needs to be played)

3. playable (immediately playable)
3. unplayable (not immediately playable)

bool alive
bool dispensible
bool playable

It should not be played if it is dead.
It should not be played if it is unplayable.
Other cases means that it is alive, but it should only be played when playable.

A card should not be discarded if it is indespensible.
A card should not be discarded if it is playable.

Given the above rules, I can try to find some booleans markers that satisfies each card.
The cards that have non-contradictory booleans will be good for taking action



in reality I don't really care about the exact details of the card, I just want to know what category it falls under, so given a hand, mark it with the designated annotations.

It is pretty trivial given a set of Cardshints
red green red1 blue
and a possible hand, just go through every permutation of the hand and see if it matches, that is make a corrospondance so
red green red1 blue
red1 green1 red1 blue5
matches but
red green red1 blue
blue1 green1 red1 blue5
does not :)
	[X] - Make converter for World into a list of cards,make sure that each player has some fixed notion of their hand.
	[X] - Each position should also have some fixed notion of alive, dispensibility, playable. And its position should be fixed so that it can be used in the game :)
	[ ] - Take a list of cards from world and iterate through all combinations thereof until you find one that matches the current hand. -> This can also be used for layer two since that if no one matches the current hand, then we just remove that :) 
		[ ] - make a test :)
		[X] - make the playable, dead etc. booleans to the hand given the game state.
		[X] - Make layer 2
			[X] - Take the heapsalgorithm and make it more general and do not use all this comptime stuff. Make it take a buffer and integer of sorts it will probably be just as fast :)

[X] - Make mini hanabi
	Motivation: without a mini version it will be hard to simulate strategies, so a mini version would be nice.
	Limitations: Should play nicely with existing methods and should not make it much harder to design.
	How mini is mini-hanabi?
	25 cards should be more than sufficient for the deck, I think
	3 1s, 2 2s, 1 3
	4 colors
	there we go
	According to python simulated_first_rounds.py we get
	
	==========    Mini hanabi!!!!!!!!!! =========
	Without looking at the other players hands state spaces
	==============================
	number of possibilities without looking at the other players hands 1007
	meta knowledge without looking at the other players hands space 1014049
	looking at the other players hands state spaces (simulated)
	number of possibilities when looking at the other players hands 36
	number of unique cards 12
	
	This is good. :)

[in progress] - Make layer 2 kripke modification taking hints into account
	kripke structure also needs to take into account the fact that some cards are hinted about.
	Trivial enough
	For player POV A. Remove all fixed scenarios for which the hints to A do not corrospond.
	Then for each of the surviving scenarios for player B, remove all the
	hands that do not corrospond to the scenarios given to B, if this
	results in the empty set, then we know that the given scenario for A is
	not possible and we remove that as well :)
	
	[X] - Think about how to incorporate hand position, because given a set for the hand, and some hints about the hand, it should be able to deduce some things and playing a partially hinted hand, should think about the consequences of doing this.
		Heapsalgorithm and see if it matches :)


[X] - Run a simulation of the first round and check if it is feasible to do anything you want to do :)
	[X] - Simulate the first round by simply giving the players cards randomly.

Performance I got with the test "initial test"

Initial time and space nanoseconds:26587755279


 Initial time and space in seconds:2.6587755279e+01


 Initial time and space totalSpace in bytes:3723631520


 Initial time and space totalSpace in gigabytes:3.72363152e+00


 With all optimizations

 Initial time and space nanoseconds:5788229502


 Initial time and space in seconds:5.788229502e+00


 Initial time and space totalSpace in bytes:4028445245


 Initial time and space totalSpace in gigabytes:4.028445245e+00


	[X] - Investigate. do the generated state spaces seem realistic? Eventually make a mini version of the hanabi deal to sanity check
		I made the three wise men test in the "Three wise men simulation :)" and it seems sane

	[X] - How slow is it with the fastest allocator you got? What if you throw out some cards and try to generate again? When is it tolerable (i.e. within a few minutes of waiting time)
	I think it is pretty tolerable with 27 seconds per agent per round
	[hold] - Does it take too much memory? If so can you compact it using the compact array strategy? Do you lose too much speed by doing so?
		This might be relevant in the future, but right now is no the future
	[hold] - check coherency of the arrays, are they nicely laid out in memory or do you hate it?
		I am not sure how to check this, and I think it is not urgent.

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

