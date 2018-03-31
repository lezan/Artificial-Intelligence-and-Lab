;  ---------------------------------------------
;  --- Definizione del modulo e dei template ---
;  ---------------------------------------------
(defmodule AGENT (import MAIN ?ALL) (export ?ALL))

(deftemplate K-cell
	(slot sound (allowed-values yes no unknown) (default unknown))
	(slot pos-r)
	(slot pos-c)
	(slot contains (allowed-values empty debris wall gate outdoor person unknown))
	(slot injured (allowed-values yes no unknown))
	(slot discovered)
	(slot checked)
	(slot clear)
)

(deftemplate K-agent
	(slot step)
	(slot time)
	(slot pos-r)
	(slot pos-c)
	(slot direction)
	(slot loaded)
)

(deftemplate K-person
	(slot step)
	(slot time)
	(slot pos-r)
	(slot pos-c)
)

(deftemplate offset-around
	(slot direction)
	(slot position)
	(slot offset-r)
	(slot offset-c)
)

(deftemplate goal
	(slot ident)
	(slot priority)
	(slot action)
	(slot status)
)

(deftemplate plan-action
	(slot plan-step)
	(slot action (allowed-values forward turnright turnleft drill load_debris unload_debris wait inform done))
	(slot param1)
	(slot param2)
	(slot param3)
)

(deftemplate next-left
	(slot direction)
	(slot left)
)

(deftemplate next-right
	(slot direction)
	(slot right)
)

; step dell'ultima percezione esaminata
(deftemplate last-perc (slot step))
(deftemplate last-perc-vision (slot step))
(deftemplate last-perc-drill (slot step))
(deftemplate last-perc-acoustic (slot step))
(deftemplate exec-mode (slot step))

; Ci dice se l'inizializzazione dell'agente è conclusa
(deftemplate init-agent (slot done (allowed-values yes no)))

; Contiene condizioni particolari che si possono verificare in corsa
(deftemplate special-condition (slot bumped (allowed-values yes no)))

; Serve per ricordarsi qual è il prossimo modulo da attivare
(deftemplate go (slot module (allowed-values perception deliberation reasoning action none)))


(deffacts initial-fact-agent
	(last-perc (step -1))
	(last-perc-vision (step -1))
	(last-perc-acoustic (step -1))
	(last-perc-drill (step -1))
)

(deffacts offset-around
	(offset-around (direction north) (position forward) (offset-r 1) (offset-c 0))
	(offset-around (direction south) (position forward) (offset-r -1) (offset-c 0))
	(offset-around (direction east)  (position forward) (offset-r 0) (offset-c 1))
	(offset-around (direction west)  (position forward) (offset-r 0) (offset-c -1))
	(offset-around (direction north) (position forward-left) (offset-r 1) (offset-c -1))
	(offset-around (direction south) (position forward-left) (offset-r -1) (offset-c 1))
	(offset-around (direction east)  (position forward-left) (offset-r 1) (offset-c 1))
	(offset-around (direction west)  (position forward-left) (offset-r -1) (offset-c -1))
	(offset-around (direction north) (position forward-right) (offset-r 1) (offset-c 1))
	(offset-around (direction south) (position forward-right) (offset-r -1) (offset-c -1))
	(offset-around (direction east)  (position forward-right) (offset-r -1) (offset-c 1))
	(offset-around (direction west)  (position forward-right) (offset-r 1) (offset-c -1))
	(offset-around (direction north) (position left) (offset-r 0) (offset-c -1))
	(offset-around (direction south) (position left) (offset-r 0) (offset-c 1))
	(offset-around (direction east)  (position left) (offset-r 1) (offset-c 0))
	(offset-around (direction west)  (position left) (offset-r -1) (offset-c 0))
	(offset-around (direction north) (position behind-left) (offset-r -1) (offset-c -1))
	(offset-around (direction south) (position behind-left) (offset-r 1) (offset-c 1))
	(offset-around (direction east)  (position behind-left) (offset-r 1) (offset-c -1))
	(offset-around (direction west)  (position behind-left) (offset-r -1) (offset-c 1))
	(offset-around (direction north) (position behind) (offset-r -1) (offset-c 0))
	(offset-around (direction south) (position behind) (offset-r 1) (offset-c 0))
	(offset-around (direction east)  (position behind) (offset-r 0) (offset-c -1))
	(offset-around (direction west)  (position behind) (offset-r 0) (offset-c 1))
	(offset-around (direction north) (position behind-right) (offset-r -1) (offset-c 1))
	(offset-around (direction south) (position behind-right) (offset-r 1) (offset-c -1))
	(offset-around (direction east)  (position behind-right) (offset-r -1) (offset-c -1))
	(offset-around (direction west)  (position behind-right) (offset-r 1) (offset-c 1))
	(offset-around (direction north) (position right) (offset-r 0) (offset-c 1))
	(offset-around (direction south) (position right) (offset-r 0) (offset-c -1))
	(offset-around (direction east)  (position right) (offset-r -1) (offset-c 0))
	(offset-around (direction west)  (position right) (offset-r 1) (offset-c 0))
)

