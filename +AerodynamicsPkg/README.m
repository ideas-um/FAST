function [] = README()
%
% Copyright 2024 The Regents of the University of Michigan,
% The Integrated Design of Efficient Aerospace Systems
% Laboratory
% 
% Aerodynamics Package (+AerodynamicsPkg)
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
% README last updated: 15 June 2026
% 
% -------------------------------------------------------------------------
%
% (I) Overview
%     
%     The Aerodynamics Package is contains all routines utilized in FAST's
%     aerodynamic analysis. Currently, there are two models available to
%     use: 1) assume a constant lift-to-drag ratio in the climb, cruise,
%     and descent segments; or 2) compute the drag polar from a first-order
%     empirical relation. The first-order aerodynamic model was sourced
%     from Aviary, NASA's latest aircraft design and analysis tool.
%
%     In addition to a first-order aerodynamic model, additional
%     capabilities for modeling windmilling and trim drag were included
%     for simulating engine inoperative scenarios during a mission. The
%     windmilling drag model was developed for turbofan engines, but can
%     accommodate turboprops or ducted fans with significant correction
%     factors. Additionally, a trim drag model is available for
%     estimating the drag from deflecting the rudder to trim the aircraft
%     during one engine inoperative conditions (but assumes that all
%     engines are equally-sized).
%
% -------------------------------------------------------------------------
%
% (II) Using the Package
%
%     While defining the aircraft, select one of the two aerodynamic
%     analysis methods and assigning it to the
%     Aircraft.Specs.Aero.L_D.Method variable:
%
%         a) Constant Lift-to-Drag Ratio:
%            @(Aircraft) AerodynamicsPkg.ConstantLD(Aircraft);
%
%         b) First-Order Drag Polar Model
%            @(Aircraft) AerodynamicsPkg.DragPolar(Aircraft);
%            
%     After selecting the aerodynamic analysis method, the appropriate
%     variables must be defined (all under the Aircraft.Specs.Aero
%     structure).
%
%     If assuming a constant lift-to-drag ratio, define the following
%     variables:
%
%         1) L_D.ClbCF: calibration factor for the climb/descent
%            lift-to-drag ratio.
%
%         2) L_D.CrsCF: calibration factor for the cruise lift-to-drag
%            ratio.
%
%         3) L_D.Clb: climb lift-to-drag ratio.
%
%         4) L_D.Crs: cruise lift-to-drag ratio.
%
%         5) L_D.Des: descent lift-to-drag ratio.
%
%     If utilizing the first-order drag polar model, define the following
%     variables:
%
%          1) ScaleCD0: scale factor for the parasite drag coefficient.
%
%          2) ScaleCDI: scale factor for the induced drag coefficient.
%
%          3) ScaleSub: scale factor for the lift-to-drag ratio across all
%             subsonic flight regimes.
%
%          4) ScaleSup: scale factor for the lift-to-drag ratio across all
%             supersonic flight regimes.
%
%          5) ScaleWnd: scale factor for the windmilling drag during engine
%             inoperative scenarios.
%
%          6) Components.Cf: skin friction factor coefficient for all
%             components on the aircraft (row vector).
%
%          7) Components.Re: Reynolds number to simulate the flow at (row
%             vector).
%
%          8) Components.Fine: fineness ratio for each component (row
%             vector).
%
%          9) Components.Swet: wetted area for each component (row vector).
%
%         10) Components.LamFracUpper: fraction of airflow that is laminar
%             along the upper surface of each component (row vector).
%
%         11) Components.LamFracLower: fraction of airflow that is laminar
%             along the lower surface of each component (row vector).
%
%         12) Wing.S: wing area.
%
%         13) Wing.AirfoilTech: airfoil technology parameter, and can take
%             values between 1 (traditional technology) or 2 (advanced
%             technology).
%
%         14) ExcrescencesDrag: multiplicative factor to account for
%             excerscences drag, represented as a decimal. For example, a
%             5% increase is reported as 0.05.
%
%         15) DesignCL: design lift coefficient for the aircraft.
%
%         16) DesignMach: design mach number for the aircraft.
%
%         17) Wing.AR: wing aspect ratio.
%
%         18) Wing.MaxCamber: maximum camber along the wing.
%
%         19) Wing.t_c: maximum thickness-to-chord ratio.
%
%         20) Wing.e: wing Oswald efficiency factor.
%
%         21) Wing.Sweep: wing sweep along the quarter-chord.
%
%         22) Wing.TR: wing taper ratio.
%
%         23) Wing.Redux: flag to adjust for wings with extreme taper
%             ratios. This is traditionally set to 0 (no extreme taper),
%             but can be set to 1 if needed.
%
%         24) Vtail.AR: vertical tail aspect ratio.
%
%         25) Vtail.e: vertical tail Oswald efficiency factor.
%
%         26) Vtail.S: vertical tail area.
%
%         27) Vtail.Eta: ratio of dynamic pressures experienced between the
%             vertical tail and wing. For example, if the dynamic pressure
%             on the vertical tail is 90% of that on the wing, input 0.90.
%
%         28) Vtail.TAF: vertical tail lift curve slope, expressed as a
%             multiple of the lift curve slope for a thin airfoil (2 pi
%             /rad).
%
%         29) Vtail.VArm: moment arm between the wing mean aerodynamic
%             center and the vertical tail aerodynamic center.
%
%         30) Rudder.S: rudder area.
%
%         31) Rudder.b: rudder span (length).
%
%         32) Fuse.Area: fuselage area.
%
%         33) Fuse.Len_Diam: ratio of the fuselage length to its diameter.
%
%         34) Fuse.Diam_Span: ratio of the fuselage diameter to the
%             wingspan.
%
%         35) Fuse.DistToEng: moment arm between the fuselage centerline
%             and engine that fails, if simulated engine inoperative
%             conditions.
%
%         36) BaseArea: for internally-mounted engines, the difference
%             between the exit and inlet areas.
%
%     For additional information about these variables, visit the
%     "variable_meta_data.py" script at the following website:
%     https://github.com/OpenMDAO/Aviary/blob/main/aviary/variable_info
%
% -------------------------------------------------------------------------
%
% end AerodynamicsPkg.README
%
end