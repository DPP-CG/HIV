;; THIS IS MAIN FILE. MOST procedure called from here
__includes
[
  "global-initialization.nls" "initial-people.nls" "breed-people.nls" ; initialization
  "main-code-helper-functions.nls" "transmission-helper-functions.nls"; helper functions
  "update-simulation.nls" "manage-age-group.nls" "manage-care-continuum.nls" "Data.nls"; disease progression and bucket approach
  "manage-partnership.nls" ; partnership assignment
  "generate-transmission.nls" "initialize-transmissions.nls"; bernoulli model for HIV transmission
  "sensitivity-analysis.nls" ; Sensitivity analysis
  "generate-output.nls" "write-output.nls" "write-output-headers.nls" "verify-plot.nls" ; Transmission rate output
  "testing-frequency.nls" "set-dropout-care.nls" "cohort-analysis.nls" ; Cohort analysis: testing vs. VLS
  "network-generation.nls" "network-report.nls" "breed-T-tree-links.nls" "network-helper-functions.nls" ; Molecular project: network generation
  "readECNAnetwork.nls" "ECNA-generateNetwork-v2.nls" "write-ECNA-clusters.nls" "Visualization.nls"
  "dynamicpartners.nls" "partnership-behaviour.nls" "output-behavior.nls"
]

;; Extensions of NetLogo used
extensions [matrix csv profiler table]

;; Check runtime of each procedure (to identify procedures that take too long)
to profile

  profiler:start; start profiling
  repeat 1 [runExperiment]; excute procedure runExperiment to measure run time
  profiler:stop; stop profiling
  print profiler:report; view the results
  profiler:reset; clear the data

end

;; Initially settiing up x number of people
to setup

  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)

  clear-ticks
  clear-turtles
  clear-patches
  clear-drawing
  clear-all-plots ;__clear-all-and-reset-ticks  ;;clear all

  set-default-shape turtles "circle"
  setup-intermediate-globals
  setup-static-globals
  initialize-num-HIV ;; function in "main-code-helper-functions.nls": initialize number of HIV infected persons
  setup-initial-people ;;function in 'initialize-people-HET-MSM.nls': matches the initial population to represent 2006 HIV

  ;check-setup ;; see next procedure below: used for verification
  setup-people ;; procedure below
               ;; next few setup are some of the plots.
               ;;However most of the results analysis has been conducted in excel files. (See ReadMe.doc in the folder)
               ;setup-plot
               ;setplot-het-stage
               ;setplot-MSM-stage
               ;setplot-CD4-diagnosis-HET
               ;setplot-CD4-diagnosis-MSM
               ;setplot-PLWH

end

;; Repeat simulation for x times
to runExperiment

  initialize-output ; procedure in "write-output.nls"
  setup-sensitive-global-var ; procedure in "sensitivity-analysis.nls"
  initialize-sensitive-globals ; procedure in "sensitivity-analysis.nls"
  assign-sensitive-globals ; procedure in "sensitivity-analysis.nls"

  if goal = 1
  [
    carefully [file-delete "results-ptnr-one.csv"] []
    carefully [file-delete "results-PLWH-one.csv"] []
    carefully [file-delete "results-new-infections-one.csv"] []
  ]

  if goal = 2
  [
    carefully [file-delete "results-ptnr-two.csv"] []
    carefully [file-delete "results-PLWH-two.csv"] []
    carefully [file-delete "results-new-infections-two.csv"] []
  ]

  if goal = 3
  [
    carefully [file-delete "results-ptnr-three.csv"] []
    carefully [file-delete "results-PLWH-three.csv"] []
    carefully [file-delete "results-new-infections-three.csv"] []
  ]

  if goal = 4
  [
    carefully [file-delete "results-ptnr-four.csv"] []
    carefully [file-delete "results-PLWH-four.csv"] []
    carefully [file-delete "results-new-infections-four.csv"] []
  ]

  if goal = 5
  [
    carefully [file-delete "results-ptnr-five.csv"] []
    carefully [file-delete "results-PLWH-five.csv"] []
    carefully [file-delete "results-new-infections-five.csv"] []
  ]

  ;; Cohort analysis
  ;carefully [file-delete "results-cohort-info.csv"] []
  ;write-cohort-header ; procedure in "chort-analysis.nls"

  ;; Molecular
  carefully [file-delete "TransmissionClusters.csv"] []
  write-cluster-statistics-header

  ;; Repeat simulation maxRun number of times
  set tempRun 0
  while [tempRun < maxRun]
  [
    setup ; procedure in "main-code-helper-functions.nls"
    reset-ticks; for PATH
    repeat maxTicks [go]; for PATH

    importNetwork ; testing scale-free network


    generate-cluster ; procedure in "network-generate.nls"

    set tempRun tempRun + 1
    print (word "Completed run #:" tempRun)
  ]

  ;; Write output in csv files
  write-PLWH-header ; procedure in "write-output-header.nls"
  write-results-PLWH ; procedure in "write-output.nls"
  write-new-infections-header ; procedure in "write-output-header.nls"
  write-results-new-infections ; procedure in "write-output.nls"
  write-ptnr-header ; procedure in "write-output-header.nls"
  write-results-ptnr ; procedure in "write-output.nls"

