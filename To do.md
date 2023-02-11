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
