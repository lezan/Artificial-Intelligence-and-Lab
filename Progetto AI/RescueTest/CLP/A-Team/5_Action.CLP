; Modulo per la definizione delle azioni da eseguire
; MODULO ACTION
(defmodule ACTION (import MAIN ?ALL)(import AGENT ?ALL)(export ?ALL))

(defrule agent-bumped
	(status (step ?step))
	?f <- (special-condition (bumped yes))
=>
	(retract ?f)
)

(defrule entered-action (declare (salience 1000))
	(path-picked)
=>
	(halt)
)

(defrule translate-path-step-turn
	(K-agent (step ?step) (direction ?agent-direction))
	(not (exec (step ?step)))
	(path-picked (path-id ?path-id))
	(path-step (path-id ?path-id) (step 1) (direction ?move-direction))
	(path-step (path-id ?path-id) (step ?path-step) (direction ?move-direction))
	(not (path-step (step ?other-step&:(< ?other-step ?path-step))))
	(turn-direction (direction-from ?agent-direction) (direction-to ?move-direction) (action ?turn&turnleft|turnright))
=>
	(assert (test-exec (step ?step) (action ?turn)))
)

(defrule translate-path-step-forward
	(K-agent (step ?step) (direction ?agent-direction) (pos-r ?r) (pos-c ?c))
	(not (exec (step ?step)))
	(path-picked (path-id ?path-id))
	?f <- (path-step (path-id ?path-id) (step ?path-step) (direction ?move-direction))
	(not (path-step (path-id ?path-id) (step ?other-step&:(< ?other-step ?path-step))))
	(turn-direction (direction-from ?agent-direction) (direction-to ?move-direction) (action forward))
	(offset-around (direction ?agent-direction) (position forward) (offset-r ?offset-r) (offset-c ?offset-c))
	(K-cell (pos-r =(+ ?r ?offset-r)) (pos-c =(+ ?c ?offset-c)) (contains ~debris))
=>
	(assert (test-exec (step ?step) (action forward)))
	(retract ?f)
)

(defrule translate-path-step-load-debris
	(K-agent (step ?step) (direction ?agent-direction) (pos-r ?r) (pos-c ?c) (loaded no))
	(not (exec (step ?step)))
	(path-picked (path-id ?path-id))
	(path-step (path-id ?path-id) (step ?path-step) (direction ?move-direction))
	(not (path-step (path-id ?path-id) (step ?other-step&:(< ?other-step ?path-step))))
	(turn-direction (direction-from ?agent-direction) (direction-to ?move-direction) (action forward))
	(offset-around (direction ?agent-direction) (position forward) (offset-r ?offset-r) (offset-c ?offset-c))
	(K-cell (pos-r =(+ ?r ?offset-r)) (pos-c =(+ ?c ?offset-c)) (contains debris) (injured no))
=>
	(assert (test-exec (step ?step) (action load_debris) (param1 (+ ?r ?offset-r)) (param2 (+ ?c ?offset-c))))
)

(defrule translate-path-step-drill
	(K-agent (step ?step) (pos-r ?r) (pos-c ?c))
	(not (exec (step ?step)))
	(path-picked (path-id ?path-id))
	?f <- (path-step (path-id ?path-id) (step ?path-step) (direction drill))
	(not (path-step (path-id ?path-id) (step ?other-step&:(< ?other-step ?path-step))))
	(goal-candidate (pos-r ?r) (pos-c ?c) (goal-type drill) (param1 ?action-r) (param2 ?action-c) (activated yes))
	(K-cell (pos-r ?action-r) (pos-c ?action-c) (contains debris) (injured unknown))
=>
	(assert (test-exec (step ?step) (action drill) (param1 ?action-r) (param2 ?action-c)))
	(retract ?f)
)

(defrule translate-path-step-unload
	(K-agent (step ?step) (pos-r ?r) (pos-c ?c))
	(not (exec (step ?step)))
	(path-picked (path-id ?path-id))
	?f <- (path-step (path-id ?path-id) (step ?path-step) (direction unload_debris))
	(not (path-step (path-id ?path-id) (step ?other-step&:(< ?other-step ?path-step))))
	(goal-candidate (pos-r ?r) (pos-c ?c) (goal-type unload_debris) (param1 ?action-r) (param2 ?action-c) (activated yes))
	(not (K-person (pos-r ?action-r) (pos-c ?action-c)))
=>
	(assert (test-exec (step ?step) (action unload_debris) (param1 ?action-r) (param2 ?action-c)))
	(retract ?f)
)

