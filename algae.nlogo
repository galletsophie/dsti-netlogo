breed [ algae alga ]
breed [ astres astre ]

globals
[
  water-line                ; where the water starts
  is-day?
  ;; below: species specific, could create a new breed
  growth-rate
  topt
  tmin
  tmax
  mu-opt
  Iopt
  alpha
  light
  ;; temp variables necessary for growth computation
  phi
  light-coef
  light-inhib-threshold ; level above which light inhibition occurs (slow to no growth)
]

to startup
  setup
end

to setup
  clear-all
  set water-line round (1 / 3 * max-pycor )
  initialize
  reset-ticks
end

to initialize
  set-default-shape astres "circle"
  set-default-shape algae "circle"

  ;; create sky, water
  ask patches
  [
    ifelse pycor > water-line
    [ set pcolor sky + 2]                        ; sky
    [ set pcolor scale-color blue pycor -20 20 ] ; water
  ]

  ;; Create the sun
  create-astres 1
  [
    setxy (max-pxcor - 5) (max-pycor - 5)
    display-sun
  ]
  set is-day? true

  create-algae init-algae-number ; create *number* microalgae
  [ setup-alga ]

  ;; set variables needed for growth computation

  setup-species
  set light sun-intensity * 4    ; transform user-friendly sun-intensity (%) into usable value (in muE/m2/s)
end

to setup-alga
  setxy random-xcor random (min-pycor - water-line - 1 ) + water-line ; algae in water
  ifelse species = "N.oceanica"   ; two colors to differenciate them
  [set color green]
  [set color green - 2]
end

;; Ideal growth conditions vary from one species to another
to setup-species
  ifelse species = "N.oceanica"
  [
    set topt 26.7    ; degree C
    set tmin 0       ; degree C
    set tmax 33.3    ; degree C
    set mu-opt 1.85  ; /day
    set alpha 0.12
    set Iopt 203     ; muE/m2/s
    set light-inhib-threshold 350  ; above it, no growth (simplification)
  ]
  [
    set topt 38.5
    set tmin 5.2
    set tmax 45.8
    set mu-opt 2.00
    set alpha 0.05
    set Iopt 275
    set light-inhib-threshold 380  ; above it, no growth (simplification)
  ]
end


;; --------------------------------------------------------
;; GO
;; --------------------------------------------------------
to go
  if not any? algae [stop]  ; stop if all algae are dead
  set-day-or-night          ; environment change between day /night + cellular division triggered by night-time
  update-temp
  grow-size                 ; size growth during the day (as microalgae 'collect' nutrients and light)
  die-low-probability       ; to make growth less 'rectangular' and closer to real life
  move-algae
  tick
end

;; --------------------------------------------------------
;; GO algae procedures
;; --------------------------------------------------------

;; during the day, microalgae 'feed' on nutrients and light, and increase in size (one type of growth)
;; as we're in nutrient unlimited conditions, we assume algae can feed as much as needed
;; we introduce the effect of light and some uncertainty to determine growth increase
;; Note that this is mostly to demonstrate growth by size, not rigorous scientifically
to grow-size
  if is-day?
  [ ask algae
    [if size = 1 and random (105 - sun-intensity) = 1 [set size 2]]
  ]
end

to die-low-probability
  ask algae
  [
    if random 50000 = 1 [die]
  ]
end

to update-temp
  ifelse is-day?  ; warmer temp /sun during the day
  [
    set sun-intensity sun-intensity + random 2
    set water-temperature water-temperature + random 2
  ]
  [
    set sun-intensity sun-intensity - random 2
    set water-temperature water-temperature - random 2
  ]

end

to move-algae
  ask algae [
    setxy random-xcor random (min-pycor - water-line ) + water-line ; algae in water
  ]
end

;; at the end of the day, microalgae 'reproduce' by dividing into 2 organisms (one type of growth)
;; Note that this happens once a day, end of day, if growth-rate = ln(2)
;; and potentially at different times if growth-rate ≠ ln(2)
;; To simplify, we'll adapt the number of new individuals created based on the computed growth-rate
;; Finally, note that the computed growth rate takes into account mortality
to grow-algae
  compute-growth water-temperature light
  ifelse growth-rate > 0
  [ create-algae init-algae-number * exp growth-rate
    [ setup-alga ]
  ]
  [ ask algae
    [ if random 2 = 1 [die]]
  ]