end

to testECNA
  clear
  file-close-all
  ; carefully [file-delete "TransmissionClusters.csv"] []
  ; write-cluster-statistics-header
  ; carefully [file-delete "TransmissionClustersShort.csv"] []
  ; write-cluster-header-Short


  let j 0
  repeat 1[
    let i 0
    repeat 1[
      ask turtles [die]
      ;clear
      setup-ECNA-globals
      set transmission-rate transmission-rate - i * 0.005
      ;set i i + 1
      setupECNA
      runECNA
      let numDiag count people with [aware? = true]
      ask n-of (numDiag * 0.4) people with [aware? = true][
        set aware? false
        set time-at-diagnosis 0]
      ask ECNA-links[set breed Ttree-links]
      ;  killSusceptibles
      ;reportECNA
      ;runClusterCodes
    ]
    ; set j j + 1
    ;set TimeToDiagnosis TimeToDiagnosis  - time-unit

  ]

end
to runECNA
  ;write-partnership-behavior-header
  tick

  ;while [ticks < (num-year-trans + dry-run) * time-unit] [goECNA]
  if count people >=  termination-node [stop]
  if count non-agent-susceptibles < 1000 [
    create-non-agent-susceptibles (termination-node * 10)[
    ]
  ]

;  ;; estimating ticks equivalent of number of infections in 10 years (say 2010 and 2015) assuming 50000 new infections per year
;  ;; trans-year will then use persons infected  in 10 years
;;  let found false
;  if (trans-year-threshold = 0 and count people > (1 - (50000 * 10) / 1100000) * termination-node)[
;    set trans-year-threshold floor ((ticks + 1) / time-unit) / 2
; ;   set found true
;  ]
  set trans-year-threshold 0
  goECNA
  ;;;;calculate infected people
  ;write-partnership-behavior-output
  stageColor
   ask ECNA-links[set breed Ttree-links]
end

to killSusceptibles
  ask susceptibles [die]
  ask non-agent-susceptibles[die]
end


to reportECNA
  ; writeECNA
  ; reset-ticks
  ; repeat maxTicks [tick]; disconnect PATH for ECNA testing
  importNetwork ; testing scale-free network
end

to runClusterCodes
  generate-cluster ; procedure in "network-generate.nls"
  report-ECNA-Clusters; write clusters hshort version
                      ;  visualizeCluster
  print "total people"
  print count people
  print "total people with trans year >= 1"
  print count people with [trans-year >= trans-year-threshold]


end

