(defmodule SEARCH (import REASONING ?ALL) (import PICK-GOAL ?ALL) (export ?ALL))

(deftemplate search-node
	(slot id) (slot pos-r) (slot pos-c) (slot direction (allowed-values north south east west)) 
	(slot loaded (allowed-values yes no)) (slot f-cost) (slot g-cost) (slot father) (slot open (allowed-values yes no))
)
(deftemplate search-node-new
	(slot id) (slot pos-r) (slot pos-c) (slot direction (allowed-values north south east west)) 
	(slot loaded (allowed-values yes no)) (slot f-cost) (slot g-cost) (slot father)
)
(deftemplate search-node-current (slot id))
(deftemplate search-action (slot id) (slot pos-r) (slot pos-c) (slot direction (allowed-values north south east west)))

(deffacts init-costs
	(init-cost (goal-type explore) (cost 0))
	(init-cost (goal-type unload_debris) (cost 16))
	(init-cost (goal-type debris) (cost 0))
	(init-cost (goal-type drill) (cost 60))
	(init-cost (goal-type done) (cost 10))
	(max-cost 10000)
)

(deftemplate current-search-goal (slot id) (slot pos-r) (slot pos-c) (slot goal-type))
(deftemplate current-lowest-cost (slot cost))
(deftemplate plan-counter (slot count))

(defrule request-planning
	(not (current-goal-candidate))
	(not (planning-requested))
	?plan-counter <- (plan-counter (count ?count&:(> ?count 0)))
=>
	(modify ?plan-counter (count (- ?count 1)))
	(assert (planning-requested))
)

(defrule request-planning-extra (declare (salience 0))
	?plan-counter <- (plan-counter (count ?count&:(= ?count 0)))
	(not (path (goal-type ?goal-type&:(neq ?goal-type done))))
=>
	(modify ?plan-counter (count 1))
)

(defrule current-goal-candidate-deactivated (declare (salience 150))
	?current-goal <- (current-goal-candidate (id ?id))
	(goal-candidate (id ?id) (activated no))
=>
	;(printout t "Current goal was satisfied or unreacheable" crlf)
	(retract ?current-goal)
)

(defrule pick-goal-candidate-keep-old (declare (salience 100))
	(AGENT-OPTION_single-goal)
	(current-goal-candidate (id ?id))
	(K-agent (step ?step))
	(goal-candidate (id ?id) (pos-r ?goal-r) (pos-c ?goal-c) (goal-type ?goal-type) (activated yes))
=>
	(assert
		(search-goal (created-at-step ?step) (pos-r ?goal-r) (pos-c ?goal-c) (goal-type ?goal-type))
		(goal-candidate-processed (id ?id))
	)
)
(defrule current-goal-candidate-search-failed-0 (declare (salience 50))
	(AGENT-OPTION_single-goal)
	?current-goal <- (current-goal-candidate (id ?id))
	(goal-candidate (id ?id) (pos-r ?goal-r) (pos-c ?goal-c) (goal-type ?goal-type))
	(not (path (pos-r ?goal-r) (pos-c ?goal-c) (goal-type ?goal-type)))
=>
	(retract ?current-goal)
)
(defrule current-goal-candidate-search-failed-1 (declare (salience 50))
	(AGENT-OPTION_single-goal)
	?current-goal <- (current-goal-candidate (id ?id))
	(not (goal-candidate (id ?id)))
=>
	(retract ?current-goal)
)

(defrule calculate-goal-distance (declare (salience 100))
	(not (current-goal-candidate))
	(K-agent (pos-r ?r) (pos-c ?c))
	(goal-candidate (id ?id) (pos-r ?goal-r) (pos-c ?goal-c) (goal-type ~done) (activated yes))
=>
	(assert (goal-distance (id ?id) (distance (distance ?r ?c ?goal-r ?goal-c))))
)

