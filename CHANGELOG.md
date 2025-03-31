# **Changelog**

Copyright 2024 The Regents of the University of Michigan, The Integrated Design of Efficient Aerospace Systems Laboratory

Written by the IDEAS Lab at the University of Michigan:
<https://ideas.engin.umich.edu>

Principal Investigator and Point of Contact:
- Dr. Gokcin Cinar, <cinar@umich.edu>

Principal Authors:
- Paul Mokotoff, <prmoko@umich.edu>
- Max Arnson, <marnson@umich.edu>

Last Updated: 28 Mar 2025
	
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