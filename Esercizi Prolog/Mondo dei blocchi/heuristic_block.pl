:- module(heuristic, [length_list/2, heuristic1/3, h/2, g/2]).

length_list([], 0).
length_list([_|List], Length) :- 
	length_list(List, X),
	Length is X + 1.

heuristic1(List1, List2, Card) :- 
	ord_subtract(List1, List2, DifferenceList),
	length_list(DifferenceList, Length),
	Card is abs(Length) - 1.

h(N, Distance) :- 
	goal(G),
	heuristic1(N, G, Distance).

g(G, NewG) :- 
	NewG is G + 1.

/*
heuristic2(List1, List2, Card) :-
	list_to_ord_set(List1, OrdList1),
	list_to_ord_set(List2, OrdList2),
	find_difference(OrdList1, OrdList2, Difference),
	Card is Difference.

find_difference([], _, 0). % Caso base

find_difference([Element | List1], List2, Difference) :-
	ord_memberchk(Element, List2) -> find_difference(List1, List2, Difference);
	atom(Element) -> Diff1 is Difference + 1, find_difference(List1,List2, Diff1);
	Element == ontable(X), Element == clear(X) -> Diff1 is Difference + 1, find_difference(List1,List2, Diff1);
	Element == clear(X) -> Diff1 is Difference + 1, find_difference(List1,List2, Diff1);
	Element == ontable(X), Element \= clear(X) -> Diff1 is Difference + 2, find_difference(List1, List2, Diff1);
	Element == on(X, Z), Element \= clear(X) -> Diff1 is Difference + 2, find_difference(List1, List2, Diff1);
	Element == on(X, Z), Element == clear(X) -> Diff1 is Difference + 1, find_difference(List1, List2, Diff1).
*/