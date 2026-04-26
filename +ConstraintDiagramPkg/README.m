function [] = README()
%
% Copyright 2024 The Regents of the University of Michigan,
% The Integrated Design of Efficient Aerospace Systems
% Laboratory
% 
% Constraint Diagram Package (+ConstraintDiagramPkg)
%
% Written by the IDEAS Lab at the University of Michigan. 
% https://ideas.engin.umich.edu
%
% Principal Authors:
%     Paul Mokotoff, prmoko@umich.edu
%     Max Arnson, marnson@umich.edu
%
% Principal Investigator:
%     Dr. Gokcin Cinar, cinar@umich.edu
%
% Additional Contributors:
%     Huseyin Acar
%     Yi-Chih (Arenas) Wang
%     Miranda Stockhausen
%     Emma Cassidy
%     Nawa Khailany
%     Janki Patel
%     Michael Tsai
%     Vaibhav Rau
% 
% README last updated: 06 Oct 2025
% 
% -------------------------------------------------------------------------
%
% (I) Overview
%
% The ConstraintDiagramPkg allows the user to create a constraint diagram
% given a set of FAA or user-prescribed regulations. Current FAA-supported
% regulations are within 14 CFR 25:
%
%     25.111  - Takeoff Climb
%     25.119  - Landing Climb, All Engines Operative
%     25.121a - Transition Climb
%     25.121b - Second Segment Climb
%     25.121c - Enroute Climb
%     25.121d - Landing Climb, One Engine Inoperative
%
% Other pertinent requirements exist for the takeoff/landing field length
% (JetTOFL/JetLFL), minimum approach speed (JetApp), cruise/diversion
% (JetCrs/JetDiv), and the service ceiling (JetCeil). However, these are
% not explicitly defined in 14 CFR 25, but may be necessary for sizing a
% configuration.
%
% In future releases, 14 CFR 23 regulations may be added. Alternatively,
% these can be added by someone else within the aerospace community. 
% Despite this limitation, the main function, "ConstraintDiagram", has
% already been built to accommodate additional constraint functions and
% generate diagrams for aircraft certified under 14 CFR 23.
%
% Turbofan aircraft are always certified under 14 CFR 25, and
% thrust-to-weight ratio and wing loading (T/W-W/S) diagram is created. For
% turboprop and piston aircraft, a power-to-weight ratio and wing loading
% diagram (P/W-W/S) is created if the aircraft is certified under 14 CFR
% 23. If the turboprop/piston aircraft is certified under 14 CFR 25, a
% power loading and wing loading diagram (W/P-W/S) is created.
%
% -------------------------------------------------------------------------
%
% (II) Using this Package
%
% First, create a Constraint Specification File. Examples are included in
% the "+ConstraintSpecsPkg" and include both turbofan and turboprop
% aircraft certified by 14 CFR 25. A comprehensive list of the possible
% input parameters is provided in Section III. The actual input parameters
% needed depend on the requirements used for the analysis. Please consult
% each constraint function for the necessary parameters that must be input
% to execute the code accordingly.
%
% Second, run the "ConstraintDiagram" function. This involves inputting the
% aircraft model made in the previous step. In the example files, the
% function is called within the Constraint Specification File (for
% convenience). However, it can be called elsewhere, or embedded in another
% piece of code. (We keep it in the Constraint Specification File so that
% we can plot the sizing point from literature in red.)
%
% -------------------------------------------------------------------------
%
% (III) Inputs Used by +ConstraintSpecsPkg
%
% The constraint specification files in "+ConstraintSpecsPkg" use the
% following fields in the "Aircraft.Specs" data structure, where "Aircraft"
% is the name of the overarching data structure. Each specification may
% not use each field.
%
% Top-level requirements (TLAR)
%     Class   -  the aircraft class, either: 
%                    a) "Turbofan"
%                    b) "Turboprop"
%                    c) "Piston"
%
%     CFRPart -  the certification regulations used, either:
%                    a) 23 - 14 CFR 23
%                    b) 25 - 14 CFR 25
%
%     ReqType -  the requirements used in the packaged constraint
%                functions, either:
%                    a) 0 - Roskam
%                    b) 1 - Mattingly
%                    c) 2 - deVries et al.
%
% Performance
%     Alts.Crs       - cruise altitude (m)
%
%     Alts.Srv       - service ceiling (m)
%
%     Alts.Div       - diversion altitude (m)
%
%     Vels.Stl       - stall speed (m/s)
%
%     Vels.Crs       - cruise speed (Mach)
%
%     Vels.App       - approach speed (m/s)
%
%     Vels.Div       - diversion speed (Mach)
%
%     TOFL           - takeoff field length (m)
%
%     LFL            - landing field length (m)
%
%     ObstLen        - obstacle clearance length, subtracted from the
%                      landing field length (m)
%
%     TempInc        - multiplicative factor to increase engine size for a
%                      50 F temperature increase (typically 1.25)
%
%     MaxCont        - multiplicative factor to increase engine size for
%                      maximum continuous thrust (typically 1 / 0.94)
%
%     PsLoss         - percent specific excess power loss (if using novel
%                      performance requirements - see the setting at the
%                      end of this section)
%
%     Wland_MTOW     - landing weight as a fraction of MTOW
%
%     ConstraintFuns - array of strings indicating the constraint functions
%                      that shall be run to generate the constraint diagram
%
%     ConstraintLabs - array of strings indicating how each constraint
%                      function should be labeled on the constraint diagram
%
%     ExtraGrad      - an additional all engine operative climb gradient
%                      that acts as an additional requirement
%
% Aerodynamics (Aero)
%     W_S.SLS - wing loading at sea level (kg / m^2)
%
%     AR      - aspect ratio
%
%     CL.Crs  - cruise lift coefficient
%
%     CL.Tko  - takeoff lift coefficient
%
%     CL.Lnd  - landing lift coefficient
%
%     CD0.Crs - cruise parasite drag coefficient
%
%     CD0.Tko - takeoff parasite drag coefficient
%
%     CD0.Lnd - landing parasite drag coefficient
%
%     e.Crs   - cruise Oswald efficiency factor
%
%     e.Tko   - takeoff Oswald efficiency factor
%
%     e.Lnd   - landing Oswald efficiency factor
%
% Weights (Weight)
%     MTOW - maximum takeoff weight
%
% Propulsion
%     T_W.SLS    - thrust-to-weight ratio at sea-level, used for turbofan
%                  aircraft
%
%     NumEngines - number of engines installed (used for 14 CFR 25 climb
%                  gradients)
%
% Power
%     P_W.SLS - power-to-weight ratio at sea-level, used for turboprop or
%               piston aircraft (kW/kg)
%
%
% Additionally, one field must be specified in the Aircraft.Settings
% structure, where "Aircraft" is the name of the overarching data
% structure:
%
% ConstraintType - defines which climb gradients should be used, either:
%                      a) 0 - climb gradients from 14 CFR 25
%                      b) 1 - climb gradients as a function of the specific
%                             excess power loss
%
% -------------------------------------------------------------------------
%
% end ConstraintDiagramPkg.README
%
end