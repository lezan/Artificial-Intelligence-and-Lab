#include <incmode>.

#program base.

cargo(c1; c2).

plane(p1; p2).

airport(jfk; sfo).

init(at(c1,sfo)). % il cargo c1 è nell'aereoporto sfo.
init(at(c2,jfk)). % il cargo c2 è nell'aereoporto jfk.
init(at(p1,sfo)). % l'aereo p1 è nell'aereoporto sfo.
init(at(p2,jfk)). % l'aereo p2 è nell'aereoporto jfk.

goal(at(c1,jfk)). % il cargo c1 è nell'aereoporto jfk.
goal(at(c2,sfo)). % il cargo c2 è nell'aereporto sfo.

holds(F, 0) :- init(F).

#program step(t).

1 { load(C, P, A, t): cargo(C), plane(P), airport(A); unload(C, P, A, t): cargo(C), plane(P), airport(A); fly(P, FROM, TO, t): plane(P), airport(FROM), airport(TO), FROM != TO} 1.

holds(F, t) :- holds(F, t - 1), not -holds(F, t).
-holds(F, t) :- -holds(F, t - 1), not holds(F, t).

% Azione Load.
% Se effettuo una azione di load di un cargo sull'aereoplano, il cargo P si troverà sull'aereo P.
holds(in(C, P), t) :- cargo(C), plane(P), load(C, P, A, t).
-holds(at(C, A), t) :- cargo(C), airport(A), load(C, P, A, t).

% Azione Unload.
% 
holds(at(C, A), t) :- cargo(C), airport(A), unload(C, P, A, t).
-holds(in(C, P), t) :- cargo(C), plane(P), unload(C, P, A, t).

% Azione Fly.
% 
holds(at(P, TO), t) :- fly(P, FROM, TO, t).
-holds(at(P, FROM), t) :- fly(P, FROM, TO, t).

% Constraints su load.
% Escludo l'azione di load al tempo t se il cargo C si trova nell'aereoporto A1 al tempo t - 1 e l'aereo P si trova nell'aereoporto A2 e A1 è diverso da A2.
:- load(C, P, A, t), holds(at(C, A1), t - 1), holds(at(P, A2), t - 1), A1 != A2.
% Escludo l'azione di load al tempo t se il cargo C non si trova nello stesso aereoporto dell'aereo P.
:- load(C, P, A, t), holds(at(C, A1), t - 1), A != A1.
% Escludo l'azione di load al tempo t se l'aereo P non si trova nello stesso aereoporto del cargo C.
:- load(C, P, A, t), holds(at(P, A2), t - 1), A != A2.
% Escludo l'azione di load al tempo t se ho già caricato al tempo t - 1 senza aver prima scaricato.
:- load(C, P, A, t), holds(in(_, P), t - 1).
% Escludo l'azione di load al tempo t se al tempo t - 1 ho caricato lo stesso cargo.
:- load(C, P, A, t), holds(in(C, _), t - 1).

% Constraints su unload.
% Escludo l'azione di unload se l'aereo P non si trova nell'aereoporto A.
:- unload(C, P, A, t), not holds(at(P, A), t - 1).
% Escludo l'azione di unload se il cargo C non è un su P.
:- unload(C, P, A, t), not holds(in(C, P), t - 1).

% Constraints su fly.
% Se l'aereo P non si trova nell'aereoporto FROM, allora non può volare dall'aereoporto FROM all'aereoporto TO.
:- fly(P, FROM, TO, t), not holds(at(P, FROM), t - 1).

#program check(t).

:- query(t), goal(F), not holds(F, t).

%% OUTPUT

#show load/4.
#show fly/4.
#show unload/4.