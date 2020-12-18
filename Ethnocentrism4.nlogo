__includes["tests.nls"]

;; agents have a probablity to reproduce and a strategy
turtles-own [ ptr is-cosmopolitan? different-threshold tag-string ]

;; creates a world with exactly one agent on the corner patch
to setup
  clear-all
  ask patch 0 0 [ create-turtle ]
  reset-ticks
end


;; creates a new agent in the world
to create-turtle  ;; patch procedure
  sprout 1 [
    set tag-string random-tag-string
    set is-cosmopolitan? ifelse-value random 2 = 0 [true][false]
    ;; Set difference threshold to a random value in the range [0, num-tags + 1]
    set different-threshold random num-tags + 2
    ;; Set the color of the agent based on tag string
    update-color
    ;; change the shape of the agent on the basis of the strategy
    update-shape
  ]
end

to-report random-tag-string
  report n-values num-tags [ random 2 ]
end

;; the main routine
to go
  ;; Stop the simulation if turtles are extinct.
  if not any? turtles [ stop ]
  ;; reset the probability to reproduce
  ask turtles [ set ptr initial-ptr ]
  ;; have all of the agents interact with other agents if they can
  ask turtles [ interact ]
  ;; now they reproduce
  ask turtles [ reproduce ]
  ask turtles [ death ]          ;; kill some of the agents
  tick
end

to interact  ;; turtle procedure
  ;; interact with Von Neumann neighborhood
  ask turtles-on neighbors4 [
    ;; the commands inside the ASK are written from the point of view
    ;; of the agent being interacted with.  To refer back to the agent
    ;; that initiated the interaction, we use the MYSELF primitive.
    ;; cooperate or not based on color and strategy
    ;; TODO: Make this more readible (the two "myself"s in the following command refer to different objects)
    if [should-cooperate? myself] of myself [
      receive-help
    ]
  ]
end

to receive-help
  ;; Increase my PTR and reduce it for the one giving me help
  ask myself [ set ptr ptr - cost-of-giving ]
  set ptr ptr + gain-of-receiving
end

;; use PTR to determine if the agent gets to reproduce
to reproduce  ;; turtle procedure
  ;; if a random variable is less than the PTR the agent can reproduce
  if random-float 1.0 < ptr [
    ;; find an empty location to reproduce into
    let destination one-of neighbors4 with [not any? turtles-here]
    if destination != nobody [
      ;; if the location exists hatch a copy of the current turtle in the new location
      ;;  but mutate the child
      hatch 1 [
        move-to destination
        mutate
      ]
    ]
  ]
end

;; modify the children of agents according to the mutation rate
to mutate  ;; turtle procedure
  ;; Mutate the tag string
  set tag-string map [ i -> ifelse-value random-float 1.0 < mutation-rate [1 - i][i] ] tag-string
  ;; mutate the strategy flags;
  ;; Use a smaller mutation probability for is-cosmopolitan
  if random-float 1.0 < mutation-rate [ set is-cosmopolitan? not is-cosmopolitan? ]
  ;; Mutate by at most 1. Bound in the range [0, num-tags + 1]. Make the edges half as likely to mutate to ensure an even probability distribution.
  if random-float 1.0 < mutation-rate [
    ifelse random 2 = 0
    [ if different-threshold > 0 [ set different-threshold different-threshold - 1 ] ]
    [ if different-threshold <= num-tags [ set different-threshold different-threshold + 1 ] ]
  ]
  ;; Update the color in case the tag string changed
  update-color
  ;; make sure the shape of the agent reflects its strategy
  update-shape
end

to death  ;; turtle procedure
  ;; check to see if a random variable is less than the death rate for each agent
  if random-float 1.0 < death-rate [ die ]
end

to update-color
  ifelse num-tags = 0
  [ set color red ]
  [
    let hue 180 * first tag-string
    set color hsb hue 100 100
  ]
end

