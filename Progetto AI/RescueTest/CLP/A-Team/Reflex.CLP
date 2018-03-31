; ------ REFLEX ----------
(defmodule REFLEX (import REASONING ?ALL) (export ?ALL))

(deftemplate unload-candidate-spot (slot pos-r) (slot pos-c))

(defrule reflex-action-inform-checked (declare (salience 50))
	?cell <- (K-cell (pos-r ?r) (pos-c ?c) (contains debris) (injured no) (checked ~yes))
	(not (cell-informed (pos-r ?r) (pos-c ?c)))
	(K-agent (step ?step))
	(not (test-exec (step ?step)))
=>
	(assert
		(cell-informed (pos-r ?r) (pos-c ?c) (info checked))
		(test-exec (step ?step) (action inform) (param1 ?r) (param2 ?c) (param3 checked))
	)
	(modify ?cell (checked yes))
)

(defrule reflex-action-inform-discover (declare (salience 100))
	?cell <- (K-cell (pos-r ?r) (pos-c ?c) (contains debris) (injured yes) (discovered ~yes))
	(not (cell-informed (pos-r ?r) (pos-c ?c)))
	(K-agent (step ?step))
	(not (test-exec (step ?step)))
=>
	(assert
		(cell-informed (pos-r ?r) (pos-c ?c) (info discover))
		(test-exec (step ?step) (action inform) (param1 ?r) (param2 ?c) (param3 discover))
	)
	(modify ?cell (discovered yes))
)

(defrule reflex-action-inform-clear (declare (salience 25))
	(AGENT-OPTION_inform-clear)
	?cell <- (K-cell (pos-r ?r) (pos-c ?c) (contains empty) (clear ~yes))
	(not (cell-informed (pos-r ?r) (pos-c ?c)))
	(K-agent (step ?step))
	(not (test-exec (step ?step)))
	(not (unload-candidate-spot (pos-r ?r) (pos-c ?c))) ;TODO: in caso ci serva per unload! magari opzionale?
=>
	(assert
		(cell-informed (pos-r ?r) (pos-c ?c) (info clear))
		(test-exec (step ?step) (action inform) (param1 ?r) (param2 ?c) (param3 clear))
	)
	(modify ?cell (clear yes))
)

