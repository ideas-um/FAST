# Thermal equivalent-circuit ground charging

`GroundChargeModel = "ThermalEquivalentCircuit"` selects a conservative
NMC sensitivity model for off-design sequence studies. It is intended to
show thermal and end-of-life implications until cell/pack test data are
available; it is not a calibrated production-battery model.

## Default scenario

| Quantity | Default |
|---|---:|
| State of health | 80% |
| First-flight battery temperature | 35 degC |
| Ground ambient / coolant | 30 / 25 degC |
| Allowed charging temperature | 0 to 45 degC |
| Cooling on / target | 32 / 30 degC |
| Passive / active conductance | 30 / 500 W/K |
| Maximum heat rejection | 20 kW thermal |
| Cooling coefficient of performance | 3 |
| Battery specific heat | 900 J/(kg K) |
| Charger efficiency | 95% |
| Coulombic efficiency | 99.5% |
| Site power limit | 150 kW AC, including cooling electricity |
| End-of-life maximum charge rate | 0.6C |
| End-of-life resistance multiplier | 1.30 |
| CC-CV termination current | 0.02C |

The temperature-dependent maximum C-rate table is:

| Temperature (degC) | 0 | 5 | 10 | 15 | 25 | 35 | 40 | 45 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Maximum charge rate (C) | 0 | 0.10 | 0.30 | 0.50 | 0.80 | 0.80 | 0.40 | 0 |

The 0--45 degC envelope follows NASA lithium-ion operational guidance. The
interior derating curve, cooling-system sizing, efficiency, and aging
multipliers are explicit engineering assumptions selected for a conservative
hot/end-of-life sensitivity case. Replace them with supplier or HPPC data
before using the result for certification or hardware design.

MathWorks documents the Battery Equivalent Circuit block's lumped thermal
mass, temperature-dependent electrical tables, heat generation, and aging
capabilities here:

https://www.mathworks.com/help/simscape-battery/ref/batteryequivalentcircuit.html

NASA charging-temperature guidance used for the hard envelope:

https://ntrs.nasa.gov/api/citations/20240007136/downloads/Nano%20Satellite%20Electrical%20Power%20Systems%20Revised.pdf

## Controller limits

At each integration step, charge current is the minimum of:

1. temperature- and SOH-dependent C-rate current;
2. current satisfying the remaining AC site-power budget after cooling;
3. current satisfying the maximum cell-voltage limit.

The pack temperature state includes ohmic heat, passive heat transfer, and
active liquid cooling. The mission current history estimates landing
temperature, and post-charge temperature is carried into the next flight.

Override any assumption with fields under
`Aircraft.Settings.BatteryThermalCharge`. Set
`Aircraft.Settings.BatterySOH_pct` and
`Aircraft.Settings.BatteryInitialTemperature_C` to choose the operating
point without enabling FAST's lifecycle-aging accumulator.