(defrule pick-goal-candidate-in-order
	(not (current-goal-candidate))
	(K-agent (step ?step))
	?request <- (planning-requested)
	(goal-candidate (id ?id) (goal-type ?goal-type) (pos-r ?goal-r) (pos-c ?goal-c) (activated yes))
	(not (goal-candidate-processed (id ?id)))
	?goal-distance <- (goal-distance (id ?id) (distance ?distance))
	(not(and
		(goal-distance (id ?id-other&:(neq ?id ?id-other)) (distance ?distance-other&:(< ?distance-other ?distance)))
		(not (goal-candidate-processed (id ?id-other)))
	))
=>
	(assert 
		(search-goal (created-at-step ?step) (pos-r ?goal-r) (pos-c ?goal-c) (goal-type ?goal-type))
		(goal-candidate-processed (id ?id))
	)
	(retract ?request ?goal-distance)
)

(defrule pick-goal-candidate-home-plan
	(recalculate-home-plan)
	(goal-candidate (pos-r ?goal-r) (pos-c ?goal-c) (goal-type done) (activated yes))
	(K-agent (step ?step))
=>
	(assert (search-goal (created-at-step ?step) (pos-r ?goal-r) (pos-c ?goal-c) (goal-type done)))
)

(defrule search-init-globals (declare (salience 200))
	(AGENT-OPTION_max-plans ?max-plans)
	(max-cost ?max-cost)
	(K-agent)
=>
	(assert 
		(plan-counter (count ?max-plans))
		(current-lowest-cost (cost ?max-cost))
	)
)

(defrule start-search (declare (salience 150))
	?search-goal <- (search-goal (pos-r ?goal-r) (pos-c ?goal-c) (goal-type ?goal-type))
	(init-cost (goal-type ?goal-type) (cost ?init-cost))
	(bias-cost (goal-type ?goal-type) (cost ?bias-cost))
	(K-agent (pos-r ?agent-r) (pos-c ?agent-c) (direction ?direction) (loaded ?loaded))
	(test (not (and (= ?agent-r ?goal-r) (= ?agent-c ?goal-c))))
=>
	(bind ?path-id (gensym*))
	(bind ?id (gensym*))
	(bind ?g-init (+ ?init-cost ?bias-cost))
	(bind ?distance (distance ?agent-r ?agent-c ?goal-r ?goal-c))
	(assert
		(search-node (id ?id) (pos-r ?agent-r) (pos-c ?agent-c) (direction ?direction) (loaded ?loaded)
			(f-cost (+ ?g-init ?distance)) (g-cost ?g-init) (father NA))
		(search-node-current (id ?id))
		(current-search-goal (id ?path-id) (pos-r ?goal-r) (pos-c ?goal-c) (goal-type ?goal-type))
	)
	(retract ?search-goal)
	(focus SEARCH-EXPAND)
)

(defrule goal-reached-from-current-position (declare (salience 150))
	?search-goal <- (search-goal (pos-r ?r) (pos-c ?c) (goal-type ?goal-type&drill|unload_debris|done))
	(init-cost (goal-type ?goal-type) (cost ?init-cost))
	(bias-cost (goal-type ?goal-type) (cost ?bias))
	(K-agent (step ?step) (pos-r ?r) (pos-c ?c))
=>
	(bind ?path-id (gensym*))
	(assert 
		(path (id ?path-id) (created-at-step ?step) (goal-type ?goal-type) (pos-r ?r) (pos-c ?c) (cost ?init-cost) (biased-cost (+ ?init-cost ?bias)))
		(path-step (path-id ?path-id) (step 1) (direction ?goal-type))
	)
	(retract ?search-goal)
)

(defrule go-to-create-solution(declare (salience 200))
	?f <- (path-found)
=>
	(halt)
	(retract ?f)
	(focus CREATE-SOLUTION)
)

(defrule clean-up-current-lowest-cost (declare (salience -200))
	?f <- (current-lowest-cost)
=>
	(retract ?f)
)

(defrule clean-up-plan-counter (declare (salience -200))
	?f <- (plan-counter)
=>
	(retract ?f)
)

;------ SEARCH-EXPAND -----------
(defmodule SEARCH-EXPAND (import SEARCH ?ALL) (export ?ALL))

(defrule node-worse-than-global (declare (salience 150))
	?node <- (search-node(f-cost ?cost) (open yes))
	(current-lowest-cost (cost ?min-cost&:(> ?cost ?min-cost)))
=>
	(modify ?node (open no))
)

