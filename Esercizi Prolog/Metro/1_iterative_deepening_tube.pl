:- use_module(action_tube).

% 3°.
/*
Caso base ricorsione.
Primo parametro: nodo Node attuale.
Secondo parametro: qualsiasi profondità.
Terzo parametro: qualsiasi lista di nodi visitati.
Quarto parametro: lista azioni vuota.
*/
dfs_bounded(Node, _, _, []) :-
	finale(Node), !. % Il nodo finale è quello finale, allora cut e finisco.

% 4°.
/*
Caso generale della ricorsione.
Primo parametro: Node, nodo attuale.
Secondo parametro: MaxDepth,limite di profodità.
Terzo parametro: Visited, lista dei nodi visitati.
Quarto parametro: Action | OtherAction, lista delle azioni possibili.
*/
dfs_bounded(Node, MaxDepth, Visited, [Action | OtherAction]) :-
	MaxDepth > 0, % Controllo se posso continuare con la ricorsione (se il parametro di profondità me lo consente).
	applicabile(Action, Node), % Cerco le azioni possibili dal nodo Node.
	trasforma(Action, Node, NewNode), % Espando dal vecchio nodo Node  al nuovo nodo NewNode con l'azione Action.
	\+ member(NewNode, Visited), % Controllo che il nuovo nodo NewNode non sia già stato visitato.
	NewMaxDepth is MaxDepth - 1, % Aggiorno il limite di profondità MaxDepth riducendolo di 1 e lo assegno a NewMaxDepth.
	dfs_bounded(NewNode, NewMaxDepth, [Node | Visited], OtherAction). % Continuo la ricerca, con il nuovo nodo NewNode, la nuova profondità NewMaxDepth, la lista dei nodi visitati [ Node | Visited] e il resto delle azioni OtherAction.

% 2°.
iterative_deepening_search(StartNode, MaxDepth, PathSolution) :-
	dfs_bounded(StartNode, MaxDepth, [], PathSolution).

iterative_deepening_search(StartNode, MaxDepth, PathSolution) :-
	NewMaxDepth is MaxDepth + 1, % Aumento la profondità della ricerca perché ancora non ho trovato la soluzione.
	iterative_deepening_search(StartNode, NewMaxDepth, PathSolution). % Richiamo la ricerca con la nuova profondità D1.

% 1°.
iterative_deepening(LimitedDepth) :-
	iniziale(StartNode), % Prendo il nodo iniziale.
	iterative_deepening_search(StartNode, 1, PathSolution), % Richiamo la funzione di ricerca con profondità 1.
	write(PathSolution). % Scrivo il percorso trovato.