end


;; math formula to compute growth coefficient based on temperature and light intensity
to compute-growth [t i]
  ifelse t < tmin or t > tmax or i > light-inhib-threshold
  [
    set growth-rate 0                 ; no growth below/above extremes
  ]
  [
    set phi (t - tmax) * (t - tmin) * (t - tmin) / ( (topt - tmin) * ( (topt - tmin) * (t - topt) - (topt - tmax) * (topt + tmin - 2 * t)))
    set growth-rate mu-opt * phi
    set light-coef i / (i + growth-rate / alpha * (i / Iopt - 1) * (i / Iopt - 1) )
    set growth-rate growth-rate * light-coef
    ]
end




;; --------------------------------------------------------
;; GO Night/Day procedures
;; --------------------------------------------------------

to set-day-or-night
  ifelse ticks mod 24 = 1
  [
    if ticks > 2
    [set-day-mode
    set is-day? true]
  ]
  [
    if ticks mod 12 = 1
    [set-night-mode
    set is-day? false]
  ]
end

to set-day-mode
  ask patches [
  ifelse pycor  > water-line
    [set pcolor sky + 2]
    [set pcolor scale-color blue pycor -20 20]
  ]
  set sun-intensity max list 5 (50 + random 50) ; reset the sun-intensity at beginning of day
  ask astres [ display-sun ]
end

to set-night-mode
  grow-algae
  ask algae [                     ; algae typically 'reproduce' at the end of the day (when they do it once a day)
    set size 1                    ; simulating the duplication of algae by resetting all sizes to 1
  ]
  ask patches [
  ifelse pycor  > water-line      ; darker sky & water
    [set pcolor black + 2]
    [set pcolor 102 ]
  ]
  set sun-intensity max list 1 (0 + random 5) ; reset the moon-intensity at beginning of day
  ask astres [                    ; moon
    set color white
    set size 5
  ]

end

