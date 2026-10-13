# Why the high-lift downsizing graph had spikes

The previous figure combined points from a coarse sweep and selective local
refinements. Different high-lift diameters therefore had different W/S coverage.
Taking the minimum mass at each diameter did not produce a comparable curve.

For example, in the saved October 12 13:11 run with 4-ft cruise props and all
motors operating, the 1.40-ft high-lift point included W/S24 and reached about
2,208 lb. The neighboring 1.45-ft point had only W/S16 and returned about
2,552 lb. Connecting these values made an artificial 344-lb jump. It was
evidence of incomplete sampling, not an aerodynamic discontinuity.

The revised plot uses the same W/S grid at every plotted high-lift diameter.
Default review mode reuses the seven coarse high-lift diameters and five cruise
diameters to avoid extra sizing work. Thorough mode uses 0.1-ft intervals and
six representative cruise diameters; its full cruise-diameter search is retained
in the numerical study. Additional local refinement cases
remain available for selecting the best designs, but are excluded from this
common-grid diagnostic figure.

The axes now say “Best passing MTOW on common W/S grid.” Circles/lines are
passing minima on that grid; crosses show converged rejected cases when no
passing case exists at that plotted diameter. There is no spline smoothing.
Some corners can remain when the selected discrete W/S changes or a different
constraint becomes limiting. A passing curve is still a sampled envelope,
not proof of a continuously optimized result.

Run `AEGAtrades('props')`. The common plotting samples are exported as
`07_common_downsize_plot_cases.csv` alongside the full case table. The checks
verify equal W/S coverage at each plotted cruise/high-lift diameter pair.
