:- use_module(action_block).
:- use_module(heuristic_block).
:- use_module(configuration_1_block).
%:- use_module(configuration_2_block).

/*
**nodo:
	1. F, costo totale dal nodo iniziale al nodo finale.
	2. G, misura della distanza effettiva.
	3. Node, stato (nodo) attuale.
	4. ActionsAvailable, lista della azioni possibili a partire da quel nodo (scendi, sali, vai).

** astar_search:
	1. Stato (nodo) attuale.
	2. CloseNodes, lista dei nodi chiusi.
	3. PathSolution, soluzione trovata (oppure ActionAvailable, con la lista delle azioni possibili da quel nodo).

** espandi:
	1. Lo stato (nodo) attuale.
	2. NextNodes, con la lista dei nodi successivi.

** successori:
	1. Lo stato (nodo) attuale.
	2. [Action|OtherActions], la lista con le azioni possibili da quel nodo, dove action è l'azione in testa, e nella coda OtherActions le restanti azioni successive.
	3. Successors, una lista dei nodi connessi al nodo attuale.
*/

/*
Se il PRIMO PARAMETRO nodo è una lista con in testa:
 - F qualsiasi;
 - G, qualsiasi;
 - S, stato attuale;
 - ActionsAvailable, lista;
e in coda:
- qualsiasi;
 Se il SECONDO PARAMETRO lista è:
 - qualsiasi;
 Se il TERZO PARAMETRO lista è:
 - ActionsAvailable,
*/

% astar_search/3.
astar_search([nodo(_, _, Node, ActionsAvailable)| _], _, ActionsAvailable) :-
	finale(Node). % Caso base della ricerca.

astar_search([nodo(F, G, Node, ActionsAvailable) | OtherActions], CloseNodes, PathSolution) :-
	member(Node, CloseNodes) -> astar_search(OtherActions, CloseNodes, PathSolution); % Se il nodo attuale fa parte della lista CloseNodes, allora ho terminato su quel ramo perché totalmente espanso. Richiamo astar con il resto dei nodi.
	expand(nodo(F, G, Node, ActionsAvailable), NextNodes), % Se il nodo attuale non fa parte della lista CloseNodes (quindi è un nodo aperto), lo espando.
	ord_union(OtherActions, NextNodes, Tail), % Unione della lista OtherActions e NextNodes nella lista Tail.
	astar_search(Tail, [Node | CloseNodes], PathSolution). %

% espandi/2.
expand(nodo(F, G, Node, ActionsAvailable), NextNodes) :-
	findall(Action, applicabile(Action, Node), ListActions), % Produce una lista di ListActions di tutti gli oggetti Action che soddisfano il goal applicabile(Action,Node). Quindi in sostanza cerco tutte le azioni possibili dal nodo attuale (?).
	successor(nodo(F, G, Node, ActionsAvailable), ListActions, NextNodes). % Cerco i successori del nodo attuale in NextNodes, con tutte le azioni prima individuate in ListActions.

% successori/3.
successor(_, [], []).
successor(nodo(F, G, Node, ActionsAvailable), [Action | OtherActions], Successors) :-
	trasforma(Action, Node, NewNode), % Applicando una della azioni (quella in testa alla lista ListActions = [Action|OtherActions]) alla stato (nodo) attuale Node si ottiene il nuovo stato (nodo) NewNode.
	append(ActionsAvailable, [Action], NewActionAvailable), % Si concatena la lista ActionAvailable con la lista Action nella lista NewActionAvailable.
	successor(nodo(F, G, Node, ActionsAvailable), OtherActions, OtherNodes), % Dal nodo attuale, con le restanti azioni da fare OtherActions sui nodi successivi OtherNodes.
	g(G, NewG), % Calcolo la distanza effettiva tra lo stato (nodo) Node e NewNode, specificando che il costo non aggiornato è G e quello nuovo NewG.
	h(NewNode, NewH), % Calcolo la stima euristica della distanza con NewS e NewH.
	NewF is NewG + NewH, % Effettuo la somma tra NewG e NewH e inserisci il risultato in NewF.
	ord_add_element(OtherNodes, nodo(NewF, NewG, NewNode, NewActionAvailable), Successors). % Aggiungi nodo nella lista OtherNodes e inserisci tutto nella lista Successors.

astar :-
	iniziale(Node), % Stato iniziale (nodo iniziale) da cui inizia la ricerca.
	h(Node, H), % Stima euristica dal nodo iniziale al nodo finale, inserendo il risultato in H.
	G is 0, % Inizializzazione di G a 0.
	F is G + H, % Inizializzazione di F a G + H. Inizialmente G vale 0 e H è calcolata due righe sopra.
	astar_search([nodo(F, G, Node, [])], [], PathSolution), % Inizia la ricerca con astar_search.
	write(PathSolution). % Scrivi la soluzione trovata.

:- set_prolog_stack(global, limit(100 000 000 000)).