(defrule action-move (declare (salience 100)) ;TODO: Safe search per i goal-type done
	(current-search-goal (goal-type ~done))
	(direction ?direction)
	(direction-offset (direction ?direction) (pos-r ?offset-r) (pos-c ?offset-c))
	(search-node-current (id ?id))
	(search-node (id ?id) (pos-r ?r) (pos-c ?c) (loaded ?loaded) (open yes))
	(K-agent (step ?step))
	(or 
		(K-cell (pos-r =(+ ?r ?offset-r)) (pos-c =(+ ?c ?offset-c)) (contains empty|gate|unknown))
		(and
			(test (eq ?loaded no))
			(K-cell (pos-r =(+ ?r ?offset-r)) (pos-c =(+ ?c ?offset-c)) (contains debris) (injured no)) ;TODO: |unknown ?
		)
	)
	(not (K-person (step ?step) (pos-r =(+ ?r ?offset-r)) (pos-c =(+ ?c ?offset-c))))
=>
	(assert (search-action (id ?id) (pos-r ?r) (pos-c ?c) (direction ?direction)))
)

(defrule action-move-safe (declare (salience 100))
	(current-search-goal (goal-type done))
	(direction ?direction)
	(direction-offset (direction ?direction) (pos-r ?offset-r) (pos-c ?offset-c))
	(search-node-current (id ?id))
	(search-node (id ?id) (pos-r ?r) (pos-c ?c) (open yes))
	(K-agent (step ?step))
	(K-cell (pos-r =(+ ?r ?offset-r)) (pos-c =(+ ?c ?offset-c)) (contains empty|gate))
	(not (K-person (step ?step) (pos-r =(+ ?r ?offset-r)) (pos-c =(+ ?c ?offset-c))))
=>
	(assert (search-action (id ?id) (pos-r ?r) (pos-c ?c) (direction ?direction)))
)


(deffunction loaded-change (?loaded ?cell-type)
	(if (eq ?loaded yes) then (return yes))
	(if (eq ?cell-type debris) then	(return yes) else (return no))
)
(defrule action-move-exec (declare (salience 50))
	(direction ?direction-to)
	(direction-offset (direction ?direction-to) (pos-r ?offset-r) (pos-c ?offset-c))
	(search-node-current (id ?id))
	(search-node (id ?id) (g-cost ?g) (pos-r ?r) (pos-c ?c) (direction ?direction-from) (loaded ?loaded))
	?action <- (search-action (id ?id) (pos-r ?r) (pos-c ?c) (direction ?direction-to))
	(K-cell (pos-r =(+ ?r ?offset-r)) (pos-c =(+ ?c ?offset-c)) (contains ?cell-type))
	(current-search-goal (pos-r ?goal-r) (pos-c ?goal-c))
	(move-cost (direction-from ?direction-from) (direction-to ?direction-to) (cell-type ?cell-type) (loaded ?loaded) (cost ?cost))
=>
	(bind ?new-id (gensym*))
	(bind ?new-r (+ ?r ?offset-r))
	(bind ?new-c (+ ?c ?offset-c))
	(bind ?new-g (+ ?g ?cost))
	(bind ?goal-distance (distance ?new-r ?new-c ?goal-r ?goal-c))
	(assert
		(search-node-new (id ?new-id) (pos-r ?new-r) (pos-c ?new-c) (father ?id) (direction ?direction-to) (loaded (loaded-change ?loaded ?cell-type))
			(f-cost (+ ?goal-distance ?new-g)) (g-cost ?new-g)
		)
	)
	(retract ?action)
)

(defrule go-to-check (declare (salience 100))
	(search-node-new)
=>
	(focus SEARCH-CHECK)
)

(defrule set-current-node (declare (salience 25))
	?old-current <- (search-node-current (id ?old-id))
	?old-node <- (search-node (id ?old-id) (f-cost ?old-f))
	(search-node (id ?new-id&:(neq ?new-id ?old-id)) (f-cost ?new-f) (open yes))
	(not 
		(search-node (id ?other-id&:(neq ?other-id ?old-id)) (f-cost ?other-f&:(< ?other-f ?new-f)) (open yes))
	)
=>
	(modify ?old-current (id ?new-id))
	(modify ?old-node (open no))
)