to display-sun  ;; sun procedure
  set color scale-color yellow sun-intensity 0 150
  set size sun-intensity / 10
  ifelse sun-intensity < 50
    [ set label-color yellow ]
    [ set label-color orange  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
300
10
796
507
-1
-1
8.0
1
12
1
1
1
0
1
1
1
-30
30
-30
30
1
1
1
hours
30.0

SLIDER
10
10
285
43
init-algae-number
init-algae-number
0
100
50.0
1
1
NIL
HORIZONTAL

BUTTON
50
235
138
268
setup
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

BUTTON
145
235
235
268
go
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
820
10
1090
130
Microalgae Growth
Hour
Number
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"algae" 1.0 0 -15040220 true "" "plot count algae"

SLIDER
10
110
285
143
water-temperature
water-temperature
0
50
26.7
.1
1
°C
HORIZONTAL

PLOT
820
150
1090
270
Conditions
Hours
% /  C
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"light" 1.0 0 -955883 true "" "plot sun-intensity"
"temp" 1.0 0 -13791810 true "" "plot water-temperature"

SLIDER
10
155
280
188
sun-intensity
sun-intensity
0
100
69.0
1
1
%
HORIZONTAL

CHOOSER
10
55
130
100
species
species
"N.oceanica" "C.pyrenoidosa"
0

@#$#@#$#@
## WHAT IS IT?

This model demonstrates the growth of a population of microalgae based on some of its environmental conditions, namely water temperature and light. This model assumes microalgae grow in nutrient unlimited conditions. 

Microalgae are used for water treatment and to produce biodiesel, and can be studied to better understand the impact of the climate crisis on living creatures. Good modeling of microalgae growth is thus critical.

Note that this model is based on scientific research (see reference), but changes have been made to simplify and adapt the papers to a netlogo model.  


## HOW IT WORKS

The model creates an initial population of algae of one of two species, in ocean water, under a sun of varying intensity (and the moon at night). 

The population grows depending on two two combined variables: water temperature and light intensity. 

In optimal temperature and light conditions, which are species dependent, the algae will thrive and, in the absence of food scarsity and predator, it will slowly fill the whole ocean.

Alternatively, in tougher conditions, which are also species dependent, the algae growth will be much slower to null. 

Finally, in extreme conditions, the algae population will not survive.


## HOW TO USE IT

GO: starts and stops the simulation.

SETUP: resets the simulation according to the parameters set by the sliders.

INIT-ALGAE-NUMBER: sets the initial number of algae to be created.

WATER-TEMPERATURE: sets the temperature in degree C, at setup and possibly during simulation
 
SUN-INTENSITY: set the sun intensity, or light intensity, at setup and possibly during simulation. The value, stripped of its %, is multiplied by 4 to reach a usable value for computation

SPECIES: 
Two different species whose growth is affected very differently by light intensity and temperature. 
- "N.oceanica" 
Its optimal temperature for growth is 26.7 degree C, at which temperature it grows by a growth-rate of 1.85 /day. It will slowly die at temperature below 0 or above 33.3 degree C. Its optimal light intensity is 203 muE/m2/s, almost equivalent to 50% sun-intensity.
- "C.pyrenoidosa" 
Its optimal temperature for growth is 38.5, at which temperature it grows by a growth-rate of 2 /day.

Note that the growth-rate number cannot be used as is, and is instead used in some computation that then define the number of dead/ new algae. 

## THINGS TO NOTICE

Growth for microalgae happens in 2 ways: during the day, provided they have enough nutrients and light, cells may grow in size. At some time in the day, usually the end, the cells "reproduce" through cell division. 

Temperature and light-intensity fluctuates during the day and night. 


## THINGS TO TRY

**GROWTH**
With species N.oceanica, try with the optimal growth temperature (26.7 degree C) and then change other parameters to see whether they still manage to thrive.
Try all optimal parameters (26.7 degree C, sun-intensity 50%) and see how fast they make up for all or most of the ocean.

With species C.pyrenoidosa, try the optimal light intensity (50%) and then change other parameters to see whether they still manage to thrive. Or the other way around (38.5 degree C for optimal temperature). Does one of the two variables seem to have a higher impact on growth? 

**DEATH**
Can you guess the extreme temperatures at which growth is not possible? Many algae species have a minimal temperature for growth around 0-5 degree C, and a maximum around 30-35 degree C. 

Above a certain intensity, light is no longer a friend to microalgae, and photo-inhibition happens. That too is species dependent. For N.oceanica it's when sun intensity is more than 88%. It's higher for the second species.  



## EXTENDING THE MODEL

These are some of the ways to extend this model further. 

- Extend the model to additional microalgae species (more research available on this).
- Introduce two species and see the impact of this on their growth (more research available on this).
- Demonstrate the impact of different / additional enablers and stressors on microalgae growth. 
- Introduce different environments, industrial ones such as bioreactors or raceways, or location-specific ones for natural environments. 
- Introduce seasonality, with fluctuation in temperature, sun-intensity, day length based on seasons. 


## NETLOGO FEATURES

Some more complicated than average math formulas were used to compute the growth rate. 

## CREDITS AND REFERENCES

Bernard, O., Rémond, B., 2012. Validation of a simple model accounting for light and temperature effect on microalgal growth. Bioresource Technology.

Model based partly on Autumn, Ant Adaptation, and Fireflies, credits below:

* Martin, K. and Wilensky, U. (2019). NetLogo Ant Adaptation model. http://ccl.northwestern.edu/netlogo/models/AntAdaptation. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL. 

* Wilensky, U. (2005). NetLogo Autumn model. http://ccl.northwestern.edu/netlogo/models/Autumn. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL. 

* Wilensky, U. (1997). NetLogo Fireflies model. http://ccl.northwestern.edu/netlogo/models/Fireflies. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL. 

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:
* Gallet, S. (2019). NetLogo Algae model. Data ScienceTech Institute, Sophia Antipolis, France. 

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2019 Sophie Gallet. 

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
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
@#$#@#$#@
@#$#@#$#@
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
1
@#$#@#$#@