; ----- INFER DEBRIS STATUS -----
(defrule cell-is-discovered-north (declare (salience 200))
	(K-cell (pos-r ?r) (pos-c ?c) (sound yes))
	(or (K-cell (pos-r =(- ?r 1)) (pos-c ?c) (contains ~debris)) (K-cell (pos-r =(- ?r 1)) (pos-c ?c) (contains debris) (injured no))) ;south
	(or (K-cell (pos-r ?r) (pos-c =(+ ?c 1)) (contains ~debris)) (K-cell (pos-r ?r) (pos-c =(+ ?c 1)) (contains debris) (injured no))) ;east
	(or (K-cell (pos-r ?r) (pos-c =(- ?c 1)) (contains ~debris)) (K-cell (pos-r ?r) (pos-c =(- ?c 1)) (contains debris) (injured no))) ;west
	?cell <- (K-cell (pos-r =(+ ?r 1)) (pos-c ?c) (contains debris) (injured unknown))
=>
	(modify ?cell (injured yes))
)
(defrule cell-is-discovered-south (declare (salience 200))
	(K-cell (pos-r ?r) (pos-c ?c) (sound yes))
	(or (K-cell (pos-r =(+ ?r 1)) (pos-c ?c) (contains ~debris)) (K-cell (pos-r =(+ ?r 1)) (pos-c ?c) (contains debris) (injured no))) ;north
	(or (K-cell (pos-r ?r) (pos-c =(+ ?c 1)) (contains ~debris)) (K-cell (pos-r ?r) (pos-c =(+ ?c 1)) (contains debris) (injured no))) ;east
	(or (K-cell (pos-r ?r) (pos-c =(- ?c 1)) (contains ~debris)) (K-cell (pos-r ?r) (pos-c =(- ?c 1)) (contains debris) (injured no))) ;west
	?cell <- (K-cell (pos-r =(- ?r 1)) (pos-c ?c) (contains debris) (injured unknown))
=>
	(modify ?cell (injured yes))
)
(defrule cell-is-discovered-east (declare (salience 200))
	(K-cell (pos-r ?r) (pos-c ?c) (sound yes))
	(or (K-cell (pos-r =(+ ?r 1)) (pos-c ?c) (contains ~debris)) (K-cell (pos-r =(+ ?r 1)) (pos-c ?c) (contains debris) (injured no))) ;north
	(or (K-cell (pos-r =(- ?r 1)) (pos-c ?c) (contains ~debris)) (K-cell (pos-r =(- ?r 1)) (pos-c ?c) (contains debris) (injured no))) ;south
	(or (K-cell (pos-r ?r) (pos-c =(- ?c 1)) (contains ~debris)) (K-cell (pos-r ?r) (pos-c =(- ?c 1)) (contains debris) (injured no))) ;west
	?cell <- (K-cell (pos-r ?r) (pos-c =(+ ?c 1)) (contains debris) (injured unknown))
=>
	(modify ?cell (injured yes))
)
(defrule cell-is-discovered-west (declare (salience 200))
	(K-cell (pos-r ?r) (pos-c ?c) (sound yes))
	(or (K-cell (pos-r =(+ ?r 1)) (pos-c ?c) (contains ~debris)) (K-cell (pos-r =(+ ?r 1)) (pos-c ?c) (contains debris) (injured no))) ;north
	(or (K-cell (pos-r =(- ?r 1)) (pos-c ?c) (contains ~debris)) (K-cell (pos-r =(- ?r 1)) (pos-c ?c) (contains debris) (injured no))) ;south
	(or (K-cell (pos-r ?r) (pos-c =(+ ?c 1)) (contains ~debris)) (K-cell (pos-r ?r) (pos-c =(+ ?c 1)) (contains debris) (injured no))) ;east
	?cell <- (K-cell (pos-r ?r) (pos-c =(- ?c 1)) (contains debris) (injured unknown))
=>
	(modify ?cell (injured yes))
)

(defrule cell-is-checked (declare (salience 200))
	(K-agent (pos-r ?r) (pos-c ?c))
	(direction ?direction)
	(direction-offset (direction ?direction) (pos-r ?offset-r) (pos-c ?offset-c))
	(K-cell (pos-r ?r) (pos-c ?c) (sound no))
	?cell <- (K-cell (pos-r =(+ ?r ?offset-r)) (pos-c =(+ ?c ?offset-c)) (contains debris) (injured unknown))
=>
	(modify ?cell (injured no))
)

; Goal candidates
(defrule add-goal-candidate-explore
	(K-cell (pos-r ?r) (pos-c ?c) (contains unknown))
=>
	(assert (goal-candidate (goal-type explore) (pos-r ?r) (pos-c ?c) (activated yes)))
)
(defrule deactivate-goal-candidate-explore
	(K-cell (pos-r ?r) (pos-c ?c) (contains ~unknown))
	?candidate <- (goal-candidate (goal-type explore) (pos-r ?r) (pos-c ?c) (activated yes))
=>
	(modify ?candidate (activated no)))
)

(defrule add-goal-candidate-debris
	(K-cell (pos-r ?debris-r) (pos-c ?debris-c) (contains debris) (injured unknown))
	(direction-offset (pos-r ?offset-r) (pos-c ?offset-c))
	(not (goal-candidate (pos-r =(+ ?debris-r ?offset-r)) (pos-c =(+ ?debris-c ?offset-c)) (goal-type debris)))
=>
	(assert (goal-candidate (pos-r (+ ?debris-r ?offset-r)) (pos-c (+ ?debris-c ?offset-c)) (goal-type debris) (activated yes)))
)

