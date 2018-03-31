:- module(heuristic, [euclidean_distance/3, h/2, g/4]).
:- use_module(action_tube).

/*
Euristica utilizzata per il calcolo delle distanze tra due stazioni.
Il primo parametro specifica la stazione di partenza, il secondo parametro specifica la stazione di arrivo, mentre il terzo parametro restituisce la distanza calcolata nella variabile Dist.
Tutte le condizioni devono essere soddisfatte per poter calcolare la distanza euclidea, ovvero per poter esistere la testa della regola tutti i goals del corpo devono essere veri.
*/
euclidean_distance([at(F1)|_], [at(F2)|_], Distance) :-
	% Stazione(NomeStazione,CoordX,CoordY)
	% Deve esistere la stazione selezionata di partenza.
	stazione(F1, X1, Y1), 
	% Deve esistere la stazione selezionata di arrivo.
	stazione(F2, X2, Y2),
	% Calcolo la differenza di coordinata sull'asse X tra le due stazioni e l'assegno a Xdiff.
	XDifference is X1 - X2,
	% Calcolo il quadrato della differenza della coordinata sull'asse X.
	XExp is XDifference * XDifference,
	% Calcolo la differenza di coordinata sull'asse Y tra le due stazioni e l'assegno a Xdiff.
	YDifference is Y1 - Y2,
	% Calcolo il quadrato della differenza della coordinata sull'asse Y.
	YExp is YDifference * YDifference,
	% Calcolo la somma dei quadrati.
	Sum is XExp + YExp,
	% Calcolo la radice quadrata della somma dei quadrati e l'assegno alla variabile Dist
	Distance is sqrt(Sum).
	% Scrivo il risultato ottenuto.
	%writeln(Dist).
	
/*
E' la stima euristica della distanza dal nodo N (qualsiasi) al nodo finale.
Primo parametro N: stato (nodo) da cui voglio calcolare h.
Secondo parametro DistanceH: distanza.
*/
h(N, DistanceH) :- 
	finale(Node), % Deve esistere lo stato finale Node.
	euclidean_distance(N, Node, DistanceH). % Calcolo la distanza euclidea tra il nodo N e il nodo finale Node.

/*
E' la misura della distanza effettiva del cammino dal nodo A al nodo B.
Primo parametro G: è la misura della distanza effettiva non aggiornata.
Secondo parametro S1: è la stazione di partenza.
Terzo parametro S2: è la stazione di arrivo (attuale?).
Quarto parametro NewG: la nuova G calcolata.
*/
g(G, S1, S2, NewG2) :-
	euclidean_distance(S1, S2, Distance), % Calcolo la distanza euclidea tra la stazione S1 e quella S2.
	DistanceG is Distance, % Assegno la distanza eculidea calcolata a Distanza.
	NewG2 is G + DistanceG. % Aggiorno NewG sommando la vecchia G e la distanza DistanceG calcolata.

/*
F(N) = H(N) + G(N).
F(N) è il costo totale del cammino dal nodo iniziale al nodo finale attraverso il nodo N.
*/