(defrule translate-path-step-done
	(K-agent (step ?step) (pos-r ?r) (pos-c ?c))
	(not (exec (step ?step)))
	(path-picked (path-id ?path-id))
	?f <- (path-step (path-id ?path-id) (step ?path-step) (direction done))
	(not (path-step (path-id ?path-id) (step ?other-step&:(< ?other-step ?path-step))))
	(goal-candidate (pos-r ?r) (pos-c ?c) (goal-type done) (activated yes))
	(K-cell (pos-r ?r) (pos-c ?c) (contains gate))
=>
	(assert (test-exec (step ?step) (action done)))
	(retract ?f)
)

(defrule test-exec-not-loaded
	(K-agent (step ?step) (time ?time) (loaded no))
	(maxduration ?maxtime)
	(test-exec (step ?step) (action ?action&forward|turnright|turnleft) (param1 ?param1) (param2 ?param2) (param3 ?param3))
	(action-cost (action ?action) (cost ?cost))
	(test (> (+ ?time ?cost 1) ?maxtime))
=>
	(assert (emergency-done))	
)
(defrule test-exec-loaded
	(K-agent (step ?step) (time ?time) (loaded yes))
	(maxduration ?maxtime)
	(test-exec (step ?step) (action ?action&forward|turnright|turnleft) (param1 ?param1) (param2 ?param2) (param3 ?param3))
	(action-cost (action ?action) (extra ?extra) (cost ?cost))
	(test (> (+ ?time ?cost ?extra 1) ?maxtime))
=>
	(assert (emergency-done))	
)
(defrule test-exec-unload-outdoor
	(K-agent (step ?step) (time ?time))
	(maxduration ?maxtime)
	(test-exec (step ?step) (action ?action&unload_debris) (param1 ?param1) (param2 ?param2) (param3 ?param3))
	(K-cell (pos-r ?param1) (pos-c ?param2) (contains outdoor))
	(action-cost (action ?action) (cost ?cost))
	(test (> (+ ?time ?cost 1) ?maxtime))
=>
	(assert (emergency-done))	
)
(defrule test-exec-unload-indoor
	(K-agent (step ?step) (time ?time))
	(maxduration ?maxtime)
	(test-exec (step ?step) (action ?action&unload_debris) (param1 ?param1) (param2 ?param2) (param3 ?param3))
	(K-cell (pos-r ?param1) (pos-c ?param2) (contains empty))
	(action-cost (action ?action) (extra ?extra) (cost ?cost))
	(test (> (+ ?time ?cost ?extra 1) ?maxtime))
=>
	(assert (emergency-done))	
)
(defrule test-exec
	(K-agent (step ?step) (time ?time))
	(maxduration ?maxtime)
	(test-exec (step ?step) (action ?action&drill|inform|wait|load_debris))
	(action-cost (action ?action) (cost ?cost))
	(test (> (+ ?time ?cost 1) ?maxtime))
=>
	(assert (emergency-done))	
)

(defrule test-exec-ok (declare (salience -10))
	(not (emergency-done))
	?test-exec <- (test-exec (step ?step) (action ?action) (param1 ?param1) (param2 ?param2) (param3 ?param3))
=>
	(assert (exec (step ?step) (action ?action) (param1 ?param1) (param2 ?param2) (param3 ?param3)))
	(retract ?test-exec)
)
(defrule test-exec-emergency-done (declare (salience -10))
	(emergency-done)
	?test-exec <- (test-exec (step ?step))
=>
	(printout t "EMERGENCY DONE!" crlf)
	(assert (exec (step ?step) (action done)))
	(retract ?test-exec)
)

(defrule consume-path-step-forward (declare (salience 5))
	?picked <- (plan-action-picked ?step forward)
	?path-step <- (path-step (step ?step))
=>
	(retract ?picked ?path-step)
)
(defrule consume-path-step
	?picked <- (plan-action-picked ? ~forward)
=>
	(retract ?picked)
)

(defrule exec-fired (declare (salience -10))
	?f <- (path-picked)
=>
	(retract ?f)
)