(defrule deactivate-goal-candidate-debris-0
	?candidate <- (goal-candidate (pos-r ?r) (pos-c ?c) (goal-type debris) (activated yes))
	(or 
		(K-cell (pos-r ?r) (pos-c ?c) (sound ~unknown))
		(K-cell (pos-r ?r) (pos-c ?c) (contains wall|outdoor))
		(K-cell (pos-r ?r) (pos-c ?c) (contains debris) (injured yes))
	)
=>
	(modify ?candidate (activated no))
)
(defrule deactivate-goal-candidate-debris-1
	?candidate <- (goal-candidate (pos-r ?r) (pos-c ?c) (goal-type debris) (activated yes))
	(direction-offset (pos-r ?offset-r) (pos-c ?offset-c))
	(K-cell (pos-r =(+ ?r ?offset-r)) (pos-c =(+ ?c ?offset-c)) (contains debris) (injured yes))
=>
	(modify ?candidate (activated no))
)
(defrule deactivate-goal-candidate-debris-2
	?candidate <- (goal-candidate (pos-r ?r) (pos-c ?c) (goal-type debris) (activated yes))
	(not
		(or
			(K-cell (pos-r =(+ ?r 1)) (pos-c ?c) (contains debris) (injured unknown))
			(K-cell (pos-r =(- ?r 1)) (pos-c ?c) (contains debris) (injured unknown))
			(K-cell (pos-r ?r) (pos-c =(+ ?c 1)) (contains debris) (injured unknown))
			(K-cell (pos-r ?r) (pos-c =(- ?c 1)) (contains debris) (injured unknown))
		)
	)
=>
	(modify ?candidate (activated no))
)

(defrule add-goal-candidate-drill
	(K-cell (pos-r ?r) (pos-c ?c) (contains debris) (injured unknown))
	(direction-offset (pos-r ?offset-r) (pos-c ?offset-c))
	(not (goal-candidate (pos-r =(+ ?r ?offset-r)) (pos-c =(+ ?c ?offset-c)) (param1 ?r) (param2 ?c) (goal-type drill)))
=>
	(assert (goal-candidate (pos-r (+ ?r ?offset-r)) (pos-c (+ ?c ?offset-c)) (goal-type drill) (param1 ?r) (param2 ?c) (activated yes)))
)
(defrule deactivate-goal-candidate-drill
	?candidate <- (goal-candidate (pos-r ?r) (pos-c ?c) (goal-type drill) (param1 ?drill-r) (param2 ?drill-c) (activated yes))
	(or 
		(K-cell (pos-r ?r) (pos-c ?c) (contains debris) (injured yes))
		(K-cell (pos-r ?r) (pos-c ?c) (contains wall|outdoor))
		(K-cell (pos-r ?drill-r) (pos-c ?drill-c) (contains debris) (injured ~unknown))
	)
=>
	(modify ?candidate (activated no))
)

(defrule add-goal-candidate-done
	(K-cell (pos-r ?r) (pos-c ?c) (contains gate))
	(not (goal-candidate (pos-r ?r) (pos-c ?c) (goal-type done)))
=>
	(assert (goal-candidate (pos-r ?r) (pos-c ?c) (goal-type done) (activated yes)))
)