(defrule out-of-nodes (declare (salience 25))
	?current <- (search-node-current (id ?current-id))
	?current-node <- (search-node (id ?current-id))
	(not
		(search-node (id ?id&:(neq ?id ?current-id)) (open yes))
	)
=>
	(retract ?current)
	(modify ?current-node (open no))
	;(printout t "Search failed: out of nodes" crlf)
	(halt)
	(focus CLEAN-UP-SEARCH-FACTS)
)

; ------ SEARCH-CHECK ------------
(defmodule SEARCH-CHECK (import SEARCH-EXPAND ?ALL) (export ?ALL))

(defrule goal-not-reached (declare (salience 100))
	(search-node-new (id ?id) (pos-r ?r) (pos-c ?c))
	(current-search-goal (pos-r ?goal-r) (pos-c ?goal-c))
	(test (not (and (= ?r ?goal-r) (= ?c ?goal-c))))
=>
	(focus SEARCH-NEW)
)

(defrule goal-reached (declare (salience 50))
	(current-search-goal (pos-r ?r) (pos-c ?c))
	?new-node <- (search-node-new (id ?id) (pos-r ?r) (pos-c ?c) (g-cost ?g) (father ?father))
	?current-node <- (search-node-current)
=>
	(bind ?final-cost ?g)
	(assert 
		(search-node (id ?id) (pos-r ?r) (pos-c ?c) (g-cost ?final-cost) (f-cost ?final-cost) (father ?father) (open no))
		(path-found)
	)
	(modify ?current-node (id ?id))
	(retract ?new-node)
	(pop-focus)
	(pop-focus)
)

; ------ SEARCH-NEW --------------
(defmodule SEARCH-NEW (import SEARCH-CHECK ?ALL) (export ?ALL))

(defrule check-node-closed (declare (salience 100))
	?new-node <- (search-node-new (id ?id) (pos-r ?r) (pos-c ?c) (direction ?direction) (loaded ?loaded))
	(search-node (pos-r ?r) (pos-c ?c) (direction ?direction) (loaded ?loaded) (open no))
=>
	(retract ?new-node)
	(pop-focus)
	(pop-focus)
)

(defrule check-node-open-worse (declare (salience 100))
	?new-node <- (search-node-new (id ?id) (pos-r ?r) (pos-c ?c) (direction ?direction) (loaded ?loaded) (g-cost ?g))
	(search-node (pos-r ?r) (pos-c ?c) (direction ?direction) (loaded ?loaded) (g-cost ?old-g) (open yes))
	(test (or (> ?g ?old-g) (= ?g ?old-g)))
=>
	(retract ?new-node)
	(pop-focus)
)

(defrule check-node-open-better (declare (salience 100))
	?new-node <- (search-node-new (id ?id) (pos-r ?r) (pos-c ?c) (direction ?direction) (loaded ?loaded) (g-cost ?g) (f-cost ?f) (father ?father))
	?old-node <- (search-node (id ?id) (pos-r ?r) (pos-c ?c) (direction ?direction) (loaded ?loaded) (g-cost ?old-g) (open yes))
	(test (< ?g ?old-g))
=>
	(assert (search-node (id ?id) (pos-r ?r) (pos-c ?c) (direction ?direction) (loaded ?loaded) (g-cost ?g) (f-cost ?f) (father ?father) (open yes)))
	(retract ?new-node ?old-node)
	(pop-focus)
	(pop-focus)
)

(defrule check-node-new (declare (salience 50))
	?new-node <- (search-node-new (id ?id) (pos-r ?r) (pos-c ?c) (direction ?direction) (loaded ?loaded) (g-cost ?g) (f-cost ?f) (father ?father))
=>
	(assert (search-node (id ?id) (pos-r ?r) (pos-c ?c) (direction ?direction) (loaded ?loaded) (g-cost ?g) (f-cost ?f) (father ?father)))
	(retract ?new-node)
	(pop-focus)
	(pop-focus)
)

