%% GENERATE

% The GENERATE parts defines a large collection of answer sets that could be seen as potential solutions.
% Choice rules are typically the main members of the GENERATE part of the program.

% Colore
1 { colore(Casa, Colore) : colori(Colore) } 1 :- case(Casa).
1 { colore(Casa, Colore) : case(Casa) } 1 :- colori(Colore).

% Nazionalità
1 { nazionalita(Casa, Nazionalita) : nazionalitas(Nazionalita) } 1 :- case(Casa).
1 { nazionalita(Casa, Nazionalita) : case(Casa) } 1 :- nazionalitas(Nazionalita).

% Animale

1 { animale(Casa, Animale) : animali(Animale) } 1 :- case(Casa).
1 { animale(Casa, Animale) : case(Casa) } 1 :- animali(Animale).

% Bevanda

1 { bevanda(Casa, Bevanda) : bevande(Bevanda) } 1 :- case(Casa).
1 { bevanda(Casa, Bevanda) : case(Casa) } 1 :- bevande(Bevanda).

% Professione

1 { professione(Casa, Professione) : professioni(Professione) } 1 :- case(Casa).
1 { professione(Casa, Professione) : case(Casa) } 1 :- professioni(Professione).

%% DEFINE

% The DEFINE sections expresses additional concepts and connects the GENERATE and TEST parts.

% Nazionalità
nazionalitas(inglese;spagnolo;giapponese;italiano;norvegese).

% Casa
case(1..5).

% Professione
professioni(pittore;scultore;diplomatico;violinista;dottore).

% Animale
animali(cane;lumache;volpe;cavallo;zebra).

% Bevanda
bevande(te;caffe;latte;succo_di_frutta;altro).

% Colore
colori(rossa;verde;bianca;gialla;blu).

% Funzione di adiacenza
next_to(X, Y) :- case(X), case(Y), |X - Y| == 1.

chi_ha_la_zebra(Nazionalita) :- nazionalita(Casa, Nazionalita), animale(Casa, zebra).

%% TEST

% The TEST part consists of rules that eliminate the answer sets of the GENERATE part that do not correspond to solutions.
% Constraints often form the TEST section of a program.

% 1. L'inglese vive nella casa rossa.
:- nazionalita(X, inglese), colore(X, Y), Y != rossa.

% 2. Lo spagnolo possiede un cane.
:- nazionalita(X, spagnolo), animale(X, Y), Y != cane.

% 3. Il giapponese è un pittore.
:- nazionalita(X, giapponese), professione(X, Y), Y != pittore.

% 4. L'italiano beve tè.
:- nazionalita(X, italiano), bevanda(X, Y), Y != te.

% 5. Il norvegese vive nella prima casa a sinistra.
:- nazionalita(X, norvegese), X != 1.

% 6. Il proprietario della casa verde beve caffè.
:- bevanda(X, caffe), colore(X, Y), Y != verde.

% 7. La casa verde è immediatamente sulla destra di quella bianca.
:- colore(X, verde), colore(Y, bianca), X != Y + 1.

% 8. Lo scultore alleva lumache.
:- professione(X, scultore), animale(X, Y), Y != lumache.

% 9. Il diplomatico vive nella casa gialla.
:- professione(X, diplomatico), colore(X, Y), Y != gialla.

% 10. Nella casa di mezzo si beve latte.
:- bevanda(3, X), X != latte.

% 11. La casa del norvegese è adiacente a quella blu.
:- nazionalita(X, norvegese), colore(Y, blu), not next_to(X, Y).

% 12. Il violinista beve succo di frutta.
:- professione(X, violinista), bevanda(X, Y), Y != succo_di_frutta.

% 13. La volpe è nella casa adiacente a quella del dottore.
:- animale(X, volpe), professione(Y, dottore), not next_to(X, Y).

% 14. Il cavallo è nella casa adiacente a quella del diplomatico.
:- animale(X, cavallo), professione(Y, diplomatico), not next_to(X, Y).

%% OUTPUT

casa(Casa, Colore, Nazionalita, Animale, Bevanda, Professione) :- 
	case(Casa),
	colore(Casa, Colore),
	nazionalita(Casa, Nazionalita),
	animale(Casa, Animale),
	bevanda(Casa, Bevanda),
	professione(Casa, Professione).

#show casa/6.
#show chi_ha_la_zebra/1.
