ampiezza(Soluzione):-
  iniziale(S),
  ric_ampiezza([nodo(S,[])],Soluzione).

% ric_ampiezza(CodaNodiDaEspandere, ListaAzioniSoluzione)

ric_ampiezza([nodo(S,ListaAzioni)|_],ListaAzioni):-finale(S),!.
ric_ampiezza([nodo(S,ListaAzioni)|RestoDellaCoda],Soluzione):-
  espandi(nodo(S,ListaAzioni),ListaSuccessoriS),
  append(RestoDellaCoda,ListaSuccessoriS,NuovaCoda),
  ric_ampiezza(NuovaCoda,Soluzione).

% espandi(nodo(S,ListaAzioni),ListaSuccessoriS)
% utilizza findall

espandi(nodo(S,ListaAzioni),ListaSuccessoriS):-
  findall(Az,applicabile(Az,S),ListaApplicabili),
  successori(nodo(S,ListaAzioni),ListaApplicabili,ListaSuccessoriS).

successori(_,[],[]):-!.
successori(nodo(S,ListaAzioni),[Az|AltreAzioniApplicabili],
      [nodo(SNuovo,ListaAzioniSNuovo)|AltriSuccessoriS]):-
  trasforma(Az,S,SNuovo),
  append(ListaAzioni,[Az],ListaAzioniSNuovo),
  successori(nodo(S,ListaAzioni),AltreAzioniApplicabili,AltriSuccessoriS).