;A B C 
;D E F 
;G H I 
(defrule goal-candidate-unload-pattern-0 (declare (salience 200))
	(direction ?direction)
	;(offset-around (direction ?direction) (position forward-left) (offset-r ?offset-A-r) (offset-c ?offset-A-c))
	(offset-around (direction ?direction) (position forward) (offset-r ?offset-B-r) (offset-c ?offset-B-c))
	;(offset-around (direction ?direction) (position forward-right) (offset-r ?offset-C-r) (offset-c ?offset-C-c))
	(offset-around (direction ?direction) (position left) (offset-r ?offset-D-r) (offset-c ?offset-D-c))
	(offset-around (direction ?direction) (position right) (offset-r ?offset-F-r) (offset-c ?offset-F-c))
	(offset-around (direction ?direction) (position behind-left) (offset-r ?offset-G-r) (offset-c ?offset-G-c))
	(offset-around (direction ?direction) (position behind) (offset-r ?offset-H-r) (offset-c ?offset-H-c))
	(offset-around (direction ?direction) (position behind-right) (offset-r ?offset-I-r) (offset-c ?offset-I-c))

	(K-cell (pos-r ?r) (pos-c ?c) (contains empty|gate))
	;(K-cell (pos-r =(+ ?r ?offset-A-r)) (pos-c =(+ ?c ?offset-A-c)) (contains NA))
	(K-cell (pos-r =(+ ?r ?offset-B-r)) (pos-c =(+ ?c ?offset-B-c)) (contains wall))
	;(K-cell (pos-r =(+ ?r ?offset-C-r)) (pos-c =(+ ?c ?offset-C-c)) (contains NA))
	(K-cell (pos-r =(+ ?r ?offset-D-r)) (pos-c =(+ ?c ?offset-D-c)) (contains wall))

	(K-cell (pos-r =(+ ?r ?offset-F-r)) (pos-c =(+ ?c ?offset-F-c)) (contains empty|gate))
	(K-cell (pos-r =(+ ?r ?offset-G-r)) (pos-c =(+ ?c ?offset-G-c)) (contains empty|gate))
	(K-cell (pos-r =(+ ?r ?offset-H-r)) (pos-c =(+ ?c ?offset-H-c)) (contains empty|gate))
	(K-cell (pos-r =(+ ?r ?offset-I-r)) (pos-c =(+ ?c ?offset-I-c)) (contains empty|gate))
=>
	(assert (unload-candidate-spot (pos-r ?r) (pos-c ?c)))
)
(defrule goal-candidate-unload-pattern-1 (declare (salience 200))
	(direction ?direction)
	;(offset-around (direction ?direction) (position forward-left) (offset-r ?offset-A-r) (offset-c ?offset-A-c))
	(offset-around (direction ?direction) (position forward) (offset-r ?offset-B-r) (offset-c ?offset-B-c))
	(offset-around (direction ?direction) (position forward-right) (offset-r ?offset-C-r) (offset-c ?offset-C-c))
	(offset-around (direction ?direction) (position left) (offset-r ?offset-D-r) (offset-c ?offset-D-c))
	(offset-around (direction ?direction) (position right) (offset-r ?offset-F-r) (offset-c ?offset-F-c))
	;(offset-around (direction ?direction) (position behind-left) (offset-r ?offset-G-r) (offset-c ?offset-G-c))
	(offset-around (direction ?direction) (position behind) (offset-r ?offset-H-r) (offset-c ?offset-H-c))
	(offset-around (direction ?direction) (position behind-right) (offset-r ?offset-I-r) (offset-c ?offset-I-c))

	(K-cell (pos-r ?r) (pos-c ?c) (contains empty|gate))
	;(K-cell (pos-r =(+ ?r ?offset-A-r)) (pos-c =(+ ?c ?offset-A-c)) (contains NA))
	(K-cell (pos-r =(+ ?r ?offset-B-r)) (pos-c =(+ ?c ?offset-B-c)) (contains empty|gate))
	(K-cell (pos-r =(+ ?r ?offset-C-r)) (pos-c =(+ ?c ?offset-C-c)) (contains empty|gate))
	(K-cell (pos-r =(+ ?r ?offset-D-r)) (pos-c =(+ ?c ?offset-D-c)) (contains wall))

	(K-cell (pos-r =(+ ?r ?offset-F-r)) (pos-c =(+ ?c ?offset-F-c)) (contains empty|gate))
	;(K-cell (pos-r =(+ ?r ?offset-G-r)) (pos-c =(+ ?c ?offset-G-c)) (contains NA))
	(K-cell (pos-r =(+ ?r ?offset-H-r)) (pos-c =(+ ?c ?offset-H-c)) (contains empty|gate))
	(K-cell (pos-r =(+ ?r ?offset-I-r)) (pos-c =(+ ?c ?offset-I-c)) (contains empty|gate))
=>
	(assert (unload-candidate-spot (pos-r ?r) (pos-c ?c)))
)
(defrule goal-candidate-unload-pattern-2 (declare (salience 200))
	(direction ?direction)
	(offset-around (direction ?direction) (position forward-left) (offset-r ?offset-A-r) (offset-c ?offset-A-c))
	(offset-around (direction ?direction) (position forward) (offset-r ?offset-B-r) (offset-c ?offset-B-c))
	(offset-around (direction ?direction) (position forward-right) (offset-r ?offset-C-r) (offset-c ?offset-C-c))
	;(offset-around (direction ?direction) (position left) (offset-r ?offset-D-r) (offset-c ?offset-D-c))
	(offset-around (direction ?direction) (position right) (offset-r ?offset-F-r) (offset-c ?offset-F-c))
	(offset-around (direction ?direction) (position behind-left) (offset-r ?offset-G-r) (offset-c ?offset-G-c))
	(offset-around (direction ?direction) (position behind) (offset-r ?offset-H-r) (offset-c ?offset-H-c))
	(offset-around (direction ?direction) (position behind-right) (offset-r ?offset-I-r) (offset-c ?offset-I-c))

	(K-cell (pos-r ?r) (pos-c ?c) (contains empty|gate))
	(K-cell (pos-r =(+ ?r ?offset-A-r)) (pos-c =(+ ?c ?offset-A-c)) (contains empty|gate))
	(K-cell (pos-r =(+ ?r ?offset-B-r)) (pos-c =(+ ?c ?offset-B-c)) (contains empty|gate))
	(K-cell (pos-r =(+ ?r ?offset-C-r)) (pos-c =(+ ?c ?offset-C-c)) (contains empty|gate))
	;(K-cell (pos-r =(+ ?r ?offset-D-r)) (pos-c =(+ ?c ?offset-D-c)) (contains NA))

	(K-cell (pos-r =(+ ?r ?offset-F-r)) (pos-c =(+ ?c ?offset-F-c)) (contains empty|gate))
	(K-cell (pos-r =(+ ?r ?offset-G-r)) (pos-c =(+ ?c ?offset-G-c)) (contains empty|gate))
	(K-cell (pos-r =(+ ?r ?offset-H-r)) (pos-c =(+ ?c ?offset-H-c)) (contains empty|gate))
	(K-cell (pos-r =(+ ?r ?offset-I-r)) (pos-c =(+ ?c ?offset-I-c)) (contains empty|gate))
=>
	(assert (unload-candidate-spot (pos-r ?r) (pos-c ?c)))
)
(defrule goal-candidate-unload-pattern-3 (declare (salience 200))
	(direction ?direction)
	(offset-around (direction ?direction) (position forward-left) (offset-r ?offset-A-r) (offset-c ?offset-A-c))
	;(offset-around (direction ?direction) (position forward) (offset-r ?offset-B-r) (offset-c ?offset-B-c))
	(offset-around (direction ?direction) (position forward-right) (offset-r ?offset-C-r) (offset-c ?offset-C-c))
	(offset-around (direction ?direction) (position left) (offset-r ?offset-D-r) (offset-c ?offset-D-c))
	(offset-around (direction ?direction) (position right) (offset-r ?offset-F-r) (offset-c ?offset-F-c))
	(offset-around (direction ?direction) (position behind-left) (offset-r ?offset-G-r) (offset-c ?offset-G-c))
	;(offset-around (direction ?direction) (position behind) (offset-r ?offset-H-r) (offset-c ?offset-H-c))
	(offset-around (direction ?direction) (position behind-right) (offset-r ?offset-I-r) (offset-c ?offset-I-c))

	(K-cell (pos-r ?r) (pos-c ?c) (contains empty|gate))
	(K-cell (pos-r =(+ ?r ?offset-A-r)) (pos-c =(+ ?c ?offset-A-c)) (contains wall))
	;(K-cell (pos-r =(+ ?r ?offset-B-r)) (pos-c =(+ ?c ?offset-B-c)) (contains NA))
	(K-cell (pos-r =(+ ?r ?offset-C-r)) (pos-c =(+ ?c ?offset-C-c)) (contains empty|gate))
	(K-cell (pos-r =(+ ?r ?offset-D-r)) (pos-c =(+ ?c ?offset-D-c)) (contains wall))

	(K-cell (pos-r =(+ ?r ?offset-F-r)) (pos-c =(+ ?c ?offset-F-c)) (contains empty|gate))
	(K-cell (pos-r =(+ ?r ?offset-G-r)) (pos-c =(+ ?c ?offset-G-c)) (contains wall))
	;(K-cell (pos-r =(+ ?r ?offset-H-r)) (pos-c =(+ ?c ?offset-H-c)) (contains NA))
	(K-cell (pos-r =(+ ?r ?offset-I-r)) (pos-c =(+ ?c ?offset-I-c)) (contains empty|gate))
=>
	(assert (unload-candidate-spot (pos-r ?r) (pos-c ?c)))
)
(defrule goal-candidate-unload-outdoor
	(K-cell (pos-r ?r) (pos-c ?c) (contains outdoor))
	(not (unload-candidate-spot (pos-r ?r) (pos-c ?c)))
	(direction-offset (pos-r ?offset-r) (pos-c ?offset-c))
	(K-cell (pos-r =(+ ?r ?offset-r)) (pos-c =(+ ?c ?offset-c)) (contains gate|empty))
=>
	(assert (unload-candidate-spot (pos-r ?r) (pos-c ?c)))
)

