# Propeller weight audit — October 13, 2026

The extra 108.2 lb is produced by the current blade-weight assumption. It is **not** a mixed-diameter counting error. No numerical weight assumption was changed in this audit, so the latest sizing results and presentation tables retain their stated model.

## Arithmetic and layout

The code computes blade-only mass as:

```text
W_blades = 3.28e-6 × AF² × number_of_blades × sum(D_each_prop³)
```

Weights are lb and diameters are ft. AF is the per-blade activity-factor placeholder, currently 130; every propeller currently has five blades. The mixed layout uses the cubic-mean diameter for weight, which exactly reproduces the sum of the eight individual diameter cubes. Its separate area-equivalent diameter is used for disk area, not for weight. Six high-lift props stay at 1.50 ft when the two cruise diameters change.

| Blade-only quantity | 2.75-ft cruise | 6.00-ft cruise |
|---|---:|---:|
| One cruise blade | 1.153 lb | 11.973 lb |
| Five blades on one cruise prop | 5.764 lb | 59.867 lb |
| Two cruise props, blades only | 11.528 lb | 119.733 lb |
| Six 1.50-ft high-lift props, blades only | 5.613 lb | 5.613 lb |
| All eight propellers, blades only | 17.141 lb | 125.346 lb |
| Increase | — | 108.205 lb |

The calculation does not assign six-foot diameters to the six high-lift motors. It does not multiply a complete-propeller mass by blade count. Hubs and installation are excluded from this equation and carried in the separate 120-lb installation estimate, with reversing hardware carried separately.

## Why the estimate needs better support

The code previously attributed the coefficient directly to Amatt, Bates and Borst, USAAMRDL TR 73-34B (1973). The exact coefficient, material basis and intended range could not be independently confirmed from an accessible authoritative copy during this review. The comment now identifies that uncertainty instead of presenting the attribution as verified. This is not evidence that the exponents are definitely wrong.

The model holds activity factor and blade count constant across 1–6 ft, uses no rated power or torque in blade mass, and has no explicit composite-blade calibration. At constant AF, enlarging diameter also enlarges blade chord and implicitly preserves a broad, geometrically similar blade. Thus cubic growth is being applied to a family of similar blades, not to independently optimized blade structures at each power requirement. With the current low cruise-motor powers, that can overpenalize large diameters. A thinner/lower-activity blade or fewer blades could change both aerodynamic performance and mass and cannot be represented by a free weight reduction alone.

Manufacturer data illustrate how strongly design and pitch architecture matter:

- E-PROPS lists a **180-cm (5.91-ft), three-blade ground-adjustable carbon propeller at 2.16 kg / 4.8 lb all inclusive**. [Manufacturer product page](https://aircraft.e-props.fr/product_info.php?language=en&products_id=23950).
- Its **175/180-cm three-blade Glorieuse constant-speed propeller is listed at 4 kg / 8.8 lb all inclusive**. [Manufacturer installation example](https://blogen.e-props.fr/archives/11701/e-props-glorieuse-on-fk9-912s/).
- MT-Propeller lists its **three-blade electric constant-speed MTV-18 at approximately 20 kg / 44 lb**, with a diameter range of 152–203 cm. [Manufacturer announcement](https://www.mt-propeller.com/mt/en/unsere-news/3-blade-mt-propeller-mtv-18-type-certified-by-tcca-canada-2282/).

These are complete assemblies with different blade counts, pitch mechanisms, power ratings and material designs. They are comparisons, not interchangeable masses for our five-blade reversing design. Nevertheless, **59.9 lb of blades alone per six-foot cruise prop is poorly supported for this lightweight concept**. Treat the former 2.75-ft optimum as dependent on the legacy weight model, not proof that six-foot props inherently require 100 lb more blades.

## Recommended next model

Select a blade/pitch architecture for each propeller group, then use manufacturer or structural estimates with matching power, RPM, torque, diameter and blade count. Separate blades, hubs, pitch/reverse mechanisms, spinners and mounts, and subtract any installation allowance that would otherwise count those components twice. Calibrate a modern-composite mass relation and test its uncertainty rather than applying an unsupported blanket reduction. Re-run the diameter trade before updating the aircraft weight tables if the numerical model changes.
