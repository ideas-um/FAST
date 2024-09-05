---

title: 'FAST: A **F**uture **A**ircraft **S**izing **T**ool for Advanced Aircraft and Propulsion System Design'

tags:
  - Matlab
  - Sustainable Aviation
  - Conceptual Aircraft Design

authors:
  - name: Paul R. Mokotoff
    orcid: 0009-0006-4651-5597
    affiliation: 1

  - name: Maxfield Arnson
  - orcid: 0009-0000-9432-5858
    affiliation: 1
  
  - name: Gokcin Cinar
    orcid: 0000-0002-2562-0332
    affiliation: 1
    corresponding: true

affiliations:

 - name: Department of Aerospace Engineering, University of Michigan
   index: 1

date: 05 September 2024

bibliography: paper.bib

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

Atmospheric emissions from aviation have contributed to approximately 3.5% of all anthropogenic climate impact [@lee2021contribution].
To reduce aviation-related emissions, innovative aircraft designs, including electrified aircraft propulsion, are under development.
For instance, NASA's Electrified Powertrain Flight Demonstration (EPFD) Project is advancing these technologies with industry partners [@nasa2022epfd].
However, current aircraft sizing tools require detailed design information that may not be available early in the development process, particularly for novel technologies.
This can yield suboptimal designs and inhibits innovation.
Thus, there is a need for a computational tool to rapidly size an aircraft configuration and allow the designer to explore the vast design space, examine tradeoffs, and evaluate alternative designs.

The **F**uture **A**ircraft **S**izing **T**ool (**FAST**) addresses this challenge by rapidly sizing aircraft with *any* propulsion architecture, including conventional, electric, and hybrid-electric systems, even with limited initial data. 
FAST enables engineers to explore various aircraft configurations, evaluate design alternatives, assess performance across the flight envelope, and visualize concepts during the sizing process.
By supporting early-stage design, FAST aids in developing sustainable aviation technologies crucial for reducing the industry's carbon footprint.

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

Existing tools for conceptual aircraft design typically focus on the later stages of the conceptual phase, requiring detailed design information upfront [@cinar2018methodology].
These tools often involve complex analyses that can take several minutes to converge on a design, limiting the ability to rapidly explore and compare different configurations.
This is particularly challenging for novel aircraft designs, where key parameters may be unknown at the outset.

FAST addresses these challenges by leveraging historical data from over 450 aircraft and 200 engines to create predictive regressions [@arnson2025predicting].
These regressions are employed to estimate any design parameters that the user may not have, such as engine weight based on required thrust or power.
Combined with physics-based models, FAST rapidly analyzes an aircraft configuration, converging on a design faster than existing detailed design tools.
This rapid sizing is achieved through an energy-based mission analysis, where the aircraft is approximated as a point mass to evaluate the aircraft dynamics, forces, and energy required for a given mission [@anderson1999aircraft; @cinar2018methodology].
Additionally, FAST can analyze any propulsion architecture, including conventional, electric, and hybrid systems, using a graph theory-inspired approach that represents propulsion connections and in-flight operations as matrices [@cinar2020framework].

FAST has been utilized in multiple research projects to assess the performance of conventional and electrified aircraft.
One example is its use in trade studies for NASA's EPFD project.
An electrified LM100J freighter aircraft was evaluated for fuel burn savings by integrating electric motors in place of outboard gas-turbine engines [@mokotoff2025fast], as shown in Fig. \autoref{Fig:LM100J-PropArch}.
The trade studies explored the fuel burn savings achieved by removing a fraction of the LM100J's payload to accommodate the battery required to power electric motors.

![Electrified LM100J propulsion architecture \label{Fig:LM100J-PropArch}](Figures/ElectrifiedPropArch-NoLambda.PNG){width = 80%}

FAST was also used to explore advanced propulsion system designs and their impacts on the final aircraft design [@arnson2024system].
Advanced ATR 42-600 configurations were designed with battery electric and hydrogen fuel cell electric propulsion systems.
The aircraft's performance was assessed while varying key performance parameters such as the battery gravimetric specific energy, powertrain efficiency, and fuel cell power-to-weight ratio.
Another application of FAST includes modeling NASA's **SU**bsonic **S**ingle **A**ft E**n**gine (SUSAN) concept, and exploring how advanced technologies impact the aircraft's performance [@wang2025subsonic].
More granular aerodynamic and propulsive models are currently being incorporated into FAST to better assess the benefits of boundary layer ingestion and distributed electric propulsion technologies.
Furthermore, FAST was used in a feasibility study to size a fleet of hybrid electric aircraft and operate them on routes currently flown by regional jets [@deng2023sizing].
This work served as a proof-of-concept for understanding how hybrid electric aircraft can be seamlessly integrated into a regional airline's fleet while maintaining the same operational capabilities as existing aircraft in the fleet.

<!--------------------------------------------------------->
<!--------------------------------------------------------->
<!--------------------------------------------------------->

<!----------------------------
|                            |
| FAST WORKFLOW              |
|                            |
----------------------------->

# FAST Workflow Overview

Figure \autoref{Fig:HighLevelDSM} provides a high-level overview of FAST's main functionality, showing the user inputs and modules in the workflow.
Data is fed forwards and backwards as shown by red and green arrows, respectively.

![High-level overview of FAST's main functionality (produced via [@gray2019openmdao]) \label{Fig:HighLevelDSM}](Figures/Collapsed-WtArrows-Edited.PNG){width = 80%}

First, the user inputs the Aircraft Specifications and a Mission Profile, which informs FAST how to fly the aircraft while sizing it.
Then, FAST's Initialization module assembles the user-provided information into an aircraft model.
If any parameters are unknown, FAST utilizes its historical database [@arnson2025predicting] to generate regressions that predict these values.
Once the model is complete, FAST generates mathematical representations of the aircraft's propulsion architecture and its operation during flight (from [@cinar2020framework]), and checks that the mission profile provided by the user is valid.

After initialization, the aircraft is sized using a fixed-point iteration [@ascher2011first].
Note that FAST does not perform a constraint analysis and assumes that the point performance parameters input (thrust- or power-weight ratio and wing loading, which remain fixed) are feasible.
First, there is an iteration between the aircraft's point performance parameters and operating empty weight (OEW, which consists of the airframe, propulsion system, and crew weights).
Second, an energy-based mission analysis [@anderson1999aircraft; @cinar2018methodology] is employed to calculate the energy required for the mission and allocate it amongst the available energy sources (e.g., jet fuel, hydrogen, battery).
Lastly, the energy required from the mission analysis informs the energy source sizing, which then returns a new maximum takeoff weight (MTOW).
The iteration continues until converging on MTOW.

Upon completion of the sizing process, the aircraft model is returned to the user as a Matlab `struct`, allowing for further analysis or integration into other studies.
FAST also offers post-processing options, such as mission history visualization (i.e., information about the flight simulated, see Fig. \autoref{Fig:MissionHistory}) and geometric visualization of the sized aircraft (see Fig. \autoref{Fig:GeometryExample}).
To visualize an aircraft concept, users may either prescribe their own aircraft geometry or use one that is shipped with FAST [@khailany2025aircraft].

![Example of a mission history \label{Fig:MissionHistory}](Figures/MissionHistoryLabeled.PNG){width = 80%}

![Transport aircraft geometry shipped with FAST \label{Fig:GeometryExample}](Figures/Transport.PNG){width = 80%}

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