;; make sure the shape matches the strategy
to update-shape
  ;; if the agent cooperates with same they are a circle
  if is-cc? [ set shape "circle" ]  ;; filled in circle (altruist)
  if is-cd? [ set shape "circle 2" ]  ;; filled in circle (altruist)
  ;; if the agent doesn't cooperate with same they are a square
  if is-dc? [ set shape "square" ]  ;; filled in square (cosmopolitan)
  if is-dd? [ set shape "square 2" ]  ;; empty square (egoist)
end

;; Sub-commandss run in the turtle context for strategy determination
to-report is-different? [ other-turtle ]
  ;; Check if other-turtle is "different" according to MY difference threshold.
  report hamming-distance tag-string [tag-string] of other-turtle >= different-threshold
end

to-report should-cooperate? [ other-turtle ]
  ;; Check if THIS turtle should cooperate with other-turtle based on THIS turtle's strategy.
  let different? is-different? other-turtle
  report (not different? and not is-cosmopolitan?) or (different? and is-cosmopolitan?)
end

to-report hamming-distance [ list-1 list-2 ]
  report sum (map [ [x y] -> ifelse-value x = y [0][1] ] list-1 list-2)
end

;; convenience turtle reporters for the 1-tag case
to-report is-cc?
  report (different-threshold = 2 and not is-cosmopolitan?) or (different-threshold = 0 and is-cosmopolitan?)
end

to-report is-cd?
  report different-threshold = 1 and not is-cosmopolitan?
end

to-report is-dc?
  report different-threshold = 1 and is-cosmopolitan?
end

to-report is-dd?
  report (different-threshold = 2 and is-cosmopolitan?) or (different-threshold = 0 and not is-cosmopolitan?)
end
@#$#@#$#@
GRAPHICS-WINDOW
323
10
826
514
-1
-1
9.71
1
10
1
1
1
0
1
1
1
-25
25
-25
25
1
1
1
ticks
30.0

SLIDER
5
150
171
183
mutation-rate
mutation-rate
0.0
1.0
0.005
0.0010
1
NIL
HORIZONTAL

SLIDER
5
184
171
217
death-rate
death-rate
0.0
1.0
0.07
0.01
1
NIL
HORIZONTAL

SLIDER
172
150
318
183
initial-PTR
initial-PTR
0.0
1.0
0.13
0.01
1
NIL
HORIZONTAL

SLIDER
172
184
318
217
cost-of-giving
cost-of-giving
0.0
1.0
0.02
0.01
1
NIL
HORIZONTAL

SLIDER
172
218
318
251
gain-of-receiving
gain-of-receiving
0.0
1.0
0.04
0.01
1
NIL
HORIZONTAL

BUTTON
222
29
295
62
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
6
323
318
525
Strategy Counts
time
count
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"CC" 1.0 0 -10899396 true "" "plotxy ticks count turtles with [is-cc?]"
"CD" 1.0 0 -2674135 true "" "plotxy ticks count turtles with [is-cd?]"
"DC" 1.0 0 -1184463 true "" "plotxy ticks count turtles with [is-dc?]"
"DD" 1.0 0 -16777216 true "" "plotxy ticks count turtles with [is-dd?]"

SLIDER
5
252
318
285
immigrant-chance-cooperate-with-same
immigrant-chance-cooperate-with-same
0.0
1.0
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
5
286
318
319
immigrant-chance-cooperate-with-different
immigrant-chance-cooperate-with-different
0.0
1.0
0.5
0.01
1
NIL
HORIZONTAL

TEXTBOX
9
77
304
142
Circles cooperate with same color\nSquares defect with same color\nFilled-in shapes cooperate with different color\nEmpty shapes defect with different color\n
11
0.0
0

PLOT
9
535
323
763
Color Counts
time
count
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"red" 1.0 0 -2674135 true "" "plotxy ticks count turtles with [first tag-string = 0]"
"cyan" 1.0 0 -11221820 true "" "plotxy ticks count turtles with [first tag-string = 1]"

