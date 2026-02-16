# **Changelog**

Copyright 2024 The Regents of the University of Michigan, The Integrated Design of Efficient Aerospace Systems Laboratory

Written by the IDEAS Lab at the University of Michigan:
<https://ideas.engin.umich.edu>

Principal Investigator and Point of Contact:
- Dr. Gokcin Cinar, <cinar@umich.edu>

Principal Authors:
- Paul Mokotoff, <prmoko@umich.edu>
- Max Arnson, <marnson@umich.edu>

Last Updated: 20 Jan 2026

## Version 0.4.0 - 20 Jan 2026

### Added

1. CostPkg with a battery replacement cost estimation model.

2. Battery state of health model to capture long term effects of using a battery during flight operations.

### Changed

1. Reorganized battery (dis)charging model and broke into seperate files for readibility.

### Fixed

1. Fixed C-rate assumption error and battery resizing error. 

## Version 0.3.0 - 26 Nov 2025

### Added

1. CeRAS CSR-01 aircraft added to aircraft specs with requisite engine and mission profile specifications.

2. Database of hobby scale electric motors added, which consists of SunnySky brand motors.

3. FLOPS OEW method added internally. Note that this would need to be integrated on the user side if it is to be used in place of the default OEW method (built-in regressions).

4. New variables added to the database:     
    - ``Aircraft.Specs.TLAR.ADG``: "Aircraft Design Group, which is used in airport planning to decide gate, runway, and taxiway requirements.
    - ``Aircraft.Specs.TLAR.ADGPercent``: Ratio of aircraft wingspan or tail height to the maximum allowable wingspan or tail height for the given ADG.
    - ``Aircraft.Specs.TLAR.ADGLimitor``: FLag to indicate whether the aircraft is limited by wingspan or tail height for the given ADG.

5. ``RandomizeDB`` function added which randomizes the validation datatype variables in the database. This is useful for testing the robustness of the regression models with respect to the training and validation data. This function only affects the outputs of regressions if the the user has specifically downselected the training data to be used in a regression call.

### Changed

1. Internal regression restructuring.

    - Separated the large data-matrix inversion from the main regression call, this allows it to be called during specification processing, saving computation time during iterations for known input-output pair regressions.
    - Vectorized some internal calculations to improve regression performance. 

## Version 0.2.0 - 08 Sep 2025

### Added

1. The README file now contains a paper to cite when using FAST for your own research.

### Changed