(defrule add-goal-candidate-unload
	(unload-candidate-spot (pos-r ?unload-r) (pos-c ?unload-c))
	(direction-offset (pos-r ?offset-r) (pos-c ?offset-c))
	(K-cell (pos-r ?unload-r) (pos-c ?unload-c) (contains outdoor|empty) (clear ~yes))
	(K-cell (pos-r =(+ ?unload-r ?offset-r)) (pos-c =(+ ?unload-c ?offset-c)) (contains empty|gate))
	(not (goal-candidate (pos-r =(+ ?unload-r ?offset-r)) (pos-c =(+ ?unload-c ?offset-c)) (goal-type unload_debris) (param1 ?unload-r) (param2 ?unload-c)))
=>
	(assert (goal-candidate (pos-r (+ ?unload-r ?offset-r)) (pos-c (+ ?unload-c ?offset-c)) (goal-type unload_debris) (param1 ?unload-r) (param2 ?unload-c) (activated yes)))
)

(defrule deactivate-goal-candidate-unload
	(K-agent (loaded no))
	?candidate <- (goal-candidate (goal-type unload_debris) (activated yes))
=>
	(modify ?candidate (activated no))	
)
defrule deactivate-goal-candidate-unload-person
	(K-agent (loaded no))
	?candidate <- (goal-candidate (goal-type unload_debris) (param1 ?unload-r) (param2 ?unload-c) (activated yes))
	(K-person (pos-r ?unload-r) (pos-c ?unload-c))
