# Idea to optimizing
# ==================
# Make sure that it does not recurse right if we already know that the maximal
# sum on the right is less than k.
# This can trivially be done by precomputing a right-sum array :)



failcount = 0
import math
import random
k = 5
length=100
evenPool=100
cards = [1,2,3,4,5]
count = [3,2,2,2,1]
allCards = []
for i in range(len(cards)):
    for k in range(count[i]):
        for color in range(5):
            allCards.append(color*10+cards[i])
# print(allCards)
# random.seed(3)
for i in range(4*4):
    allCards.pop(random.randint(0,len(allCards)-1))


# TODO: it should not be necessary to recurse all the way down :(
# This has to be fixed in next iteration. 
def combinations(taken_into_account,pool,poolmax,k,cur_id):
    global failcount

    # if(k == 0 and cur_id == len(pool)):
    #     print(taken_into_account)
    #     return

    # if(cur_id == len(pool)):
        # failcount+=1
#         print(failcount)

    if(k==0):
        # if(sum(taken_into_account) != 4):
            # print(sum(taken_into_account))
        print(taken_into_account)
        if(cur_id < len(taken_into_account)):
            taken_into_account[cur_id] = 0
        return

    take = min(pool[cur_id],k)

    for i in range(0,take+1):
       taken_into_account[cur_id] = take - i
       if(poolmax[cur_id+1] < k-(take-i)): # I should stop if what I have left
           # is less than what I want to take
           failcount+=1
           # print("failcount:",failcount,"curid",cur_id,"takeninto",taken_into_account)
           taken_into_account[cur_id] = 0
           return
       combinations(taken_into_account,pool,poolmax,k-(take-i),cur_id+1)

    # TODO test
    taken_into_account[cur_id] = 0


def distinct_combinations(elements,choose_k):
    elements.sort()
    # print(elements)
    # print(len(elements))
    
    subsequentarr = []
    counter = 0
    # creates subsequentarr for elements
    for i in range(1,len(elements)):
        if elements[i] == elements[i-1]:
            counter+=1
        elif elements[i] != elements[i-1]:
            subsequentarr.append(counter+1)
            counter = 0

    n = len(elements)
    if(elements[n-1] != elements[n-2]):
        subsequentarr.append(1)
    # print("subse",subsequentarr)
            

    # print(subsequentarr)

    poolmax = [0]*(len(subsequentarr)+1)
    # creates poolmax arr
    for i in range(len(subsequentarr)):
        n = len(subsequentarr)
        poolmax[n-1-i] = poolmax[n-i] + subsequentarr[n-1-i]
    # print(poolmax)


    combinations([0]*len(subsequentarr),subsequentarr,poolmax,choose_k,0)











distinct_combinations(allCards,4)

# distinct_combinations([ 5, 1, 1, 2, 3, 5 ],3)