;; Main procedure to carry out the simulation, repeated every time unit
to go

  tick ; increment time counter

  ;; The first 100 ticks (each tick is a month) to stablize agent behaviors
  if ticks < sim-dry-run
  [first-100-ticks] ; procedure in "main-code-helper-functions"

  ;; Tick 101
  if ticks = sim-dry-run
  [tick-101] ; procedure in "main-code-helper-functions"

  ;; After sim-dry-run, start transmissions
  if ticks > sim-dry-run
  [
    ;; Molecular: identify the largest component of the diagnosed subnetwork
    if ticks = sim-dry-run + 1
    [set giant-start-node person 0]

    ;; Calculate the number of PLWH by sex/risk group
    set ptnrs-per-month n-values 8 [0]
    set total-people people with [dead = 0 and infected? = true]
    let i 0
    repeat num-sex
    [
      set total-people-sex replace-item i total-people-sex total-people with [sex = i + 1]
      set i i + 1
    ]

    ;; First dry-run (15) years as a dry run for persons to age properly, keep prevalence the same as 2006
    ;; Procedures used here are in "main-code-helper-functions.nls"
    ifelse ticks < t-start
    [dry-run-keep-prevalence]
    [
      update-stage-props (floor((ticks - t-start) / time-unit))
      count-num-HIV
      ;count-num-sharing-HIV
    ]

    ;; Change needle transmission rates after dry run
    if ticks = t-start
    [set trans-rate-needle trans-rate-needle-after-dry-run]
    if (ticks - sim-dry-run) mod time-unit = 0 and ticks >= t-start and ticks < tick-start
    [set trans-rate-needle trans-rate-needle * percent-sharing-decline]

    ;; Change the CD4 guideline to start ART treatment throughout the years
    if ticks = t-start + time-unit * 3 + 1
    [set CD4-start-ART-guideline CD4-start-ART-guideline2]
    if ticks = t-start + time-unit * 6 + 1
    [set CD4-start-ART-guideline CD4-start-ART-guideline3]

    ;; Update sexual behavior based on age
    ;; Procedures used here are in "manage-partnership.nls"
    ask total-people with [age mod 1 = 0]
    [
      set-num-ptnr
      set-sexual-behavior
    ]

    ;; Managing proportion of individuals with concurrent ptnrs
    ;; Procedures used here are in "manage-partnership.nls"
    set i 0
    repeat num-sex
    [
      manage-concurrency i
      set i i + 1
    ]

    ;; Main procedure to update disease progression. This is the disease progression model (PATH 1.0)
    ;; Procedure used here is in "update-simulation.nls".
    ask total-people
    [
      ;; monthly parameters to track infections
      set num-trans-One 0
      set num-trans-Two 0
      set num-trans-Casual 0
      set num-trans-Needle 0
      ;; disease progression within each PLWH
      update-simulation
    ]

    ;; Before calibration-year
    ;; "Bucket approach" to match proportion of PLWH along each stage of the HIV care continuum
    ;; 1) people when diagnosed are assigned probability they link to care within a month to 3;
    ;; 2) people who drop-out of care are asigned when they come back to care based on CD4 count.
    ;;
    ;; After calibration-year
    ;; 1) implement testing frequency for persons infected after 2015 to get persons diagnosed
    ;; 2) randomly assign next testing day for persons infected before 2015
    ;; 3) implement drop out of care for persons on ART
    ;;
    ;; Procedures used here are in "managed-care-continuum.nls"

    if ticks = tick-start
    [
      ask people with [dead = 0 and infected? = true and stage <= 2 and trans-year <= dry-run + calibration-year - start-year]
      [set next-test ticks + 1 + random (test-freq-pre2015 - 1)]
    ]

    set i 0
    ifelse ticks < tick-start
    [
      repeat num-sex
      [
        manage-undiag i
        manage-no-care i
        manage-care-noART i
        manage-not-VLS-dropOut i
        manage-VLS-dropOut i
        set i i + 1
      ]
    ]
    [
      manage-linkToCare
      manage-ART-post2015
      manage-dropOut-post2015
    ]

    ;; Carry out simulation on transmission.
    ;; Procedures used here are in "transmission-helper-functions.nls"

    accum-person-years ;  accumulating person-years for each continuum stages, each age group, and each sex/risk group
    acute-infection ; for individuals in acute phase infection cutting down to weekly time unit and estimating transmissions every week
    non-acute-infection ; for individuals not in acute phase estimating tarnsmissions every month

    ;; Controlling for distribution of age at infection
    ;; Procedure used here is in "manage-age-group.nls"
    if (ticks - sim-dry-run + 1) mod time-unit = 0
    [
      ifelse ticks < t-start
      [set PLWH 1]
      [set PLWH 2]
      manage-age-group
    ]

    ;; As trasnmissions occurred the dummy people from reserve (who were infected and in no way part of simulation)
    ;; were taken and set as infected to denote the infected person. Here creating more people in reserve.
    ;; Procedure used here is in "main-code-helper-functions.nls"
    if (count people with [infected? = false]) <= 3 * number-people * 1 / 12
    [setup-people]

    ;; Generating output every year. Since each tick is assumed a month we write outputs only every year
    ;; Generarte transmissions for num-year-trans years.
    ;; Procedures used here are in "generate-output.nls"
    if (ticks - sim-dry-run) mod time-unit = 0
    [
      if ticks >= t-start - 1
      [
        let year (ticks - t-start + 1) / time-unit
        ;; all PLWH
        set total-people people with [infected? = true and dead = 0]
        set total-pop count total-people
        set i 0
        repeat num-stage
        [
          set total-people-stage replace-item i total-people-stage total-people with [stage = i + 1]
          set i i + 1
        ]
        set i 0
        repeat num-sex
        [
          set total-people-sex replace-item i total-people-sex total-people with [sex = i + 1]
          set i i + 1
        ]
        set i 0
        repeat num-age
        [
          set total-people-age replace-item i total-people-age total-people with [age >= item i age-LB and age < item i age-UB]
          set i i + 1
        ]
        generate-PLWH year

        ;; all new infections
        set newly-infected people with [infected? = true and trans-year = ceiling ((ticks - sim-dry-run) / time-unit)]
        set newly-dead people with [infected? = true and dead-year = ceiling ((ticks - sim-dry-run) / time-unit)]
        set i 0
        repeat num-sex
        [
          set newly-infected-sex replace-item i newly-infected-sex newly-infected with [sex = i + 1]
          set i i + 1
        ]
        set i 0
        repeat num-age
        [
          set newly-infected-age replace-item i newly-infected-age newly-infected with [age < item i age-UB and age >= item i age-LB]
          set i i + 1
        ]
        generate-new-infections year

        generate-ptnrs year
      ]

      ;; Resetting counters every year
      set count-trans-by-stage n-values num-stage [0]
      set count-trans-by-sex n-values num-sex [0]
      set count-trans-by-age n-values num-age [0]
      set count-trans-by-ptnr-type [0 0 0 0 0 0 0]

      set count-person-years-by-stage n-values num-stage [0]
      set count-person-years-by-age n-values num-age [0]
      set count-person-years-by-sex n-values num-sex [0]

      set numACTStable3 [0 0 0 0 0 0]
      set numTranstable3 [0 0 0 0 0 0]
      set countNewDiagnosis [0 0 0 0 0 0];

      ask people with [infected? = true]
      [
        set counter-ptnr replace-item 0 counter-ptnr (item 0 ptnr-array)
        set counter-ptnr replace-item 1 counter-ptnr (item 1 ptnr-array)
        set counter-ptnr replace-item 2 counter-ptnr 0
        set counter-ptnr replace-item 3 counter-ptnr 0
      ]
    ]
  ]

  ;; Procedure for cohort analysis: testing vs. VLS
  ;collect-cohort-stats

