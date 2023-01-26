# True/False
## Task 6.1

TRUE: In Kruskals alg, the safe aedge that is added is always a least weighhht aedge, so the negative wight edges will not affect the evolution of the tree.

## Task 6.2

TRUE: you can do this by negating the weights and then applying kruskals algorithm, this should still give you thhe same computation as using the regular weights of a maximum spanding tree

## Task 6.3
FALSE: A connnected graph could just be a linked list, in which case you can add the heaviest weighted edge.

# DFS
## Task 7.1

abmhxc

abmxhc

amxhbc

amhxbc


# Heaps
## Task 8.1

since the time complexity of percolate up and percolate down is O(log N), and we each calling them n times, then the overall time complexity of this algorithim ends up being O(n * log n) which ends up being O(nlog n)

# Dijkstra's
## Task 9.1

YOUR ANSWER BELOW

|Step| States Visited So Far                    | Priority Queue |
| -- | :-------------------:                    | :------------: |
| 0  |           N/A                            |  (0, s)        |
| 1  | (0, s)                                   |  (1,a,2,b,3,c) |
| 2  | (0 s, 1 a)                               |  (2 b,3 c,4 f) |
| 3  | (0 s, 1 a, 2 b)                          |  (3 c,4 f,3 e) |
| 4  | (0 s, 1 a, 2 b, 3 c)                     |     (4 f,3 e)  |
| 5  | ( 0 s, 1 a, 2 b, 3 c, 3 e)               |      (4,f)     |
| 6  | ( 0 s, 1 a, 2 b, 3 c, 3 e, 4 f)          |     (6,h,10,g) |
| 7  | (0 s, 1 a, 2 b, 3 c, 3 e, 4 f, 6 h)      |     (9,g)      |
| 8  | (0 s, 1 a, 2 b, 3 c, 3 e, 4 f, 6 h, 9 g) |                |
| 9  |                                          |                |
| 10 |                                          |                |
| 11 |                                          |                |
| 12 |                                          |                |
