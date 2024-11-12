<p align="center">
  <img src="https://github.com/ideas-um/FAST/assets/94265270/af0238b2-7463-4d5d-81ec-12d84bf4fc59" width="50%" height="auto">
</p>

# README

Copyright 2024 The Regents of the University of Michigan, The Integrated Design of Environmentally-friendly Aircraft Systems Laboratory

Future Aircraft Sizing Tool (FAST), a MATLAB-based aircraft sizing toolbox for electrified aircraft concepts with any propulsion architecture.

Written by the IDEAS Lab at the University of Michigan.
<https://ideas.engin.umich.edu>

Principal Investigator and Point of Contact:
- Dr. Gökçin Çınar, <cinar@umich.edu>

Principal Authors:
- Paul Mokotoff, <prmoko@umich.edu>
- Max Arnson, <marnson@umich.edu>

Additional Contributors:
- Hüseyin Acar
- Nawa Khailany
- Janki Patel
- Michael Tsai
- Vaibhav Rau

README last updated: 11 Nov 2024

## Learn More About FAST

For detailed information about FAST's features, visit our website: [IDEAS Lab Website](https://www.gokcincinar.com/software/fast). 

We also offer a series of tutorial videos on YouTube to help you get started with FAST and explore its capabilities. Check out our channel and subscribe for updates: [IDEAS Lab YouTube Channel](https://www.youtube.com/channel/UC5ntmOSA1_YWu1ljQ5hXn0Q).

To stay informed about upcoming papers, new releases, and news about FAST, please sign up for [our newsletter here](https://forms.gle/b8sPXKnRAfi5ZsARA).

# (I) Installation Instructions

FAST can be cloned from its [GitHub repository](https://github.com/ideas-um/FAST) and can be run directly in Matlab. As long as Matlab is installed on the user's computer, FAST can be run directly after cloning from the online repository.

# (II) Additional Documentation

For FAST's license, notices, and community contribution instructions, refer to the following files located in the main directory.

### (1) Main Directory

- **EULA.m**: This file contains the end user license agreement (EULA) for the FAST toolbox.
- **Notices.m**: This file contains FAST compatibility requirements and logistical disclosures. The same information can also be found in section III of this file.
- **Contributions.m**: This file contains instructions for how to contribute to the FAST repository. Users are encouraged to find bugs, suggest changes, and modify the code to meet their specific needs. If your changes introduce new features into the code, feel free to reach out to us!
 
For additional documentation, see package-specific README files. These READMEs will include guides/tutorials or answer questions regarding specific aspects of FAST. A full list of packages and a brief description is included below, followed by a documentation command example.

### (2) Package List

- **+AircraftSpecsPkg**: This package contains specific aircraft initialization files. The documentation will guide a user to create their own files for repeated studies.
- **+BatteryPkg**: This package contains the battery model which is called during the mission analysis for fully or hybrid electric aircraft.
- **+DatabasePkg**: This package contains the IDEAS Lab historical database. It also contains functions which help convert the original database format (MS Excel sheet) into the FAST format (Matlab data structures).
- **+DataStructPkg**: This package contains functions which process aircraft data structures when calling FAST.
- **+EngineModelPkg**: This package contains the gas turbine engine models used while running FAST. It is one of the largest packages and inspecting additional documentation is recommended if a user has more questions regarding the gas turbine engine models.
- **+MissionProfilesPkg**: This package is analogous to the AircraftSpecsPkg, as it contains specific mission profiles. The documentation will guide users in calling pre-made mission profiles.
- **+MissionSegsPkg**: This package is responsible for all aircraft performance-related functionality while performing the mission analysis (i.e., processing and flying the mission).
- **+OEWPkg**: This package determines the aircraft's airframe and propulsion system weights.
- **+OptimizationPkg**: This package contains information about running EAP power management optimization, which is focused on optimizing in the sizing loop to determine the optimum electrified powertrain component sizes and usage during flight.
- **+PlotPkg**: This package contains information about plotting the mission history upon the user's request. It creates subplots to show the time-based history of multiple aircraft performance and system-level parameters.
- **+ProjectionPkg**: This package contains code to project the value of certain Key Performance Parameters (KPP) into the future using S-curves.
- **+PropulsionPkg**: This package is responsible for creating the user's desired propulsion architecture and evaluating the propulsion system's performance during the mission analysis. It connects to the EngineModelPkg for evaluating an actual engine's performance.
- **+RegressionPkg**: This package contains code that creates regressions to predict any unknown parameters about the aircraft configuration being designed.
- **+RetrofitPkg**: This package contains code to run retrofit studies on an aircraft by electrifying its powertrain and replacing part of the payload with batteries.
- **+TutorialsPkg**: This package contains Matlab scripts to accompany all the playlist of YouTube tutorial videos, which can be accessed using [this link](https://www.youtube.com/playlist?list=PLNbQSl1VumqhNHgNOq9oxm4_Toi4_7v3-).
- **+UnitConversionPkg**: This package contains functions which perform unit conversions for use in FAST.
- **+VisualizationPkg**: This package contains information about visualizing both the aircraft's outer mold line (as a wireframe) and its propulsion architecture (in a schematic).

### (3) Examples

To inspect any package-specific documentation, please run either of the following two commands:

```matlab
>> doc  PackageName.README
>> help PackageName.README

```

where "PackageName" is replaced by the specific package a user would like to inspect. For example, to see more information about the engine model, a user would run either:
```matlab
>> doc  EngineModelPkg.README
>> help EngineModelPkg.README
```

While a user might run either:
```matlab
>> doc  VisualizationPkg.README
>> help VisualizationPkg.README
```

to see more information on the aircraft visualization software. Additionally, there may be subpackages stored within packages. The same syntax is used to view this documentation. A user may run either:
```matlab
>> doc  EngineModelPkg.EngineSpecsPkg.README
>> help EngineModelPkg.EngineSpecsPkg.README
```

for more information on creating engine specification files for the engine model.

# (III) FAST Overview

FAST performs on- and off-design analysis of a user-prescribed aircraft on a user-prescribed mission profile. To run this tool, call the "Main" function with an aircraft specification function and a parametric mission profile. To do so, the user must:

1. Prescribe their aircraft configuration via a function call. This can be achieved  by updating the example.m file provided in “AircraftSpecsPkg�?. See this package for more instructions and examples. In the function, the user should:
    - Select whether an on-design (+1, sizing and performance) analysis or off-design (-1, performance only) analysis should be performed, which is the second argument in the call to "EAPAnalysis". This is controlled by the variable: "Aircraft.Settings.Analysis.Type". The default is +1 (sizing and performance) if this value is not provided.
    - Select the maximum number of iterations to be performed during the analysis. The value must be a positive integer and is controlled by the following variable: "Aircraft.Settings.Analysis.MaxIter". The default is 50 iterations.
    - Select whether or not the mission profile should be plotted after the analysis has been completed. This is controlled by the following variable: "Aircraft.Settings.Plotting". The default is 0 (no plotting).
    - Select whether or not a mission history table should be returned after the analysis has been completed. This is controlled by: "Aircraft.Settings.Table". The default is 0 (no mission history table returned).
    - Select whether or not a geometry of the aircraft should be created. This is controlled by the variable: "Aircraft.Settings.VisualizeAircraft". The default is 0 (no geometry created).
    - Prescribe an aircraft architecture by either using a preset one (given in "CreatePropArch" within the "PropulsionPkg") or define their own. To learn more about how to define a propulsion architecture, the user should refer to the examples in "CreatePropArch" and the following paper:

        > Cinar, G., Garcia, E., & Mavris, D. N. (2020). A framework for electrified propulsion architecture and operation analysis. Aircraft Engineering and Aerospace Technology, 92(5), 675-684.

    It is acceptable if some information is unknown about the aircraft. The user can either set the value to `NaN` or omit it. During the analysis preprocessing, any unknown information about the aircraft will be estimated using historical regressions from a database of over 450 aircraft.

2. Define an engine specification file for any aircraft configuration requiring a gas-turbine engine. Examples of these are located in the "EngineSpecsPkg", which is contained within the "EngineModelPkg". Once the engine is defined, it must be included in the aircraft configuration specification via the following variable: "Aircraft.Specs.Propulsion.Engine". Unlike the aircraft configuration provided by the user, all information about the engine must be complete; no `NaN` inputs are allowed.

3. Prescribe a mission profile (also via a function call). There are many templates/examples in the "MissionProfilesPkg", particularly the ones named "NotionalMission", "RegionalJetMission", and "TurbopropMission". Information from the aircraft specification file can be passed into the mission profile, as done in the "NotionalMission" examples. The "RegionalJetMission" profiles are designed for a regional jet (specifically, the ERJ 170/175/190). The "TurbopropMission" is intended for a regional turboprop aircraft (specifically, the ATR 42). Note that these mission profiles are approximate and may not return the most accurate block fuel estimates - they are primarily simple examples for the user to understand how a mission is defined.

Once these two functions are created, the main aircraft analysis function can be called via:

```matlab
OutputAircraft = Main(AircraftSpecsPkg.AC, @MissionProfilesPkg.Miss);
```

To run an aircraft that was created, replace "AC" in "AircraftSpecsPkg.AC" with the appropriate .m file that was created in the "AircraftSpecsPkg". Also, replace "Miss" in "MissionProfilesPkg.Miss" with the appropriate .m file in the "MissionProfilesPkg". In the function call above, "OutputAircraft" is the analyzed aircraft output and can be replaced with any Matlab-valid variable name. Note that an "@" is required before calling the mission profile, but it is not needed for the aircraft specification file (because it should have no input arguments).

# (IV) Requirements and Compatibility:

1. The oldest Matlab version that this code has been successfully run on is R2019b.
2. FAST requires no installation of additional toolboxes or packages. 

# (V) Notes:

1. In the main sizing/performance analysis function, "EAPAnalysis", information about the weight of each component being sized is printed. To suppress these printouts, comment out any line containing a call to "fprintf". In a later version, the user will be given an option to indicate how much information should be printed to the command window.
2. For off-design missions, the user can specify "Aircraft.Settings.Analysis.Type" to be either -1 or -2 (for more information about this, refer to "AircraftSpecsPkg.README", Section III.C.70).
3. To run an off-design mission, a payload must be specified (via "Aircraft.Specs.Weight.Payload") rather than a number of passengers ("Aircraft.Specs.TLAR.MaxPax"). Thus, if the number of passengers changes, change the payload weight instead of the number of passengers. Refer to "AircraftSpecsPkg.README", Section III.C.19 to learn more about this.
4. Please direct any questions, comments, suggestions, or success stories while using FAST to the listed Point of Contact at the beginning of this file.

# (VI) Disclaimers:

1. When defining an aircraft in the "AircraftSpecsPkg" folder, many of the values will remain as `NaN`. For any values that remain as `NaN`, the regressions mentioned previously will attempt to approximate values for these variables. In some cases, this can lead to an unrealistic design, or one that is not able to converge. If possible, please try to define as much as possible about the aircraft. For any value in the "Aircraft.Settings" sub-structure that is not specified, a default value is internally provided.
2. Some of the variables in the aircraft specification may have dependencies on each other. In the event that a dependency exists, the user will see a warning in the command window, indicating which variables will be prioritized and used to compute the others. If this warning appears, it does not mean that the design failed to converge or is deprecated. Instead, it means that excess information was supplied before the analysis began.
3. During the mission evaluation, the thrust (for a turbojet or turbofan) or power (for a turboprop or piston aircraft) is lapsed by a power of the density ratio (density at altitude to density at sea level). For turbojets and turbofans, this exponent is set to 1. For turboprops or piston aircraft, this exponent is set to 0 (no lapse). Currently, the user is unable to specify the exponent. However, it can be modified inside the "EngineLapse" function, which is housed in the "PropulsionPkg" folder.
4. The "OptimizationPkg" is currently deprecated and only runs on previous versions of FAST. Updates to this package are expected to commence in Spring/Summer 2024 and be released by the end of 2024.
5. Currently, we are in the process of switching to a new off-design engine model. As a result of that, some of the engines provided in the "+EngineModelPkg\+EngineSpecsPkg" are not fully up to date. The engines that currently work are the LEAP-1A26, CF34-8E5, and any turboprop engine. If you want to use a turbofan engine not listed above, please refer to "+EngineModelPkg\SimpleOffDesign" for the necessary coefficients that need to be provided to use the fuel flow equation. Additionally, due to this switch, please refrain from using the "+EngineModelPkg\TurbofanOffDesign" function or any functions that it calls within its routine.

# (VII) Testing FAST:

Multiple unit tests are shipped with FAST to ensure that the code is operating correctly. In order to test FAST, run the following command:

```matlab
>> TestFAST();
```

If all of the tests run correctly, then FAST is up-to-date and can be ran. If some of the tests fail, please submit an issue on GitHub using the following link: [https://github.com/ideas-um/FAST/issues](https://github.com/ideas-um/FAST/issues).

# (VIII) Acknowledgments:

This work is sponsored by the NASA Aeronautics Research Mission Directorate and the Electrified Powertrain Flight Demonstration (EPFD) project, "Development of a Parametrically Driven Electrified Aircraft Design and Optimization Tool". The IDEAS Lab would like to thank Ralph Jansen, Andrew Meade, Karin Bozak, Amy Chicatelli, Noah Listgarten, Dennis Rohn, and Gaudy Bezos-O'Connor from the NASA EPFD project for supporting this work and providing valuable technical input and feedback throughout the duration of the project.

Glenn Engineering and Research Support Contract (GEARS)
Contract No. 80GRC020D0003