end
@#$#@#$#@
GRAPHICS-WINDOW
198
13
805
474
-1
-1
10.512
1
10
1
1
1
0
0
0
1
-28
28
-21
21
1
1
1
ticks
30.0

PLOT
1108
799
1425
919
CD4 count at diagnosis - Heterosexuals
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"<=200" 1.0 0 -16777216 true "" ""
"200-350" 1.0 0 -13345367 true "" ""
"350-500" 1.0 0 -5825686 true "" ""
">500" 1.0 0 -10899396 true "" ""

INPUTBOX
1435
529
1522
589
number-people
1000.0
1
0
Number

BUTTON
1564
745
1627
778
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

PLOT
1426
849
1767
974
People living with HIV/AIDS
Years
Number
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"MSM" 1.0 0 -13791810 true "" ""
"Heterosexual-female" 1.0 0 -13345367 true "" ""
"ALL" 1.0 0 -16777216 true "" ""
"Heterosexual-male" 1.0 0 -10899396 true "" ""

BUTTON
1637
747
1700
780
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
1

INPUTBOX
1438
601
1526
661
simulation-years
0.0
1
0
Number

INPUTBOX
1536
524
1586
584
time-unit
12.0
1
0
Number

PLOT
999
1080
1439
1338
Transmissions
NIL
NIL
0.0
0.0
0.0
0.0
true
true
"" ""
PENS
"ALL" 1.0 0 -16777216 true "" ""
"HET-female" 1.0 0 -13345367 true "" ""
"MSM" 1.0 0 -13791810 true "" ""
"Trans per 10000 PLWH" 1.0 0 -5825686 true "" ""
"HET-male" 1.0 0 -10899396 true "" ""

PLOT
992
816
1242
951
Stage Distribution- Heterosexuals
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"acute-unaware" 1.0 0 -16777216 true "" ""
"non-acute-unaware" 1.0 0 -7500403 true "" ""
"aware-no care" 1.0 0 -2674135 true "" ""
"aware-care-no ART" 1.0 0 -955883 true "" ""
"ART-not suppressed" 1.0 0 -1184463 true "" ""
"ART-suppressed" 1.0 0 -10899396 true "" ""

