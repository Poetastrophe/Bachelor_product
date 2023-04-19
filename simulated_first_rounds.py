import more_itertools
print("Without looking at the other players hands state spaces")
print("==============================")
arr = [1,1,1,2,2,3,3,4,4,5]
superarr = []
for i in range(5):
    for elem in arr:
            superarr.append(elem+10*i)
megaarr = list(more_itertools.distinct_combinations(superarr,4))
print("number of possibilities without looking at the other players hands",len(megaarr))
print("meta knowledge without looking at the other players hands space",len(megaarr)**2)

print("looking at the other players hands state spaces (simulated)")
arr = [1,1,1,2,2,3,3,4,4,5]
superarr = []
for i in range(5):
    for elem in arr:
            superarr.append(elem+10*i)
import random
superarr2=superarr.copy()
for _ in range(4*4):
    toRemove = random.randint(0,len(superarr2)-1)
    superarr2.pop(toRemove)

megaarr = list(more_itertools.distinct_combinations(superarr2,4))
print("number of possibilities when looking at the other players hands",len(megaarr))




arr = [1,2,3,4,5]
superarr = []
for i in range(5):
    for elem in arr:
            superarr.append(elem+10*i)

print("number of unique cards",len(superarr))
# so five bits per card
print(2**5-1)
# That gives a initial state space of
# 5*5*5 = 125 bits per state
# If the entire deck is also in it, then we have
# 60*5 = 300 bits per state


print("==========    Mini hanabi!!!!!!!!!! =========")
print("Without looking at the other players hands state spaces")
print("==============================")
colors = 4
arr = [1,1,1,2,2,3]
superarr = []
for i in range(colors):
    for elem in arr:
            superarr.append(elem+10*i)
megaarr = list(more_itertools.distinct_combinations(superarr,4))
print("number of possibilities without looking at the other players hands",len(megaarr))
print("meta knowledge without looking at the other players hands space",len(megaarr)**2)

print("looking at the other players hands state spaces (simulated)")
arr = [1,1,1,2,2,3]
superarr = []
for i in range(colors):
    for elem in arr:
            superarr.append(elem+10*i)
import random
superarr2=superarr.copy()
for _ in range(4*4):
    toRemove = random.randint(0,len(superarr2)-1)
    superarr2.pop(toRemove)

megaarr = list(more_itertools.distinct_combinations(superarr2,4))
print("number of possibilities when looking at the other players hands",len(megaarr))




arr = [1,2,3]
superarr = []
for i in range(colors):
    for elem in arr:
            superarr.append(elem+10*i)

print("number of unique cards",len(superarr))
# so five bits per card
# That gives a initial state space of
# 5*5*5 = 125 bits per state
# If the entire deck is also in it, then we have
# 60*5 = 300 bits per state
