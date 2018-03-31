:- use_module(action_tube).
:- use_module(heuristic_tube).

% 3°.
dfs_bounded(Node, _, [], F, _, CutDepth) :- % Caso base.
	F =< CutDepth,  % Mi accerto che l'attuale F sia minore della soglia D.
	finale(Node), !. % Se il nodo non è finale si fallisce e si passa all'altra dfs_bounded.

% 4°.
dfs_bounded(Node, Visited, [Action | OtherAction], F, G, CutDepth) :-
	F =< CutDepth,
	applicabile(Action, Node), % Lista azioni possibile dal nodo Node. Cioè controllo su quale percorso si trova la stazione, la direzione e prendo le azioni possibili.
	trasforma(Action, Node, NewNode), % Esegui l'azione AZ selezionata precedentemente e raggiungi il nuovo nodo.
	\+ member(NewNode, Visited), % Controlla che il nuovo nodo non appartenga alla lista dei nodi già visitati.
	g(G, Node, NewNode, NewG), % Calcolo la distanza euclidea tra il vecchio nodo Node e il nuovo nodo NewNode. G è la vecchia distanza, NewG quella che andiamo a calcolare ora.
	h(NewNode, NewH), % Calcola la nuova euristica dall'attuale nodo raggiunto NewNode al nodo finale e lo pone in NewH.
	NewF is NewG + NewH, % Assegno a NewF la somma della NewG e NewH..
	dfs_bounded(NewNode, [Node | Visited], OtherAction, NewF, NewG, CutDepth). % Pongo il vecchio nodo nella lista dei nodi visitati (il secondo parametro). Ricerco a partire dal nuovo nodo Nuovo_S nella lista Resto.

dfs_bounded(_, _, _, F, _, CutDepth) :- % Gli unici valori che mi interessano qua sono la soglia CutDepth e l'attuale F.
	F > CutDepth, % Vero quando F supera il valore di soglia di IDA*, cioè sono andato oltre la soglia.
	update_cut_depth(F), % Aggiorno la profondità (la soglia) ad F.
	fail.

/*
Si aggiorna il valore del bound.
*/
update_cut_depth(F) :-
	f_min(Bound),
	Bound =< F, ! % Controllo che il vecchio bound sia minore. Se non lo è, proseguo. Se lo è, taglio (cut operator !) e torno a fail. Il valore bound è inizializzato a 99999.
	;
	retract(f_min(Bound)), !, % "Cancello" il vecchio valore assegnato a f_min (lower bound).
	asserta(f_min(F)). % Asserisco la nuova soglia di ricerca a F e lo assegno a f_min.

:- dynamic(f_min/1). % Affermo che il valore potrà essere modificato durante l'esecuzione dai predicati retract e asserta.
f_min(99999). % Inizializzo f_min a 99999.

% 2°.
/*
idastar_search/5.
Primo parametro: Node, nodo attuale.
Secondo parametro: PathSolution, risultato finale.
Terzo parametro: F, attuale f.
Quarto parametro: G, attuale distanza.
Quinto parametro: CutDepth, attuale soglia di ricerca.
*/
idastar_search(StartNode, PathSolution, F, G, CutDepth) :- 
	dfs_bounded(StartNode, [], PathSolution, F, G, CutDepth). % Richiamo la ricerca limitata in profondità, utilizzando il nodo attuale, una lista vuota, i nodi già trovati, l'attuale F, l'attuale G, e l'attuale soglia CutDepth.

/*
La ricerca è fallita, quindi si scende di profondità.
Resetto il bound al valore iniziale ed inizio ovamente la ricerca.
*/
idastar_search(StartNode, PathSolution, F, G, _) :-
	f_min(NewCutDepth),
	retract(f_min(NewCutDepth)), 
	asserta(f_min(99999)),
	idastar_search(StartNode, PathSolution, F, G, NewCutDepth). % Inizia la nuova ricerca con la nuova soglia NewCutDepth.

% 1°.
idastar :- 
	iniziale(Node),
	h(Node, H),
	G is 0,
	F is G + H,
	idastar_search(Node, PathSolution, F, G, F), % idastar_search(nodo_iniziale,soluzione,f,g,f).
	write(PathSolution).