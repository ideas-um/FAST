---
#
title: 'FAST: A **F**uture **A**ircraft **S**izing **T**ool for Advanced Aircraft and Propulsion System Design'
#
tags:
  - Matlab
  - Sustainable Aviation
  - Conceptual Aircraft Design
  - Electrified Aircraft Design
#
authors:
  - name: Paul R. Mokotoff
    orcid: 0009-0006-4651-5597
    affiliation: 1
#
  - name: Maxfield Arnson
    orcid: 0009-0000-9432-5858
    affiliation: 1
#
  - name: Gokcin Cinar
    orcid: 0000-0002-2562-0332
    affiliation: 1
    corresponding: true
#
affiliations:
  - name: Department of Aerospace Engineering, University of Michigan
    index: 1
#   
date: 11 November 2024
#
bibliography: paper.bib
#
---

<!--------------------------------------------------------->
<!--------------------------------------------------------->
<!--------------------------------------------------------->

<!----------------------------
|                            |
| SUMMARY                    |
|                            |
----------------------------->

# Summary

ICAO predicts that, without radical technological advancements, the global aviation industry will emit up to 28 gigatons of CO~2~ between 2020 and 2050 [@icao2022report].
To reduce aviation-related emissions, innovative aircraft technology, including electrified aircraft propulsion, are under development.
For instance, NASA's Electrified Powertrain Flight Demonstration (EPFD) Project is advancing these technologies with U.S. industry partners [@nasa2022epfd].
However, current aircraft sizing tools require detailed design information that may not be available early in the development process, particularly for novel technologies.
This can yield sub-optimal designs and inhibits innovation.
Thus, a computational tool is needed to easily and rapidly size an aircraft configuration while allowing the designer to explore the design space, examine tradeoffs, and evaluate alternative designs.

The **F**uture **A**ircraft **S**izing **T**ool (**FAST**) is a Matlab-based tool that addresses this challenge by rapidly sizing aircraft with *any* propulsion architecture, including conventional, electric, and hybrid-electric systems, even with limited initial data.
FAST enables engineers to explore various aircraft configurations, evaluate design alternatives, assess performance across a flight envelope, and visualize concepts during the sizing process.
By supporting early-stage design, FAST addresses a gap in currently available computational tools for developing sustainable aviation technologies to help reduce the industry's carbon footprint.

<!--------------------------------------------------------->
<!--------------------------------------------------------->
<!--------------------------------------------------------->

<!----------------------------
|                            |
| STATEMENT OF NEED          |
|                            |
| From JOSS:                 |
| A Statement of need section|
| that clearly illustrates   |
| the research purpose of the|
| software and places it in  |
| the context of related work|
|                            |
----------------------------->

# Statement of Need

During early-phase conceptual aircraft design, engineers know little information about their design.
This is particularly challenging for novel aircraft designs, as key parameters may be unknown at the outset.
Existing aircraft design tools are intended for late conceptual design, requiring detailed design information and a geometric configuration upfront [@cinar2018methodology; @david2021fast; @gratz2024aviary], or are coupled with design optimization environments [@lukaczyk2015suave; @gratz2024aviary; @david2021fast} such as OpenMDAO [@gray2019openmdao].
These tools can accommodate more detailed analyses, such as component weight estimations [@cinar2018methodology; @gratz2024aviary] or low-fidelity aerodynamic analyses [@lukaczyk2015suave; @david2021fast]. Such analyses require the user to select an aircraft configuration a-priori, which prohibits rapid design space exploration.

FAST addresses these challenges by leveraging historical data from over 450 aircraft and 200 engines to create predictive regressions [@arnson2025predicting].
These regressions are employed to estimate any design parameters that the user may not know, such as engine weight based on required thrust or power.
Combined with physics-based models, FAST rapidly analyzes an aircraft configuration, converging on a design faster than existing detailed design tools.
This rapid sizing is achieved through an energy-based mission analysis, which approximates the aircraft as a point mass to evaluate the aircraft dynamics, forces, and energy required for a given mission [@anderson1999aircraft; @cinar2018methodology].
Additionally, FAST can analyze any propulsion architecture, including conventional, electric, and hybrid systems, using a graph theory-inspired approach that represents propulsion system connections and in-flight operations as matrices [@cinar2020framework].

![Electrified freighter propulsion architecture.\label{Fig:LM100J-PropArch}](Figures/ElectrifiedPropArch-NoLambda.PNG)

FAST has been utilized in multiple research projects within NASA's EPFD project to assess the performance of conventional and electrified aircraft.
First, a commercial freighter was electrified by replacing the outboard gas-turbine engines with electric motors [@mokotoff2025fast], shown in \autoref{Fig:LM100J-PropArch}.
The trade studies explored the fuel burn savings achieved by removing a fraction of the freighter's payload to accommodate the electrified propulsion system components.
Also, NASA's **SU**bsonic **S**ingle **A**ft E**n**gine (**SUSAN**) concept was modeled in FAST and explored how advanced technologies impacted the aircraft's performance [@wang2025subsonic].
More granular aerodynamic and propulsive models were incorporated into FAST to better assess the benefits of boundary layer ingestion and distributed electric propulsion technologies.

