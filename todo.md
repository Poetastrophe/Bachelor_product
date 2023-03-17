# Todo

[ ] - Get direction on the project
	[x] - try to read about model-checking and program verification
		It does not seem to be any easier I think, I should really try
		to read more on monday about hanabi.	
	[ ] - Play hanabi and try to get a list of some simple strategies that
	work well (see wikipedia)
	[ ] - Read chapter 5 in about modal logic and agents. Take lots of notes
	so you can make sure you understand it and can nag Nina if you get
	depressed about it again.
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









# Backlog

[ ] - rewrite the code such that it actually handles allocation failure and not just ignores it.