1. Developed a new approach to analyze the propulsion system performance.
If you use a pre-defined propulsion architecture ("C", "E", "PHE", "SHE", "TE", or "PE"), the propulsion architecture does not need to be redefined.
If you use a custom propulsion architecture ("O"), then the matrices need to be redefined using the following five matrices:

    - ``Aircraft.Specs.Propulsion.PropArch.Arch``: architecture matrix (defines the propulsion architecture)
    
    - ``Aircraft.Specs.Propulsion.PropArch.OperUps``: upstream operational matrix (for computing power available, still a function of the mission segment)
    
    - ``Aircraft.Specs.Propulsion.PropArch.OperDwn``: downstream operational matrix (for sizing and propulsion system analysis, still a function of the mission segment)
    
    - ``Aircraft.Specs.Propulsion.PropArch.EtaUps``: upstream efficiency matrix (accounts for losses while propagating power upstream)
    
    - ``Aircraft.Specs.Propulsion.PropArch.EtaDwn``: downstream efficiency matrix (accounts for losses while propagating power downstream)
    
    Additionally, the user must define which components are "sources" and "transmitters", using:

    - ``Aircraft.Specs.Propulsion.PropArch.SrcType``: defines the types of sources used (fuel, battery, etc.)

    - ``Aircraft.Specs.Propulsion.PropArch.TrnType``: defines the types of transmitters used (gas-turbine engine, electric motor, electric generator, propeller/fan, etc.)

    Instead of defining the power splits using ``LamTS/TSPS/PSPS/PSES``, new variables are used:
    
    - ``Aircraft.Specs.Power.LamUps.SLS/Tko/Clb/Crs/Des/Lnd``: defines the power splits for the upstream operational matrix as a function of the segment

    - ``Aircraft.Specs.Power.LamDwn.SLS/Tko/Clb/Crs/Des/Lnd``: defines the power splits for the downstream operational matrix as a function of the segment

    Refer to the following paper to learn about the matrices:

    > Mokotoff, P. and Cinar, G. (2025). [Graph Theory-based propulsion system analysis](https://doi.org/10.1016/j.ast.2025.110798). Aerospace Science and Technology, in press. 

## Version 0.1.2 - 25 Jan 2025

### Changed

1. Updated the README with additional installation instructions and a paper to cite for those using FAST in their research.

### Fixed

1. Resolved testing issue associated with the preset propulsion architecture.

1. Assign a battery weight of 0 if there is no battery in the system to prevent issues from arising with ``NaN`` values.

1. Modified which variables are plotted as "differential" and "cumulative".

## Version 0.1.1 - 31 Oct 2024

### Added

1. Created example files that were used in a series of YouTube tutorials.
The tutorial videos may be accessed [here](https://www.youtube.com/channel/UC5ntmOSA1_YWu1ljQ5hXn0Q).

## Version 0.1.0 - 07 Oct 2024

### Added

1. Created unit test cases for various files in the ``+UnitConversionPkg``, ``+BatteryPkg``, and ``+PropulsionPkg``.

### Changed

1. Instead of using an on-design engine model to estimate off-design performance, an off-design engine model for turbofans was developed.
If you are using a turbofan aircraft, you must define the following constants in your Engine Specification File:

    - ``Engine.Cff3``
    - ``Engine.Cff2``
    - ``Engine.Cff1``
    - ``Engine.Cffch``
    - ``Engine.HEcoeff``

The first four variables are further described in [this paper](https://www.gokcincinar.com/publication/c-2025-scitech-pm/c-2025-SciTech-PM.pdf).
The fifth variable is only necessary for hybrid electric configurations and is proportional to the ratio of thrust produced by a hybrid electric configuration relative to a conventional baseline aircraft.

### Fixed

1. Bug fixes in the engine component models.

## Version 0.0.6 - 09 Sep 2024

### Added

1. Added the ability to plot "differential variables" (ones that are constant during a timestep in the mission analysis) and "cumulative variables" (ones that are a function of time)

### Fixed

1. Specific excess power during descent is now always a nonnegative number

## Version 0.0.5 - 30 Jul 2024

### Added

1. New mission segment, ``EvalDetailedTakeoff``, which uses a physics-based takeoff segment instead of approximating takeoff as a one-minute, full-throttle operation.

## Version 0.0.4 - 18 Jul 2024

### Changed

1. When using the detailed battery model, the battery is now sized to:

    - Not fall below the minimum state-of-charge
    - Ensure a maximum C-rate is not exceeded

## Version 0.0.3 - 02 Jul 2024

### Added

1. Preset propulsion architectures for series hybrid (SHE), fully turboelectric (TE), and partially turboelectric (PE) are available.
Use the strings in parenthesis from the previous sentence to define these preset propulsion architectures.

## Version 0.0.2 - 11 Jun 2024

### Changed

1. Defined an "upstream" power split to more accurately compute the power available in a propulsion system.
Users need to define three new variables:

    - ``Aircraft.Specs.Propulsion.Upstream.TSPS``
    - ``Aircraft.Specs.Propulsion.Upstream.PSPS``
    - ``Aircraft.Specs.Propulsion.Upstream.PSES``

    Each of the entries in these matrices represents the fraction of power that is supplied to its upstream connections.

## Version 0.0.1 - 30 May 2024

### Fixed

1. Throw a warning if the user requests a second output but the flag for producing a mission history table is not on.

## Version 0.0.0 - 03 May 2024

### Added

1. Released initial version of FAST publicly