(deffacts nexts
	(next-left (direction north) (left west))
	(next-left (direction west) (left south))
	(next-left (direction south) (left east))
	(next-left (direction east) (left north))
	(next-right (direction north) (right east))
	(next-right (direction east) (right south))
	(next-right (direction south) (right west))
	(next-right (direction west) (right north))
)


;  ---------------------------------------------
;  --- Regole iniziali per creare la mappa   ---
;  ---------------------------------------------

(defrule  beginagent_kcell_no_injuried
		(declare (salience 11))
		(status (step 0))
		(not (init-agent (done yes)))
		(not (exec (step 0)))
		(init_cell (pos-r ?r) (pos-c ?c) (contains ?x&outdoor|wall|empty|gate))

=>
	 (assert (K-cell (pos-r ?r) (pos-c ?c) (contains ?x) (injured no)))
)

(defrule  beginagent_kcell_maybe_injuried
		(declare (salience 11))
		(status (step 0))
		(not (init-agent (done yes)))
		(not (exec (step 0)))
		(init_cell (pos-r ?r) (pos-c ?c) (contains ?x&debris|unknown))

=>
	 (assert (K-cell (pos-r ?r) (pos-c ?c) (contains ?x) (injured unknown)))
)

(defrule beginagent_position

		(declare (salience 10))

		(status (step 0))
		(not (init-agent (done yes)))
		(not (exec (step 0)))
		(initial_agentposition (pos-r ?r) (pos-c ?c) (direction ?d))
=>
		(assert
			(K-agent
				(step 0)
				(time 0)
				(pos-r ?r)
				(pos-c ?c)
				(direction ?d)
				(loaded no)
			)
			(init-agent (done yes))
	 )
)


;  -----------------------------------------------------
;  --- Regole per gestire l'attivazione dei moduli   ---
;  -----------------------------------------------------

(defrule first-module (declare (salience 9))
	(init-agent (done yes))
	(not (go (module ?)))
	=>
	(assert (go (module perception)))
)

(defrule go-perception
	(declare (salience 5))
	?f <- (go (module perception))
	=>
	(modify ?f (module reasoning))
	(focus PERCEPTION)
)

(defrule go-reasoning (declare (salience 5))
	?f <- (go (module reasoning))
	=>
	(modify ?f (module action))
	(focus REASONING)
)

(defrule go-action (declare (salience 5))
	?f <- (go (module action))
	=>
	(modify ?f (module none))
	(focus ACTION)
)


;  ------------------------------------------------
;  --- Regole da eseguire alla fine dell'agent  ---
;  ------------------------------------------------

; Esegue l'azione dello step corrente, lasciando il controllo al main
(defrule exec_act
		(declare (salience 0))
		(K-agent (step ?i))
		(exec (step ?i))
		?go <- (go (module none))
	=>
		(retract ?go)
		(pop-focus)
)

