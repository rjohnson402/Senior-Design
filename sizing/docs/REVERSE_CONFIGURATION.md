# Conditional reverse-enabled concept, October 12

The current inputs enable reverse and use W/S27 lb/ft², AR15.5 and taper .35.
All three studies inherit this reverse configuration; the landing requirement
remains 1,500 ft over a 50-ft obstacle.

| Item | Modeling choice |
|---|---|
| Total reverse target | 6% of aircraft weight, both cruise props combined |
| Eligibility | Ground roll only; below 55 kt AND at least 2 seconds after touchdown |
| Command ramp | 1 second from the later eligibility condition |
| Low-speed fade | Full target above 15 kt, tapering to zero at 5 kt |
| Power | Request 18 kW; cap at half the installed cruise pair's assigned rating |
| Thrust cap | Static momentum screen, assumed figure of merit .50 |
| Added mass | 9 kg / 19.8 lb: two 4-kg pitch/beta increments plus 1-kg controls, before normal margin |
| Mission energy | Battery consumption included for each landing; no regeneration |
| Pair unavailable | No reverse from either prop; installed hardware remains |

The 55-kt threshold is still-air ground-roll speed. It is an analyst choice,
not a manufacturer operating limit. The model evaluates reversing blade pitch,
not a fixed-pitch prop spinning backward. It does not establish a flight-ready
ground interlock, asymmetric control or reverse/go-around transition.

At the current reference, closed MTOW is about **2,313 lb**, landing distance
**1,472 ft**, and the same installed-hardware aircraft without reverse needs
**1,526 ft**. The target was raised from5% to6%, and shaft request from15 to18 kW.
The approximately28-ft modeled margin is small and does not include
wind, runway or prop-map uncertainty.

The earlier separately sized no-reverse case reaches W/S25.75 at about2,291 lb. The
earlier sampled 5%-reverse minimum was about2,305 lb at W/S27.75: roughly14 lb heavier,
despite supporting the smaller wing. Reverse improves the feasible wing-loading
limit under these assumptions; it does not demonstrate an overall weight saving.

```matlab
out = AEGAsize();                 % Active concept at W/S27
wing = AEGAtrades('wing');        % Regenerate curves with reverse enabled
reverse = AEGAtrades('reverse');  % Compare zero, 3%, 5%, 6%, 8% and unavailable cases

m = AEGAinputs();
m.reverse_TW = 0;                % Installed hardware, unavailable reverse
outWithoutReverse = AEGAsize(m);
m.reverse_hardware_lb = 0;       % Also remove hardware for a no-reverse aircraft
m.WS_design = 24;                % Earlier conservative reference
outNoHardware = AEGAsize(m);
```

The numeric target and hardware budget remain assumptions. NASA's
[negative-thrust propeller tests](https://ntrs.nasa.gov/citations/19930091538)
show sensitivity to blade angle and installation. A static cap is not a
negative-pitch thrust/power map at the actual roll speed. These inputs support
a conceptual trade, and the 1,500-ft landing result remains conditional.
