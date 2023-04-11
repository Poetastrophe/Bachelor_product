# Representation of the hand
Since there are 25 different cards, each card can be represented by an integer
of size 5 bits. Which implies a hand with 4 cards is 4*5 = 25. Very compact, but
requires conversion.

On the other hand, a hand can also be represented by using an array of [25]u2,
since there are no more than 3 of each card. This representation takes 50 bits,
but might make some things easier (like generating hands without converting).
Furthermore this representation can also be used for the deck and discard pile
and hanabi pile. It trivializes some computations, like what is the pool of the
elements left? Easy you just subtract everything you know from the deck.
I like this idea a lot: simplifies code, simplifies generation. Unified format.

It has to be small format enough in order to satisfy the constraint that it
should not use too much space.
based on simulations it seems realistic to expect that an agent generates
10000*10000 in the first round. which for the big format is in MB
>>> 2*25*10000**2
5000000000
>>> _/8/10**6
625.0

Which is small!!