PLOT
1487
969
1766
1134
Stage Distribution- MSM
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"acute-unaware" 1.0 0 -16777216 true "" ""
"non-acute-unaware" 1.0 0 -7500403 true "" ""
"aware-no care" 1.0 0 -2674135 true "" ""
"aware-care-no ART" 1.0 0 -955883 true "" ""
"ART-not suppressed" 1.0 0 -1184463 true "" ""
"ART-suppressed" 1.0 0 -10899396 true "" ""

PLOT
534
923
802
1043
CD4 count at diagnosis - MSM
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"<=200" 1.0 0 -16777216 true "" ""
"200-350" 1.0 0 -13345367 true "" ""
"350-500" 1.0 0 -5825686 true "" ""
">500" 1.0 0 -10899396 true "" ""

PLOT
1113
923
1481
1073
Proportion transmissions in stage
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"acute-unaware" 1.0 0 -16777216 true "" ""
"non-acute-unaware" 1.0 0 -7500403 true "" ""
"aware-no care" 1.0 0 -2674135 true "" ""
"aware-care-no ART" 1.0 0 -955883 true "" ""
"ART-not suppressed" 1.0 0 -1184463 true "" ""
"ART-suppressed" 1.0 0 -10899396 true "" ""

MONITOR
1671
683
1728
728
undiag
count people with [stage = 2 and dead = 0 and index? = true and new-infections = 0]
17
1
11

INPUTBOX
1532
600
1612
660
num-year-trans
25.0
1
0
Number

INPUTBOX
1623
604
1778
664
goal
1.0
1
0
Number

INPUTBOX
1715
454
1819
514
prep-effectiveness
0.0
1
0
Number

INPUTBOX
1523
463
1620
523
prep-cov-positive
0.0
1
0
Number

INPUTBOX
1626
455
1713
515
prep-cov-casual
0.0
1
0
Number

INPUTBOX
1415
464
1527
524
prep-cov-concurrent
0.0
1
0
Number

INPUTBOX
1631
519
1786
579
dry-run
0.0
1
0
Number

BUTTON
1826
745
1892
778
Profile
profile
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
1705
745
1821
778
RunExperiment
RunExperiment
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
1793
518
1948
578
maxRun
1.0
1
0
Number

BUTTON
1489
750
1552
783
SA
sensitivity-analysis
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
957
73
1051
106
NIL
setupECNA
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1555
687
1666
732
NIL
num-exposed-sus
0
1
11

BUTTON
951
229
1075
262
NIL
runClusterCodes
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
953
106
1116
139
NIL
layout-ECNA Ttree-links\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1124
106
1236
139
NIL
killSusceptibles
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
1056
73
1137
106
NIL
runECNA
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
960
530
1131
563
NIL
color-intervention-cluster
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
951
10
1106
70
maxDegree
128.0
1
0
Number

