

# New todo
[ ] - Implement kripke structure
	[ ] - Graph
	The graph will have outgoing and incoming edges - might in reality only need incoming edges, but hey let's see
	[ ] - Set
	A simple set datastructure, due to the uncertain natura that I might
	need to modify the graph, I cannot assume a linear dense mapping.
	If I want to do a linear dense mapping optimization, then I might want
	to make sure each graph has its own bimap of atoms and bimap of States.
	[ ] - SAT solver
	The sat solver will get an allocator that holds its calculations and an
	allocator which holds the result of the calculation. It returns an
	arraylist. In retrospect I wish I did not make a Set struct and just
	made it all arrays with the criteria that they have to be sorted, I have
	to do a lot of unpacking and repacking now.
[ ] - User friendliness and user testing
	[ ] - Make it able to read txt files with specification for states,
	edges and atoms
	[ ] - Run formulas interactively
		[ ] - First iteration, make unambigous prefix notation
		AX(EX(AND(IMPLIES(...))))
		[ ] - Second iteration, make proper logic notation for user
		friendliness.
	[ ] - Add edges interactively
	[ ] - Produce graphviz dot format files that can be made into graphs
		Can us below interactive link for it
		https://dreampuf.github.io/GraphvizOnline/#digraph%20G%20%7B%0A%0A%20%20subgraph%20%20%7B%0A%20%20%20%20style%3Dfilled%3B%0A%20%20%20%20color%3Dlightgrey%3B%0A%20%20%20%20node%20%5Bstyle%3Dfilled%2Ccolor%3Dwhite%5D%3B%0A%20%20%20%20a0%20-%3E%20a1%20-%3E%20a2%20-%3E%20a3%3B%0A%20%20%20%20label%20%3D%20%22process%20%231%22%3B%0A%20%20%7D%0A%0A%20%20subgraph%20%20%7B%0A%20%20%20%20node%20%5Bstyle%3Dfilled%5D%3B%0A%20%20%20%20b0%20-%3E%20b1%20-%3E%20b2%20-%3E%20b3%3B%0A%20%20%20%20label%20%3D%20%22process%20%232%22%3B%0A%20%20%20%20color%3Dblue%0A%20%20%7D%0A%20%20start%20-%3E%20a0%3B%0A%20%20start%20-%3E%20b0%3B%0A%20%20a1%20-%3E%20b3%3B%0A%20%20b2%20-%3E%20a3%3B%0A%20%20a3%20-%3E%20a0%3B%0A%20%20a3%20-%3E%20end%3B%0A%20%20b3%20-%3E%20end%3B%0A%0A%20%20start%20%5Bshape%3DMdiamond%5D%3B%0A%20%20end%20%5Bshape%3DMsquare%5D%3B%0A%7D
		or just install graphviz









# [OLD] To do

[ ] - Implement kripke structure representation
	Notes:
	- There needs to be hashmaps State -> int_id, and int_id -> State, the user
	should be able to name the states.
	- There needs to be hashmaps Preposition -> int_id and int_id ->
	Preposition, the user should be able to name prepositions
	- Internally, states and prepositions are just numbers
	- The graph will be represented as a arraylist representation
	[ ] - Make a bimap class, since that is what is needed
		- fromDomainToCodomain
		- fromCodomainToDomain
		no need to make it generic
	Pipeline will be 
					method
[raw text -> lexer -> parser] =	Formula ------> AdequateSetFormula [--->

simplifier ----> ROBDD eventually, maybe? ] but for now make it work with the
labelling algorithm 

Current progress:
Lige nu har jeg mange compiler errors, men jeg har gjort det godt, tak gud :)



# Plan

1. Read about the simple algorithm used to implement the input p, return {x \in M | M,x \implies
   p} query. 
2. Find a framework that does something similarly
	> Maybe SPIN but seems complicated to make comparable inputs
	> https://github.com/marcincuber/modal_logic seems good, but not an
	official framework or industry tested thing, but it does use some other
	algorithms (tableuax)
3. Benchmark it and see if you can beat it.


# The algorithm
## Key concepts: Adequate sets.
So for the modal operator \square q means roughly the same as CTL: AXq, and
diamond q means in CTL: EXq, 
Furthermore AXq can be expressed as -EX-q, and therefore it is sufficient to
only solve the problem for one of the operators.
Furthermore adequate sets of prepositional logic will just be FALSE, not, and ^.

So the algorithm will initially take the formula and translate it into the
adequate set. Then I run the algorithm on the adequate set.

QUESTION: What is most efficient EXq or AXq?

Something is labeled EXq if there is a single neighbor that is q
While state s will be labeled AXq if all its neighbours are q. So there is no
possibility of early terminations.

Then I will opt for early termination and use EXq


formula:
connectives use words such as, and, or, implies, biimplication, not, xor, EX, AX. 
As a start I will use prefix notation such as to avoid ambiguity in the parse
tree.

Jeg skal nok tjekke dette ud for at parse det...
https://craftinginterpreters.com/contents.html

Jeg skal muligvis også lave nogle interfaces


Node:
tag:
lhs:
rhs:

Question: Are there severe costs with assuming binary tree heap representation?
But of course having a simple array and specifying where the next ones lie will
fit fine.

Det er ikke et problem så længe jeg bruger arena allocator, https://zig.news/xq/cool-zig-patterns-gotta-alloc-fast-23h
https://github.com/ziglang/zig/blob/master/lib/std/heap/memory_pool.zig
Forstå forskellen mellem memory pool og arena allocator.

https://keleshev.com/abstract-syntax-tree-an-example-in-c/

## Parsing

Dette er særligt useful hvis jeg gerne vil lave en full on grammar
https://en.wikipedia.org/wiki/Recursive_descent_parser
