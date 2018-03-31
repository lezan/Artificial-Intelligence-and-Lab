:- module(action, [applicabile/2, trasforma/3, percorso/3, tratta/4, member_pair/3, stazione/3, fermata/2, iniziale/1, finale/1]).

% stato: [at(Stazione), Location]
% Location può essere in(NomeLinea, Dir) o
% 'ground' se l'agente non e' su nessun treno
% Dir può esere 0 o 1

% Azioni:
%  sali(Linea, Dir)
%  scendi(Stazione)
%  vai(Linea, Dir, StazionePartenza, StazioneArrivo)

applicabile(sali(Linea,Dir),[at(Stazione),ground]) :- % Controllo se l'azione sali è applicabile. Per esserlo devo essere a terra (ground).
	fermata(Stazione,Linea), % Controllo a quale stazione appartiene la Stazione a quale Linea.
	member(Dir,[0,1]). % Controllo la direzione.

applicabile(scendi(Stazione),[at(Stazione),in(_,_)]).

applicabile(vai(Linea,Dir,SP,SA),[at(SP),in(Linea,Dir)]) :-
	tratta(Linea,Dir,SP,SA).

trasforma(sali(Linea,Dir),[at(Stazione),ground],[at(Stazione),in(Linea,Dir)]).

trasforma(scendi(Stazione),[at(Stazione),in(_,_)],[at(Stazione),ground]).

trasforma(vai(Linea,Dir,SP,SA),[at(SP),in(Linea,Dir)],[at(SA),in(Linea,Dir)]) :-
	tratta(Linea,Dir,SP,SA).
	
uguale(S,S).

% percorso(Linea, Dir, ListaFermate)
/*
Percorso consente di tenere traccia di tutte le linee prese in considerazione e le relative stazione in ordine.
Sono, inoltre, definite due direzioni: 0 e 1. I percorsi "1" sono definiti con una lista rovesciata.
*/
percorso(piccadilly,0,['Kings Cross','Holborn','Covent Garden','Leicester Square','Piccadilly Circus','Green Park','South Kensington','Gloucester Road','Earls Court']).
percorso(jubilee,0,['Baker Street','Bond Street','Green Park','Westminster','Waterloo','London Bridge']).
percorso(central,0,['Notting Hill Gate','Bond Street','Oxford Circus','Tottenham Court Road','Holborn','Bank']).
percorso(victoria,0,['Kings Cross','Euston','Warren Street','Oxford Circus','Green Park','Victoria']).
percorso(bakerloo,0,['Paddington','Baker Street','Oxford Circus','Piccadilly Circus','Embankment','Waterloo']).
percorso(circle,0,['Embankment','Westminster','Victoria','South Kensington','Gloucester Road','Notting Hill Gate','Bayswater','Paddington','Baker Street','Kings Cross']).
	
percorso(Linea,1,LR) :-
	percorso(Linea,0,L),
	reverse(L,LR).

% tratta(NomeLinea, Dir, StazionePartenza, StazioneArrivo)
/*
Gestisce la relazione di adiancenza tra stazioni di un certo percorso e una certa direzione.
member_pair implementa la relazione di adiacenza con l'aiuto del percorso per la direzione della linea.
*/
tratta(Linea,Dir,SP,SA) :-
	percorso(Linea,Dir,LF),
	member_pair(SP,SA,LF).

member_pair(X,Y,[X,Y|_]).
member_pair(X,Y,[_,Z|Rest]) :-
	member_pair(X,Y,[Z|Rest]).

% stazione(Stazione, Coord1, Coord2)
/*
E' l'elenco di tutte le stazione prese in esame con la loro posizione, così da permettere il calcolo della distanza.
*/
stazione('Baker Street',4.5,5.6).
stazione('Bank',12,4).
stazione('Bayswater',1,3.7).
stazione('Bond Street',5.4,4.1).
stazione('Covent Garden',8,4).
stazione('Earls Court',0,0).
stazione('Embankment',8.2,3).
stazione('Euston',7.1,6.6).
stazione('Gloucester Road',1.6,0.6).
stazione('Green Park',6,2.8).
stazione('Holborn',8.6,4.8).
stazione('Kings Cross',8.2,7.1).
stazione('Leicester Square',7.6,3.6).
stazione('London Bridge',0,0).
stazione('Notting Hill Gate',0,3.2).
stazione('Oxford Circus',6.2,4.3).
stazione('Paddington',2.4,4.2).
stazione('Piccadilly Circus',7,3.3).
stazione('South Kensington',2.6,0.5).
stazione('Tottenham Court Road',7.4,4.5).
stazione('Victoria',5.8,1).
stazione('Warren Street',6.5,6).
stazione('Waterloo',9.2,2.4).
stazione('Westminster',8,1.8).

/*
Fermata consente di conoscere se una certa stazione appartiene o meno ad una linea.
*/
fermata(Stazione,Linea) :-
	percorso(Linea,0,P), % Vado a cercare tutti i possibili percorsi.
	member(Stazione,P). % Controllo se il percorso trovato ha nelle sue fermate la Stazione che si sta cercando.

/*
La stazione decisa come stato iniziale della ricerca.
Si specifica, come primo parametro, la stazione in cui ci si trova e, come secondo parametro, lo stato in cui si è, cioè a terra e non sulla metropolinana.
*/
iniziale([at('Bayswater'),ground]).
%iniziale([at('Waterloo'),ground]).

/*
La stazione decisa come stato finale della ricerca.
Si specifica, come primo parametro, la stazione in cui ci si trova (si vuole andare) e, come secondo parametro, lo stato in cui si è, cioè a terra e non sulla mentropolitana.
*/
%finale([at('Covent Garden'),ground]).
%finale([at('Paddington'),ground]).
finale([at('Orvieto'),ground]).