; L'agent non sa cosa fare. Halt per evitare di far crashare CLIPS
(defrule nothing-to-do
	(declare (salience -1000))
	=>
	(printout t "Don't know what to do")
	(assert (clips-monitor stop))
	(halt)
)

;  ------------------------------------------------
;  ---- Implementazione ---------------------------
;  ------------------------------------------------
(deffunction distance(?ar ?ac ?br ?bc)
	(bind ?dist (+ (abs (- ?ar ?br)) (abs(- ?ac ?bc))))
	(return ?dist)
)

(deftemplate test-exec (slot step) (slot action (allowed-values forward turnright turnleft drill load_debris unload_debris wait inform done))
	(slot param1) (slot param2) (slot param3)
)
(deftemplate init-cost (slot goal-type) (slot cost))
(deftemplate bias-cost (slot goal-type) (slot cost))
(deftemplate search-goal (slot created-at-step) (slot goal-type) (slot pos-r) (slot pos-c))
(deftemplate goal-candidate (slot id) (slot goal-type (allowed-values explore debris unload_debris drill done)) (slot pos-r) (slot pos-c)
	(slot param1) (slot param2) (slot activated (allowed-values yes no))
)
(deftemplate current-goal-candidate (slot id))
(deftemplate path (slot id) (slot created-at-step) (slot goal-type) (slot pos-r) (slot pos-c) (slot cost) (slot biased-cost))
(deftemplate path-step (slot path-id) (slot step) (slot direction (allowed-values north south east west drill unload_debris done))) ;TODO: rename direction>action
(deftemplate path-picked (slot path-id))

(deftemplate home-plan (slot id) (slot cost) (slot calculated-at-time))

(deftemplate cell-informed (slot pos-r) (slot pos-c) (slot info (allowed-values checked discover clear)))

(deffacts AGENT-OPTIONS
	(AGENT-OPTION_inform-clear)
	;(AGENT-OPTION_home-plan)
	;(AGENT-OPTION_single-goal)
	(AGENT-OPTION_max-plans 100)

	(bias-cost (goal-type explore) (cost 0))
	(bias-cost (goal-type unload_debris) (cost -25))
	(bias-cost (goal-type debris) (cost -10))
	(bias-cost (goal-type drill) (cost -60))
	(bias-cost (goal-type done) (cost 0))
)

; Clean up old search stuff
(defrule clean-up-old-search-goal (declare (salience 100))
	(K-agent (step ?current-step))
	?goal <- (search-goal (created-at-step ?old-step&:(< ?old-step ?current-step)))
=>
	(retract ?goal)
)
(defrule clean-up-old-path-step (declare (salience 100))
	(K-agent (step ?current-step))
	(path (id ?path-id) (created-at-step ?old-step&:(< ?old-step ?current-step)))
	?step <- (path-step (path-id ?path-id))
=>
	(retract ?step)
)
(defrule clean-up-old-path (declare (salience 100))
	(K-agent (step ?current-step))
	?path <- (path (id ?path-id) (created-at-step ?old-step&:(< ?old-step ?current-step)))
	(not (path-step (path-id ?path-id)))
=>
	(retract ?path)
)
(deftemplate goal-candidate-processed (slot id))
(defrule clean-up-goal-candidate-processed (declare (salience 100))
	?f <- (goal-candidate-processed)
=>
	(retract ?f)
)
(deftemplate goal-distance (slot id) (slot distance))
(defrule clean-up-goal-distance (declare (salience 100))
	?f <- (goal-distance)
=>
	(retract ?f)
)

;(defrule print-path-picked (declare (salience 9000))
;	(K-agent (step ?step))
;	(path-picked (path-id ?id))
;	(path (id ?id) (goal-type ?type) (pos-r ?r) (pos-c ?c))
;	(path-step (path-id ?id) (step 1) (direction ?action))
;=>
;	(printout t "Step " ?step ": " ?type " (" ?r ", " ?c ")" crlf)
;	(printout t "> " ?action crlf)
;)
;--------------

