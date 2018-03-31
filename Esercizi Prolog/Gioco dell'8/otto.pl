applicabile(est,Stato):-
  nth(Stato,PosVuoto,vuoto),
  \+bordosinistro(PosVuoto).
applicabile(ovest,Stato):-
  nth(Stato,PosVuoto,vuoto),
  \+bordodestro(PosVuoto).
applicabile(nord,Stato):-
  nth(Stato,PosVuoto,vuoto),
  \+bordoinferiore(PosVuoto).
applicabile(sud,Stato):-
  nth(Stato,PosVuoto,vuoto),
  \+bordosuperiore(PosVuoto).

trasforma(sud,Stato,NuovoStato):-
  nth(Stato,PosVuoto,vuoto),
  PosTessera is PosVuoto-3,
  swap(Stato,PosVuoto,PosTessera,NuovoStato).
trasforma(ovest,Stato,NuovoStato):-
  nth(Stato,PosVuoto,vuoto),
  PosTessera is PosVuoto+1,
  swap(Stato,PosVuoto,PosTessera,NuovoStato).
trasforma(nord,Stato,NuovoStato):-
  nth(Stato,PosVuoto,vuoto),
  PosTessera is PosVuoto+3,
  swap(Stato,PosVuoto,PosTessera,NuovoStato).
trasforma(est,Stato,NuovoStato):-
  nth(Stato,PosVuoto,vuoto),
  PosTessera is PosVuoto-1,
  swap(Stato,PosVuoto,PosTessera,NuovoStato).


bordosinistro(Posizione):-Resto is Posizione mod 3,Resto=0.
bordodestro(Posizione):-Resto is Posizione mod 3,Resto=2.
bordoinferiore(Posizione):-Posizione > 5.
bordosuperiore(Posizione):-Posizione < 3.