BUTTON
105
28
203
61
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
362
567
678
808
Cyan Strategy Counts
time
percentage
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"CC" 1.0 0 -10899396 true "" "plotxy ticks count turtles with [is-cc? and first tag-string = 1] / count turtles with [ first tag-string = 1 ] * 100"
"CD" 1.0 0 -2674135 true "" "plotxy ticks count turtles with [is-cd? and first tag-string = 1] / count turtles with [ first tag-string = 1 ] * 100"
"DC" 1.0 0 -1184463 true "" "plotxy ticks count turtles with [is-dc? and first tag-string = 1] / count turtles with [ first tag-string = 1 ] * 100"
"DD" 1.0 0 -16777216 true "" "plotxy ticks count turtles with [is-dd? and first tag-string = 1] / count turtles with [ first tag-string = 1 ] * 100"

PLOT
704
571
1047
809
Red Strategy Counts
time
percentage
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"CC" 1.0 0 -10899396 true "" "plotxy ticks count turtles with [is-cc? and first tag-string = 0] / count turtles with [ first tag-string = 0 ] * 100"
"CD" 1.0 0 -2674135 true "" "plotxy ticks count turtles with [is-cd? and first tag-string = 0] / count turtles with [ first tag-string = 0 ] * 100"
"DC" 1.0 0 -1184463 true "" "plotxy ticks count turtles with [is-dc? and first tag-string = 0] / count turtles with [ first tag-string = 0 ] * 100"
"DD" 1.0 0 -16777216 true "" "plotxy ticks count turtles with [is-dd? and first tag-string = 0] / count turtles with [ first tag-string = 0 ] * 100"

PLOT
832
28
1187
360
Total Population
time
count
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plotxy ticks count turtles"

SLIDER
5
219
170
252
num-tags
num-tags
0
20
1.0
1
1
NIL
HORIZONTAL

BUTTON
927
414
1009
447
NIL
run-tests
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model, due to Robert Axelrod and Ross A. Hammond, suggests that "ethnocentric" behavior can evolve under a wide variety of conditions, even when there are no native "ethnocentrics" and no way to differentiate between agent types.  Agents compete for limited space via Prisoner Dilemma's type interactions. "Ethnocentric" agents treat agents within their group more beneficially than those outside their group.  The model includes a mechanism for inheritance (genetic or cultural) of strategies.

## HOW IT WORKS

Each agent has three traits: a) color, b) whether they cooperate with same colored agents, and c) whether they cooperate with different colored agents.  An "ethnocentric" agent is one which cooperates with same colored agents, but does not cooperate with different colored agents. An "altruist" cooperates with all agents, while an "egoist" cooperates with no one.  A "cosmopolitan" cooperates with agents of a different color but not of their own color.

At each time step, the following events occur:

1. Up to IMMIGRANTS-PER-DAY, new agents appear in random locations with random traits.

2. Agents start with an INITIAL-PTR (Potential-To-Reproduce) chance of reproducing.  Each pair of adjacent agents interact in a one-move Prisoner's Dilemma in which each chooses whether or not to help the other.  They either gain, or lose some of their potential to reproduce.

3. In random order, each agent is given a chance to reproduce.  Offspring have the same traits as their parents, with a MUTATION-RATE chance of each trait mutating.  Agents are only allowed to reproduce if there is an empty space next to them.  Each agent's birth-rate is reset to the INITIAL-PTR.

4. The agent has a DEATH-RATE chance of dying, making room for future offspring and immigrants.

## HOW TO USE IT

To prepare the simulation for a new run, press SETUP EMPTY.  Press GO to start the simulation running, press GO again to stop it.

SETUP FULL will allow you to start with a full world of random agents.

COST-OF-GIVING indicates how much it costs an agent to cooperate with another agent.

GAIN-OF-RECEIVING indicates how much an agent gains if another agent cooperates with them.

IMMIGRANT-CHANCE-COOPERATE-WITH-SAME indicates the probability that an immigrating agent will have the COOPERATE-WITH-SAME? variable set to true.