(deftemplate action-cost (slot action) (slot extra) (slot cost))
(deffacts action-costs
	(action-cost (action forward) (extra 1) (cost 1))
	(action-cost (action turnleft) (extra 1) (cost 2))
	(action-cost (action turnright) (extra 1) (cost 2))
	(action-cost (action drill) (extra 0) (cost 60))
	(action-cost (action inform) (extra 0) (cost 1))
	(action-cost (action load_debris) (extra 0) (cost 20))
	(action-cost (action unload_debris) (extra 6) (cost 10))
	(action-cost (action wait) (extra 0) (cost 5))
)

(deftemplate move-cost (slot direction-from) (slot direction-to) (slot loaded) (slot cell-type) (slot cost))
(deffacts move-costs
	; not loaded, empty
	(move-cost (direction-from north) (direction-to north) (loaded no) (cell-type empty) (cost 1))
	(move-cost (direction-from north) (direction-to south) (loaded no) (cell-type empty) (cost 5))
	(move-cost (direction-from north) (direction-to east) (loaded no) (cell-type empty) (cost 3))
	(move-cost (direction-from north) (direction-to west) (loaded no) (cell-type empty) (cost 3))

	(move-cost (direction-from south) (direction-to north) (loaded no) (cell-type empty) (cost 5))
	(move-cost (direction-from south) (direction-to south) (loaded no) (cell-type empty) (cost 1))
	(move-cost (direction-from south) (direction-to east) (loaded no) (cell-type empty) (cost 3))
	(move-cost (direction-from south) (direction-to west) (loaded no) (cell-type empty) (cost 3))

	(move-cost (direction-from east) (direction-to north) (loaded no) (cell-type empty) (cost 3))
	(move-cost (direction-from east) (direction-to south) (loaded no) (cell-type empty) (cost 3))
	(move-cost (direction-from east) (direction-to east) (loaded no) (cell-type empty) (cost 1))
	(move-cost (direction-from east) (direction-to west) (loaded no) (cell-type empty) (cost 5))

	(move-cost (direction-from west) (direction-to north) (loaded no) (cell-type empty) (cost 3))
	(move-cost (direction-from west) (direction-to south) (loaded no) (cell-type empty) (cost 3))
	(move-cost (direction-from west) (direction-to east) (loaded no) (cell-type empty) (cost 5))
	(move-cost (direction-from west) (direction-to west) (loaded no) (cell-type empty) (cost 1))

	; not loaded, gate
	(move-cost (direction-from north) (direction-to north) (loaded no) (cell-type gate) (cost 1))
	(move-cost (direction-from north) (direction-to south) (loaded no) (cell-type gate) (cost 5))
	(move-cost (direction-from north) (direction-to east) (loaded no) (cell-type gate) (cost 3))
	(move-cost (direction-from north) (direction-to west) (loaded no) (cell-type gate) (cost 3))

	(move-cost (direction-from south) (direction-to north) (loaded no) (cell-type gate) (cost 5))
	(move-cost (direction-from south) (direction-to south) (loaded no) (cell-type gate) (cost 1))
	(move-cost (direction-from south) (direction-to east) (loaded no) (cell-type gate) (cost 3))
	(move-cost (direction-from south) (direction-to west) (loaded no) (cell-type gate) (cost 3))

	(move-cost (direction-from east) (direction-to north) (loaded no) (cell-type gate) (cost 3))
	(move-cost (direction-from east) (direction-to south) (loaded no) (cell-type gate) (cost 3))
	(move-cost (direction-from east) (direction-to east) (loaded no) (cell-type gate) (cost 1))
	(move-cost (direction-from east) (direction-to west) (loaded no) (cell-type gate) (cost 5))

	(move-cost (direction-from west) (direction-to north) (loaded no) (cell-type gate) (cost 3))
	(move-cost (direction-from west) (direction-to south) (loaded no) (cell-type gate) (cost 3))
	(move-cost (direction-from west) (direction-to east) (loaded no) (cell-type gate) (cost 5))
	(move-cost (direction-from west) (direction-to west) (loaded no) (cell-type gate) (cost 1))

	; not loaded, debris (magic number 60)
	(move-cost (direction-from north) (direction-to north) (loaded no) (cell-type debris) (cost 21))
	(move-cost (direction-from north) (direction-to south) (loaded no) (cell-type debris) (cost 25))
	(move-cost (direction-from north) (direction-to east) (loaded no) (cell-type debris) (cost 23))
	(move-cost (direction-from north) (direction-to west) (loaded no) (cell-type debris) (cost 23))

	(move-cost (direction-from south) (direction-to north) (loaded no) (cell-type debris) (cost 25))
	(move-cost (direction-from south) (direction-to south) (loaded no) (cell-type debris) (cost 21))
	(move-cost (direction-from south) (direction-to east) (loaded no) (cell-type debris) (cost 23))
	(move-cost (direction-from south) (direction-to west) (loaded no) (cell-type debris) (cost 23))

	(move-cost (direction-from east) (direction-to north) (loaded no) (cell-type debris) (cost 23))
	(move-cost (direction-from east) (direction-to south) (loaded no) (cell-type debris) (cost 23))
	(move-cost (direction-from east) (direction-to east) (loaded no) (cell-type debris) (cost 21))
	(move-cost (direction-from east) (direction-to west) (loaded no) (cell-type debris) (cost 25))

	(move-cost (direction-from west) (direction-to north) (loaded no) (cell-type debris) (cost 23))
	(move-cost (direction-from west) (direction-to south) (loaded no) (cell-type debris) (cost 23))
	(move-cost (direction-from west) (direction-to east) (loaded no) (cell-type debris) (cost 25))
	(move-cost (direction-from west) (direction-to west) (loaded no) (cell-type debris) (cost 21))

	; not loaded, unknown
	(move-cost (direction-from north) (direction-to north) (loaded no) (cell-type unknown) (cost 1))
	(move-cost (direction-from north) (direction-to south) (loaded no) (cell-type unknown) (cost 5))
	(move-cost (direction-from north) (direction-to east) (loaded no) (cell-type unknown) (cost 3))
	(move-cost (direction-from north) (direction-to west) (loaded no) (cell-type unknown) (cost 3))

	(move-cost (direction-from south) (direction-to north) (loaded no) (cell-type unknown) (cost 5))
	(move-cost (direction-from south) (direction-to south) (loaded no) (cell-type unknown) (cost 1))
	(move-cost (direction-from south) (direction-to east) (loaded no) (cell-type unknown) (cost 3))
	(move-cost (direction-from south) (direction-to west) (loaded no) (cell-type unknown) (cost 3))

	(move-cost (direction-from east) (direction-to north) (loaded no) (cell-type unknown) (cost 3))
	(move-cost (direction-from east) (direction-to south) (loaded no) (cell-type unknown) (cost 3))
	(move-cost (direction-from east) (direction-to east) (loaded no) (cell-type unknown) (cost 1))
	(move-cost (direction-from east) (direction-to west) (loaded no) (cell-type unknown) (cost 5))

	(move-cost (direction-from west) (direction-to north) (loaded no) (cell-type unknown) (cost 3))
	(move-cost (direction-from west) (direction-to south) (loaded no) (cell-type unknown) (cost 3))
	(move-cost (direction-from west) (direction-to east) (loaded no) (cell-type unknown) (cost 5))
	(move-cost (direction-from west) (direction-to west) (loaded no) (cell-type unknown) (cost 1))


	; loaded, empty
	(move-cost (direction-from north) (direction-to north) (loaded yes) (cell-type empty) (cost 2))
	(move-cost (direction-from north) (direction-to south) (loaded yes) (cell-type empty) (cost 8))
	(move-cost (direction-from north) (direction-to east) (loaded yes) (cell-type empty) (cost 5))
	(move-cost (direction-from north) (direction-to west) (loaded yes) (cell-type empty) (cost 5))

	(move-cost (direction-from south) (direction-to north) (loaded yes) (cell-type empty) (cost 8))
	(move-cost (direction-from south) (direction-to south) (loaded yes) (cell-type empty) (cost 2))
	(move-cost (direction-from south) (direction-to east) (loaded yes) (cell-type empty) (cost 5))
	(move-cost (direction-from south) (direction-to west) (loaded yes) (cell-type empty) (cost 5))

	(move-cost (direction-from east) (direction-to north) (loaded yes) (cell-type empty) (cost 5))
	(move-cost (direction-from east) (direction-to south) (loaded yes) (cell-type empty) (cost 5))
	(move-cost (direction-from east) (direction-to east) (loaded yes) (cell-type empty) (cost 2))
	(move-cost (direction-from east) (direction-to west) (loaded yes) (cell-type empty) (cost 8))

	(move-cost (direction-from west) (direction-to north) (loaded yes) (cell-type empty) (cost 5))
	(move-cost (direction-from west) (direction-to south) (loaded yes) (cell-type empty) (cost 5))
	(move-cost (direction-from west) (direction-to east) (loaded yes) (cell-type empty) (cost 8))
	(move-cost (direction-from west) (direction-to west) (loaded yes) (cell-type empty) (cost 2))

	; loaded, gate
	(move-cost (direction-from north) (direction-to north) (loaded yes) (cell-type gate) (cost 2))
	(move-cost (direction-from north) (direction-to south) (loaded yes) (cell-type gate) (cost 8))
	(move-cost (direction-from north) (direction-to east) (loaded yes) (cell-type gate) (cost 5))
	(move-cost (direction-from north) (direction-to west) (loaded yes) (cell-type gate) (cost 5))

	(move-cost (direction-from south) (direction-to north) (loaded yes) (cell-type gate) (cost 8))
	(move-cost (direction-from south) (direction-to south) (loaded yes) (cell-type gate) (cost 2))
	(move-cost (direction-from south) (direction-to east) (loaded yes) (cell-type gate) (cost 5))
	(move-cost (direction-from south) (direction-to west) (loaded yes) (cell-type gate) (cost 5))

	(move-cost (direction-from east) (direction-to north) (loaded yes) (cell-type gate) (cost 5))
	(move-cost (direction-from east) (direction-to south) (loaded yes) (cell-type gate) (cost 5))
	(move-cost (direction-from east) (direction-to east) (loaded yes) (cell-type gate) (cost 2))
	(move-cost (direction-from east) (direction-to west) (loaded yes) (cell-type gate) (cost 8))

	(move-cost (direction-from west) (direction-to north) (loaded yes) (cell-type gate) (cost 5))
	(move-cost (direction-from west) (direction-to south) (loaded yes) (cell-type gate) (cost 5))
	(move-cost (direction-from west) (direction-to east) (loaded yes) (cell-type gate) (cost 8))
	(move-cost (direction-from west) (direction-to west) (loaded yes) (cell-type gate) (cost 2))

	; loaded, debris (magic number 60)
	(move-cost (direction-from north) (direction-to north) (loaded yes) (cell-type debris) (cost 62))
	(move-cost (direction-from north) (direction-to south) (loaded yes) (cell-type debris) (cost 68))
	(move-cost (direction-from north) (direction-to east) (loaded yes) (cell-type debris) (cost 65))
	(move-cost (direction-from north) (direction-to west) (loaded yes) (cell-type debris) (cost 65))

	(move-cost (direction-from south) (direction-to north) (loaded yes) (cell-type debris) (cost 68))
	(move-cost (direction-from south) (direction-to south) (loaded yes) (cell-type debris) (cost 62))
	(move-cost (direction-from south) (direction-to east) (loaded yes) (cell-type debris) (cost 65))
	(move-cost (direction-from south) (direction-to west) (loaded yes) (cell-type debris) (cost 65))

	(move-cost (direction-from east) (direction-to north) (loaded yes) (cell-type debris) (cost 65))
	(move-cost (direction-from east) (direction-to south) (loaded yes) (cell-type debris) (cost 65))
	(move-cost (direction-from east) (direction-to east) (loaded yes) (cell-type debris) (cost 62))
	(move-cost (direction-from east) (direction-to west) (loaded yes) (cell-type debris) (cost 68))

	(move-cost (direction-from west) (direction-to north) (loaded yes) (cell-type debris) (cost 65))
	(move-cost (direction-from west) (direction-to south) (loaded yes) (cell-type debris) (cost 65))
	(move-cost (direction-from west) (direction-to east) (loaded yes) (cell-type debris) (cost 68))
	(move-cost (direction-from west) (direction-to west) (loaded yes) (cell-type debris) (cost 62))

	; loaded, unknown
	(move-cost (direction-from north) (direction-to north) (loaded yes) (cell-type unknown) (cost 2))
	(move-cost (direction-from north) (direction-to south) (loaded yes) (cell-type unknown) (cost 8))
	(move-cost (direction-from north) (direction-to east) (loaded yes) (cell-type unknown) (cost 5))
	(move-cost (direction-from north) (direction-to west) (loaded yes) (cell-type unknown) (cost 5))

	(move-cost (direction-from south) (direction-to north) (loaded yes) (cell-type unknown) (cost 8))
	(move-cost (direction-from south) (direction-to south) (loaded yes) (cell-type unknown) (cost 2))
	(move-cost (direction-from south) (direction-to east) (loaded yes) (cell-type unknown) (cost 5))
	(move-cost (direction-from south) (direction-to west) (loaded yes) (cell-type unknown) (cost 5))

	(move-cost (direction-from east) (direction-to north) (loaded yes) (cell-type unknown) (cost 5))
	(move-cost (direction-from east) (direction-to south) (loaded yes) (cell-type unknown) (cost 5))
	(move-cost (direction-from east) (direction-to east) (loaded yes) (cell-type unknown) (cost 2))
	(move-cost (direction-from east) (direction-to west) (loaded yes) (cell-type unknown) (cost 8))

	(move-cost (direction-from west) (direction-to north) (loaded yes) (cell-type unknown) (cost 5))
	(move-cost (direction-from west) (direction-to south) (loaded yes) (cell-type unknown) (cost 5))
	(move-cost (direction-from west) (direction-to east) (loaded yes) (cell-type unknown) (cost 8))
	(move-cost (direction-from west) (direction-to west) (loaded yes) (cell-type unknown) (cost 2))
)