; ------ CREATE-SOLUTION ----------
(defmodule CREATE-SOLUTION (import SEARCH ?ALL) (export ?ALL))

(deftemplate solution-step-counter (slot count) (slot id)))
(defrule solution-step-count-init (declare (salience 50))
	(search-node-current (id ?id))
=>
	(assert (solution-step-counter (count 0) (id ?id)))
)
(defrule solution-step-count (declare (salience 50))
	?counter <- (solution-step-counter (count ?count) (id ?id))
	(search-node (id ?id) (father ?father&~NA))
=>
	(modify ?counter (count (+ ?count 1)) (id ?father)))
)
(defrule solution-step-count-done (declare (salience 25))
	?counter <- (solution-step-counter (count ?count) (id ?id))
	(search-node-current (id ?reset-id))
	(not (create-path))
=>
	(assert (create-path))
	(modify ?counter (id ?reset-id))
)

(defrule create-path (declare (salience 200))
	(current-search-goal (id ?path-id) (goal-type ?goal-type) (pos-r ?r) (pos-c ?c))
	(search-node-current (id ?node-id))
	(search-node (id ?node-id) (f-cost ?cost))
	(init-cost (goal-type ?goal-type) (cost ?init))
	(bias-cost (goal-type ?goal-type) (cost ?bias))
	(K-agent (step ?step))
=>
	(bind ?actual-cost (- ?cost ?bias))
	(assert (path (id ?path-id) (created-at-step ?step) (goal-type ?goal-type) (pos-r ?r) (pos-c ?c) (cost ?actual-cost) (biased-cost ?cost)))
)

(defrule new-best-path ; NB: viene utilizzato il costo biased durante la ricerca
	(current-search-goal (id ?path-id))
	(path (id ?path-id) (cost ?new-cost))
	?lowest-cost <- (current-lowest-cost (cost ?old-cost&:(< ?new-cost ?old-cost)))
=>
	(modify ?lowest-cost (cost ?new-cost))
)

(defrule create-path-step (declare (salience 100))
	(create-path)
	(current-search-goal (id ?path-id))
	?counter <- (solution-step-counter (count ?count) (id ?to-id))
	(search-node (id ?to-id) (pos-r ?to-r) (pos-c ?to-c) (father ?from-id))
	(search-node (id ?from-id) (pos-r ?from-r) (pos-c ?from-c))
	(direction-offset (direction ?direction) (pos-r =(- ?to-r ?from-r)) (pos-c =(- ?to-c ?from-c)))
	(K-agent (step ?created-at-step))
=>
	(assert (path-step (path-id ?path-id) (step ?count) (direction ?direction)))
	(modify ?counter (count (- ?count 1)) (id ?from-id))
)

(defrule go-to-clean-up (declare (salience -100))
	(current-search-goal)
=>
	(focus CLEAN-UP-SEARCH-FACTS)
)

;(defrule print-path
;	(path-step (path-id ?path-id) (step ?step) (direction ?direction))
;=>
;	(printout t "path-step: (" ?path-id ") " ?step ": " ?direction crlf)
;)


(defmodule CLEAN-UP-SEARCH-FACTS (import SEARCH ?ALL) (import CREATE-SOLUTION ?ALL) (export ?ALL))

(defrule clean-up-search-action
	?action <- (search-action)
=>
	(retract ?action)
)

(defrule clean-up-node (declare (salience 10))
	?node <- (search-node)
=>
	(retract ?node)
)
(defrule clean-up-node-current (declare (salience 10))
	?node <- (search-node-current)
=>
	(retract ?node)
)
(defrule clean-up-counter (declare (salience 10))
	?counter <- (solution-step-counter)
=>
	(retract ?counter)
)
;(defrule clean-up-search-goal (declare (salience 10))
;	?search-goal <- (search-goal)
;=>
;	(retract ?search-goal)
;)
(defrule clean-up-current-search-goal (declare (salience 10))
	?search-goal-handler <- (current-search-goal)
=>
	(halt)
	(retract ?search-goal-handler)
)
(defrule clean-up-create-path (declare (salience 0))
	?f <- (create-path)
=>
	(halt)
	(retract ?f)
)