=>
	(modify ?candidate (activated no))	
)
defrule deactivate-goal-candidate-unload-informed-clear
	(K-agent (loaded no))
	?candidate <- (goal-candidate (goal-type unload_debris) (param1 ?unload-r) (param2 ?unload-c) (activated yes))
	(K-cell (pos-r ?unload-r) (pos-c ?unload-c) (clear yes))
=>
	(modify ?candidate (activated no))	
)
(defrule reactivate-goal-candidate-unload
	(K-agent (loaded yes))
	?candidate <- (goal-candidate (goal-type unload_debris) (param1 ?unload-r) (param2 ?unload-c) (activated no))
	(K-cell (pos-r ?unload-r) (pos-c ?unload-c) (contains outdoor|empty) (clear no|unknown|nil))
	(not (K-person (pos-r ?unload-r) (pos-c ?unload-c)))
=>
	(modify ?candidate (activated yes))	
)

;(defrule deactivate-goal
;	?goal <- (search-goal (goal-type ?type) (pos-r ?r) (pos-c ?c))
;	?candidate <- (goal-candidate (goal-type ?type) (pos-r ?r) (pos-c ?c) (activated no))
;=>
;	(retract ?goal)
;)

(defrule goal-candidate-assign-id (declare (salience 100))
	?candidate <- (goal-candidate (id nil))
=>
	(bind ?id (gensym*))
	(modify ?candidate (id ?id))
)