(deftemplate turn-direction (slot direction-from) (slot direction-to) (slot action (allowed-values forward turnright turnleft)))
(deffacts turn-directions
	(turn-direction (direction-from north) (direction-to north) (action forward))
	(turn-direction (direction-from north) (direction-to south) (action turnleft))
	(turn-direction (direction-from north) (direction-to east) (action turnright))
	(turn-direction (direction-from north) (direction-to west) (action turnleft))

	(turn-direction (direction-from south) (direction-to north) (action turnleft))
	(turn-direction (direction-from south) (direction-to south) (action forward))
	(turn-direction (direction-from south) (direction-to east) (action turnleft))
	(turn-direction (direction-from south) (direction-to west) (action turnright))

	(turn-direction (direction-from east) (direction-to north) (action turnleft))
	(turn-direction (direction-from east) (direction-to south) (action turnright))
	(turn-direction (direction-from east) (direction-to east) (action forward))
	(turn-direction (direction-from east) (direction-to west) (action turnleft))

	(turn-direction (direction-from west) (direction-to north) (action turnright))
	(turn-direction (direction-from west) (direction-to south) (action turnleft))
	(turn-direction (direction-from west) (direction-to east) (action turnleft))
	(turn-direction (direction-from west) (direction-to west) (action forward))
)