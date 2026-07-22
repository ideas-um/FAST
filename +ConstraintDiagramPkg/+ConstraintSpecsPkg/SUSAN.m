function [] = SUSAN()
%
% [] = SUSAN()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 22 jul 2026
%
% create a constraint diagram for NASA's SUSAN aircraft.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     none
%

% initial cleanup
clc, close all


%% DEFINE THE AIRCRAFT'S PARAMETERS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% top-level aircraft         %
% requirements               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% aircraft class
Aircraft.Specs.TLAR.Class = "Turboprop";

% CFR regulations to certify
Aircraft.Specs.TLAR.CFRPart = 25;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% performance parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% altitudes [cruise from economy mission outlined in 2024 paper; service
% ceiling estimated]
Aircraft.Specs.Performance.Alts.Crs = UnitConversionPkg.ConvLength(37000, "ft", "m");
Aircraft.Specs.Performance.Alts.Srv = UnitConversionPkg.ConvLength(40000, "ft", "m");

% stall speed [based on wing loading from 2024 paper]
Aircraft.Specs.Performance.Vels.Stl = sqrt(2 * 634 * 9.81 / 2 / 1.225);

% cruise mach number [2024 paper, Tab. 5]
Aircraft.Specs.Performance.Vels.Crs = 0.775;

% runway lengths and obstacle clearances [Boeing 737-800 MAX airport
% planning manual]
Aircraft.Specs.Performance.TOFL    = 2040;
Aircraft.Specs.Performance.LFL     = 1700;
Aircraft.Specs.Performance.ObstLen = UnitConversionPkg.ConvLength(1000, "ft", "m");

% multiplicative factors for OEI conditions
Aircraft.Specs.Performance.TempInc = 1.25;
Aircraft.Specs.Performance.MaxCont = 1 / 0.94;

% design specific excess power loss
% 0.9171 - mean SEP loss for twin-engine aircraft
% 0.0720 - lose a single distributed propulsor (most outboard)
% 0.3426 - lose the aft turbofan engine
Aircraft.Specs.Performance.PsLoss = 0.3426;

% landing weight as a fraction of MTOW (computed from FAST simulations)
Aircraft.Specs.Performance.Wland_MTOW = 0.8411;

% requirement type (0 = Roskam; 1 = Mattingly, 2 = de Vries et al.)
Aircraft.Specs.TLAR.ReqType = 2;

% constraints to use
Aircraft.Specs.Performance.ConstraintFuns = ["Jet25_111"; "Jet25_119"; "Jet25_121a"; "Jet25_121b"; "Jet25_121c"; "Jet25_121d"; "JetCrs"; "JetLFL"; "JetTOFL"];

% labels to use
Aircraft.Specs.Performance.ConstraintLabs = ["25.111"; "25.119"; "25.121a"; "25.121b"; "25.121c"; "25.121d"; "Cruise"; "Landing"; "TOFL"];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% aerodynamic parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% wing loading [2024 paper]
Aircraft.Specs.Aero.W_S.SLS = 634;

% wing properties [2024 paper]
Aircraft.Specs.Aero.AR = 9.44;

% lift coefficients [cruise lift coefficient from 2024 paper, others are
% estimated based DEP tech. improvements]
Aircraft.Specs.Aero.CL.Crs = 1.0; % given as 0.61 in 2024 paper, but need maximum CL for the constraint diagram
Aircraft.Specs.Aero.CL.Tko = 2.5;
Aircraft.Specs.Aero.CL.Lnd = 3.0;

% parasite drag coefficients (computed from Raymer)
Aircraft.Specs.Aero.CD0.Crs = 0.0176;
Aircraft.Specs.Aero.CD0.Tko = 0.0626; % cruise CD0 + 0.045
Aircraft.Specs.Aero.CD0.Lnd = 0.1076; % cruise CD0 + 0.090

% Oswald efficiency factors (computed using source from deVries + 0.025)
Aircraft.Specs.Aero.e.Crs = 0.8144;
Aircraft.Specs.Aero.e.Tko = 0.7737; % 95% of cruise e
Aircraft.Specs.Aero.e.Lnd = 0.7330; % 90% of cruise e

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% weights                    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% MTOW [2024 paper]
Aircraft.Specs.Weight.MTOW = UnitConversionPkg.ConvMass(190890, "lbm", "kg");

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% propulsion system          %
% specifications             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% thrust-weight ratio [2024 paper]
Aircraft.Specs.Propulsion.T_W.SLS = 0.298;

% number of engines [for appropriate FARs]
Aircraft.Specs.Propulsion.NumEngines = 2;

% lapse rate [estimated]
Aircraft.Specs.Propulsion.LapseRate.Crs = 0.35;

% alternatively, a power-weight ratio [assumed takoeff airspeed as the
% "characteristic speed" to avoid singularities]
Aircraft.Specs.Power.P_W.SLS = (Aircraft.Specs.Propulsion.T_W.SLS * 1.21 * Aircraft.Specs.Performance.Vels.Stl) * 9.81 / 1000;


%% RUN THE CONSTRAINT ANALYSIS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% determine which constraints to use (0 = 14 CFR 25; 1 = novel)
Aircraft.Settings.ConstraintType = 1;

% create a constraint diagram
ConstraintDiagramPkg.ConstraintDiagram(Aircraft);

% add the existing sizing point
hold on
scatter(Aircraft.Specs.Aero.W_S.SLS * 9.81 / 1000, 1 / (Aircraft.Specs.Power.P_W.SLS / 9.81 * 1000), 48, "o", "MarkerEdgeColor", "red", "MarkerFaceColor", "red");

end