FAST was also used to explore advanced propulsion system designs and their impacts on the final aircraft design [@arnson2024system].
Advanced ATR 42-600 configurations were designed with battery electric and hydrogen fuel cell electric propulsion systems.
The aircraft's performance was assessed while varying key performance parameters such as the battery gravimetric specific energy, powertrain efficiency, and fuel cell power-to-weight ratio.

ARPA-E used FAST to estimate the fuel/operating costs for electrified aircraft on domestic US flights [@debock2024special].
Also, a fleet of hybrid electric aircraft was sized and operated on routes currently flown by regional jets using FAST @[deng2023sizing].
This work demonstrated how hybrid electric aircraft can be integrated into a regional airline's fleet while maintaining the same operational capabilities as existing aircraft, assuming that the necessary battery-charging infrastructure and power supplies are available.

<!--------------------------------------------------------->
<!--------------------------------------------------------->
<!--------------------------------------------------------->

<!----------------------------
|                            |
| FAST WORKFLOW              |
|                            |
----------------------------->

# FAST Workflow Overview

![High-level overview of FAST's main functionality (produced using [@gray2019openmdao]).\label{Fig:HighLevelDSM}](Figures/Collapsed-WtArrows-Edited.PNG)

\autoref{Fig:HighLevelDSM} provides an overview of FAST's functionality, detailing all user inputs and modules.
Data is passed forwards (colored red) and provided as feedback (colored green) in an iterative process.

First, the user provides the Aircraft Specifications and a Mission Profile, which informs FAST how to fly the aircraft while sizing it.
Then, FAST's Initialization module assembles the user-provided information into an aircraft model and utilizes its historical database [@arnson2025predicting] to generate regressions and predict any unknown parameters.
Once the initial model is complete, FAST generates mathematical representations of the propulsion architecture and its operation during flight (from [@cinar2020framework]).

The aircraft is sized using a fixed-point iteration [@ascher2011first].
First, an inner iteration sizes the airframe and propulsion system between the "Airframe and Propulsion System Sizing" and "Weight Build-Up" modules.
FAST does not perform a constraint analysis and assumes that the thrust- or power-weight ratio and wing loading provided remain fixed and are feasible.
Then, an energy-based mission analysis [@anderson1999aircraft; @cinar2018methodology] calculates the energy required for the mission and allocates it amongst the available energy sources (jet fuel, hydrogen, battery).
Lastly, the energy required from the mission analysis informs the "Energy Source Sizing", which updates the aircraft's weight.
The iteration continues until converging on a sized aircraft.

![Example mission history plots.\label{Fig:MissionHistory}](Figures/MissionHistoryLabeled.PNG)

![Transport aircraft geometry shipped with FAST.\label{Fig:GeometryExample}](Figures/Transport.PNG)

After sizing, the aircraft model is returned as a data structure, allowing for further analysis or integration into other studies.
FAST also offers post-processing options, including mission history visualization (see \autoref{Fig:MissionHistoryLabeled}) and geometric visualization of the sized aircraft (see \autoref{Fig:GeometryExample}).
To visualize an aircraft concept, users either prescribe their own aircraft geometry or use one that is pre-defined within FAST [@khailany2025aircraft].

<!--------------------------------------------------------->
<!--------------------------------------------------------->
<!--------------------------------------------------------->

<!----------------------------
|                            |
| ACKNOWLEDGEMENTS           |
|                            |
----------------------------->

# Acknowledgements

This work is sponsored by the NASA Aeronautics Research Mission Directorate and the Electrified Powertrain Flight Demonstration (EPFD) project, "Development of a Parametrically Driven Electrified Aircraft Design and Optimization Tool".
The IDEAS Lab would like to thank Ralph Jansen, Andrew Meade, Karin Bozak, Amy Chicatelli, Noah Listgarten, Dennis Rohn, and Gaudy Bezos-O'Connor from the NASA EPFD project for supporting this work and providing valuable technical input and feedback throughout the duration of the project.
The work was performed under Glenn Engineering and Research Support Contract (GEARS) Contract No. 80GRC020D0003.

The authors would also like to thank Huseyin Acar, Nawa Khailany, Janki Patel, and Michael Tsai for their contributions to developing FAST.

<!--------------------------------------------------------->
<!--------------------------------------------------------->
<!--------------------------------------------------------->

<!----------------------------
|                            |
| REFERENCES                 |
| (included automatically)   |
|                            |
----------------------------->

# References
