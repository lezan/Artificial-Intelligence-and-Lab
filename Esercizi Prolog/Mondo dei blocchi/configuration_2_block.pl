:- module(configuration, [iniziale/1, goal/1, finale/1, block/1]).

block(a).
block(b).
block(c).
block(d).

iniziale(S) :-
	list_to_ord_set([clear(a), clear(c), clear(d), on(a,b), ontable(b), ontable(c), ontable(d), handempty], S).

goal(G) :- 
	list_to_ord_set([on(a,b), on(b,c), on(c,d), ontable(d)], G).

finale(S) :- 
	goal(G),
	ord_subset(G,S).