IMMIGRANT-CHANCE-COOPERATE-WITH-DIFFERENT indicates the probability that an immigrating agent will have the COOPERATE-WITH-DIFFERENT? variable set to true.

The STRATEGY COUNTS plot tracks the number of agents that utilize a given cooperation strategy:

CC --- People who cooperate with everyone
CD --- People who cooperate only with people of the same type
DD --- People who do not cooperate with anyone
DC --- People who only cooperate with people of different types

## THINGS TO NOTICE

Agents appear as circles if they cooperate with the same color.  They are filled in if they also cooperate with a different color (altruists) or empty if they do not (ethnocentrics).  Agents are squares if they do not cooperate with the same color.  The agents are filled in if they cooperate with a different color (cosmopolitans) or empty if they do not (egoists).

Observe the interaction along the edge of a group of ethnocentric agents, and non-ethnocentric agents.  What behaviors do you see?  Is one more stable?  Does one expand into the other group?

Observer the STRATEGY COUNTS plot.  Does one strategy occur more than others?  What happens when we change the model?

## THINGS TO TRY

Set the IMMIGRANT-CHANCE-COOPERATE sliders both to 1.0.  This means there are only altruists created.  Do ethnocentrics and other strategies ever evolve?  Do they ever out compete the altruists?

Change the values of COST-OF-GIVING and GAIN-OF-RECEIVING and observe the effects on the model and the level of ethnocentricity.

This model comes with a group of BehaviorSpace experiments defined.  You can access them by choosing BehaviorSpace on the Tools menu.  These are the original experiments that Axelrod and Hammond ran to test the robustness of this model. These experiments vary lots of parameters like the size of the world, IMMIGRANTS-PER-DAY and COST-OF-GIVING.  These experiments are detailed at   http://www-personal.umich.edu/~axe/Shared_Files/Axelrod.Hammond/index.htm

## EXTENDING THE MODEL

Add more colors to the model.  Does the behavior change?

Make some patches richer than others, so that agents on them have a higher chance of reproducing.  Distribute this advantage across the world in different ways such as randomly, in blobs, or in quarters.

Tag patches with a color.  distribute the colors across the world in different ways: blobs, randomly, in discrete quarters.  Agents use the patch color under other agents to determine whether to cooperate with them or not.

## NETLOGO FEATURES

To ensure fairness, the agents should run in random order.  Agentsets in NetLogo are always in random order, so no extra code is needed to achieve this.

## RELATED MODELS

 * Segregation
 * PD Basic
 * Ethnocentrism - Alternative Visualization

## CREDITS AND REFERENCES

This model is a NetLogo version of the ethnocentrism model presented by Robert Axelrod at Northwestern University at the NICO (Northwestern Institute on Complex Systems) conference on October 25th, 2003.

See also Ross A. Hammond and Robert Axelrod, The Evolution of Ethnocentrism, http://www-personal.umich.edu/~axe/research/AxHamm_Ethno.pdf

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (2003).  NetLogo Ethnocentrism model.  http://ccl.northwestern.edu/netlogo/models/Ethnocentrism.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2003 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227.

<!-- 2003 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
setup-full repeat 150 [ go ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="functional change test" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>count turtles</metric>
    <metric>count turtles with [shape = "circle"]</metric>
    <metric>count turtles with [shape = "circle 2"]</metric>
    <metric>count turtles with [shape = "square"]</metric>
    <metric>count turtles with [shape = "square 2"]</metric>
    <metric>count turtles with [color = red]</metric>
    <metric>count turtles with [color = blue]</metric>
    <enumeratedValueSet variable="immigrant-chance-cooperate-with-different">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immigrant-chance-cooperate-with-same">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gain-of-receiving">
      <value value="0.01"/>
      <value value="0.03"/>
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-of-giving">
      <value value="0.01"/>
      <value value="0.02"/>
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-PTR">
      <value value="0.1"/>
      <value value="0.12"/>
      <value value="0.14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-rate">
      <value value="0"/>
      <value value="0.005"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.12"/>
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-seed">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