TEXTBOX
965
142
1689
240
ECNA COLOR CODE\ngreen nodes: susceptible\nred nodes: infected and unaware\nblue nodes: infected and aware\nnode labels: [time-at-infection time-at-diagnosis]\nnumber on node die: stage (1- acute; 2- unaware;  3- aware-not-in-care; 4- aware-incare-noART; 5 -ART-noVLS; 6 -ART-VLS
11
0.0
1

BUTTON
779
132
948
165
layout- cluster links
layout-ECNA Ptree-links
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
777
165
946
198
layout- transmisison links
layout-ECNA Ttree-links\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1135
456
1331
513
Red- cluster links\nThick grey- transmission links
15
0.0
1

TEXTBOX
969
280
1570
418
Clustering color code:\nRed links: if total distance < evolution-time-window\n\nRed nodes: acute phase (within past 3 months)\nYellow nodes: recent infections (within past 6 months)\n\nOnly clusters with atleast two persons diagnosed in past 'time-window' months are considered for reporting for comparing to surveillance\nclusters with blue and gray nodes: are part of surveillance clusters \nclusters with green nodes: not in surveillance cluster\n
11
0.0
1

TEXTBOX
969
578
1119
606
IDENTIFY color code for intervention clusters:
11
0.0
1

@#$#@#$#@
##MOLECULAR PROJECT
1. create-Ttree-link-with in initialize-transmissions.nls



## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.  
Initially hit "setup" button on the interface tab

1. It sets up global variables by calling "setup-globals"
	a. globals are all the data that remains the same for entire population

2. It calls "setup-people"
 	a. It generates number of people as mentioned in the "number-people" input button. Sets x% (currently 100%) of the initial people as index-patients. Which means everyone gets infected in quarter 1, i.e., tick 1 (but are un-infected in tick 0 for ease of computation). 

 	b. Initializes all the variable used in the model by calling procedure "set-infected-variables"

Next hit the "go" button. This begins the simulation

1. For "simulation-years" updates all the variables of (dead =0, i.e, non-dead) people in the simulation by calling "update-simulation"

2. Each quarter, i.e., each tick, creates new infections (currently creates new people because 100% of initial population was infected in the beginning and can be changed as needed). Number of new infections = total number of transmissions generated by all the index patients only. 
	a. This is done by calling the procedure "setup-new-transmissions [number]".

	b. The procedure sets the new infections as index-patients = false and calls "set-infected-variables" to initialize the variables. From the next quarter they are included in the simulation, that is, "update-simulation" automatically applies to everyone in the simulation

3. when a person dies, variable "dead = 1" but we do not assign "die" which is in-built netlogo function for permanently removing person from the simulation. This is done so that the population statistics can be collected in the end (using die erases persons data)

After simulation stops hit "display-values"  
1. Displays the required data for index and transmissions separately.  
2. For each peron, at time of death, "set-life-variables" which keeps track of life variables. When display-values is clicked the simulation is modeled to display some of these values. Note: Currently all life-variables are for index-patients ONLY. Change as needed in procedures "set-dead", "set-life-variables", and "display-values"

## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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

die 1
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 129 129 42

die 2
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 189 189 42

die 3
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 129 129 42
Circle -16777216 true false 189 189 42

die 4
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 69 189 42
Circle -16777216 true false 189 69 42
Circle -16777216 true false 189 189 42

die 5
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 129 129 42
Circle -16777216 true false 69 189 42
Circle -16777216 true false 189 69 42
Circle -16777216 true false 189 189 42

die 6
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 84 69 42
Circle -16777216 true false 84 129 42
Circle -16777216 true false 84 189 42
Circle -16777216 true false 174 69 42
Circle -16777216 true false 174 129 42
Circle -16777216 true false 174 189 42

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

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>show date-and-time
setup
;clear-all
;import-world "Base Model-HET MSM world.csv"</setup>
    <go>go</go>
    <final>;write-life-variables
show date-and-time
show numActsCasualMSM
print  numActsMainMSM
print  numActsConMSM
print  numActsMainHET
print  numActsConHET</final>
    <exitCondition>;count people with [dead = 0 and index-patient? = false and infected? = true] = 0 and ticks &gt; sim-dry-run + time-unit * num-year-trans
ticks &gt; (sim-dry-run + time-unit * num-year-trans)
;count people with [dead = 0 and infected-2013-2022? = true] = 0 and ticks &gt; sim-dry-run + time-unit * 20;; at least past 2011</exitCondition>
    <enumeratedValueSet variable="goal">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-effectiveness">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-cov-casual">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-cov-positive">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-cov-concurrent">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment2" repetitions="1" runMetricsEveryStep="false">
    <setup>show date-and-time
setup
;clear-all
;import-world "BaseModel-HETMSM world-10000-6-20-2015"
setData</setup>
    <go>go</go>
    <final>;write-life-variables
show date-and-time
show numActsCasualMSM
print  numActsMainMSM
print  numActsConMSM
print  numActsMainHET
print  numActsConHET</final>
    <exitCondition>;count people with [dead = 0 and index-patient? = false and infected? = true] = 0 and ticks &gt; sim-dry-run + time-unit * num-year-trans
ticks &gt; (sim-dry-run + time-unit * num-year-trans)
;count people with [dead = 0 and infected-2013-2022? = true] = 0 and ticks &gt; sim-dry-run + time-unit * 20;; at least past 2011</exitCondition>
    <enumeratedValueSet variable="goal">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-effectiveness">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-cov-casual">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-cov-positive">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-cov-concurrent">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Clusters" repetitions="5" runMetricsEveryStep="true">
    <setup>setupECNA</setup>
    <go>runECNA</go>
    <final>killSusceptibles
runClusterCodes</final>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="dry-run">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-years">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-cov-positive">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxDegree">
      <value value="128"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-year-trans">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="goal">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-effectiveness">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-people">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-cov-casual">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prep-cov-concurrent">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-unit">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxRun">
      <value value="1"/>
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
