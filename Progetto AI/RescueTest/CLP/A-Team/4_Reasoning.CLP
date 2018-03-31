; Modulo per la definizione dei meccanismi di reasoning dell'agente
; MODULO REASONING
(defmodule REASONING (import MAIN ?ALL)(import AGENT ?ALL)(export ?ALL))

(deffacts directions
	(direction north)
	(direction south)
	(direction east)
	(direction west)
)

(deftemplate direction-offset (slot direction) (slot pos-r) (slot pos-c))
(deffacts direction-offsets
	(direction-offset (direction north) (pos-r 1) (pos-c 0))
	(direction-offset (direction south) (pos-r -1) (pos-c 0))
	(direction-offset (direction east) (pos-r 0) (pos-c 1))
	(direction-offset (direction west) (pos-r 0) (pos-c -1))
)

(deftemplate reasoning-loop (slot module (allowed-values reflex pick-goal search none)))

;(defrule print-k-agent (declare (salience 9000))
;	(K-agent (step ?step) (time ?time) (pos-r ?r) (pos-c ?c) (direction ?direction) (loaded ?loaded))
;=>
;	(printout t crlf)
;	(printout t "step: " ?step " time: " ?time crlf)
;	(printout t "position: (" ?r ", " ?c ")" crlf)
;	(printout t "direction: " ?direction " loaded: " ?loaded crlf)
;)

(defrule first-action (declare (salience 200)) ;TODO: Remove
	(K-agent (step 0))
	(not
		(exec)
	)
	=>
	(assert (exec (step 0) (action turnleft)))
)

; Loop
(defrule start-loop (declare (salience 25))
	(not (reasoning-loop (module ?)))
=>
	(assert (reasoning-loop (module reflex)))
)

(defrule go-to-reflex (declare (salience 50))
	?f <- (reasoning-loop (module reflex))
=>
	(modify ?f (module search))
	(focus REFLEX)
)

(defrule go-to-search (declare (salience 50))
	(reasoning-loop (module search))
	(K-agent (step ?step))
	(not (exec (step ?step)))
	(not (test-exec (step ?step)))
=>
	(focus SEARCH)
)

(defrule go-to-pick-goal (declare (salience 10))
	;(not (search-goal))
	(K-agent (step ?step))
	(not (exec (step ?step)))
	(not (test-exec (step ?step)))
=>
	;(printout t "Deliberazione per lo step: " ?step crlf)
	(focus PICK-GOAL)
)

(defrule end-loop (declare (salience 0))
	?f <- (reasoning-loop (module ?))
=>
	(retract ?f)
	(pop-focus)
)
; -----


(defmodule PICK-GOAL (import MAIN ?ALL) (import REASONING ?ALL) (export ?ALL))
(defrule pick-best-path (declare (salience 100))
	(not (path-picked))
	?path <- (path (id ?best-id) (biased-cost ?best-cost) (goal-type ?goal-type&:(neq ?goal-type done)))
	(not (path (id ?other-id&:(neq ?other-id ?best-id)) (biased-cost ?other-cost&:(< ?other-cost ?best-cost))))
=>
	;(printout t "Ho scelto: " ?best-id crlf)
	(halt)
	(assert (path-picked (path-id ?best-id)))
)

(defrule current-goal-candidate-changed
	(AGENT-OPTION_single-goal)
	(not (current-goal-candidate))
	(path-picked (path-id ?id))
	(path (id ?id) (pos-r ?r) (pos-c ?c) (goal-type ?goal-type))
	(goal-candidate (id ?candidate-id) (pos-r ?r) (pos-c ?c) (goal-type ?goal-type) (activated yes))
=>
	;(printout t "Goal reached or unreachable, picking new one: " ?candidate-id " / " ?goal-type " (" ?r ", " ?c ")" crlf)
	(assert (current-goal-candidate (id ?candidate-id)))
)

(defrule update-home-plan (declare (salience 100))
	?recalculate-request <- (recalculate-home-plan)
	?home-plan <- (home-plan)
	(K-agent (step ?step) (time ?time))
	(path (id ?best-id) (cost ?best-cost) (goal-type done) (created-at-step ?step))
	(not (path (id ?other-id&:(neq ?other-id ?best-id)) (goal-type done) (cost ?other-cost&:(< ?other-cost ?best-cost))))
=>
	(modify ?home-plan (id ?best-id) (cost ?best-cost) (calculated-at-time ?time))
	(retract ?recalculate-request)
)
(defrule time-to-go-home
	(AGENT-OPTION_home-plan)
	?picked <- (path-picked (path-id ?best-id))
	(path (id ?best-id) (goal-type ~done) (cost ?other-cost))
	(K-agent (time ?time) (step ?step))
	(maxduration ?max-time)
	(home-plan (id ?home-id) (cost ?home-plan-cost) (calculated-at-time ?time))
	(test (> ?home-plan-cost (- ?max-time ?time ?other-cost)))
=>
	;(printout t "Time to go home, I'll be late for dinner!" ?home-id crlf)
	(modify ?picked (path-id ?home-id))
	(assert (inhibit-reflex))
	(focus SEARCH)
)
(defrule time-to-go-home-nothing-to-do
	(not (path (goal-type ~done)))
	(path (id ?best-id) (cost ?best-cost) (goal-type done) (created-at-step ?step))
	(not (path (id ?other-id&:(neq ?other-id ?best-id)) (goal-type done) (cost ?other-cost&:(< ?other-cost ?best-cost))))
=>
	(assert (path-picked (path-id ?best-id)))
)

(defrule inhibit-reflex
	?f1 <- (inhibit-reflex)
	?f2 <- (AGENT-OPTION_inform-clear)
=>
	(retract ?f1 ?f2)
)

(deffacts home-plan-init
	(home-plan (cost 0) (calculated-at-time 0))
)
(defrule recalculate-home-plan (declare (salience 0))
	(AGENT-OPTION_home-plan)
	(path-picked (path-id ?best-id))
	(path (id ?best-id) (cost ?cost))
	(K-agent (time ?time) (step ?step))
	(maxduration ?max-time)
	(home-plan (cost ?home-plan-cost) (calculated-at-time ?calculated-at-time&:(neq ?calculated-at-time ?time)))
	(test (> (+ ?home-plan-cost (- ?time ?calculated-at-time)) (- ?max-time ?time ?cost)))
=>
	;(printout t "Recalculating home plan." crlf)
	(assert (recalculate-home-plan))
	(focus SEARCH)
)
(defrule recalculate-home-plan-nothing-to-do
	(not (path-picked))
=>
	;(printout t "No more reachable goals, going home." crlf)
	(assert (recalculate-home-plan))
	(focus SEARCH)
)

(defrule dumb-done (declare (salience -9000))
	(K-agent (step ?step))
	(not (path))
	(not (exec (step ?step)))
=>
	(assert (exec (step ?step) (action done)))
	(printout t "DONE" crlf)
)