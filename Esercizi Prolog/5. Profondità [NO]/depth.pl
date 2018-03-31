% --------------------------------------------------------
% Ricerca in profondità
% --------------------------------------------------------
profondita(Soluzione):-
  iniziale(S),
  ric_prof(S,Soluzione).

ric_prof(S,[]):-finale(S).
ric_prof(S,[Azione|AltreAzioni]):-
  applicabile(Azione,S),
  trasforma(Azione,S,SNuovo),
  ric_prof(SNuovo,AltreAzioni).


% --------------------------------------------------------
% Ricerca in profondità con controllo dei cicli
% --------------------------------------------------------

profonditaControlloCicli(Soluzione):-
  iniziale(S),
  ric_prof_CC(S,[S],Soluzione).

ric_prof_CC(S,_,[]):-finale(S).
ric_prof_CC(S,Visitati,[Azione|AltreAzioni]):-
  applicabile(Azione,S),
  trasforma(Azione,S,SNuovo),
  \+member(SNuovo,Visitati),
  ric_prof_CC(SNuovo,[SNuovo|Visitati],AltreAzioni).



% --------------------------------------------------------
% Ricerca in profondità con massima profondità limitata
% (strategia non completa)
% --------------------------------------------------------

profonditaLimitata(MaxDepth,Soluzione):-
  iniziale(S),
  ric_prof_MaxDepth(S,[S],MaxDepth,Soluzione).

ric_prof_MaxDepth(S,_,_,[]):-finale(S),!.
ric_prof_MaxDepth(S,Visitati,MaxDepth,[Azione|AltreAzioni]):-
  MaxDepth>0,
  applicabile(Azione,S),
  trasforma(Azione,S,SNuovo),
  \+member(SNuovo,Visitati),
  MaxDepth1 is MaxDepth-1,
  ric_prof_MaxDepth(SNuovo,[SNuovo|Visitati],MaxDepth1,AltreAzioni).






