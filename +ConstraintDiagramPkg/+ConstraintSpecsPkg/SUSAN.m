function [] = SUSAN()
%
% [] = SUSAN()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 25 sep 2025
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
Aircraft.Specs.TLAR.Class = "Turbofan";

% CFR regulations to certify
Aircraft.Specs.TLAR.CFRPart = 25;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% performance parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% altitudes
Aircraft.Specs.Performance.Alts.Crs = UnitConversionPkg.ConvLength(40000, "ft", "m");
Aircraft.Specs.Performance.Alts.Srv = UnitConversionPkg.ConvLength(42000, "ft", "m");

% stall speed
Aircraft.Specs.Performance.Vels.Stl = sqrt(2 * 634 * 9.81 / 2 / 1.225);

% cruise mach number
Aircraft.Specs.Performance.Vels.Crs = 0.775;

% runway lengths and obstacle clearances
Aircraft.Specs.Performance.TOFL    = 2750;
Aircraft.Specs.Performance.LFL     = 2750;
Aircraft.Specs.Performance.ObstLen = UnitConversionPkg.ConvLength(1000, "ft", "m");

% multiplicative factors for OEI conditions
Aircraft.Specs.Performance.TempInc = 1.25;
Aircraft.Specs.Performance.MaxCont = 1 / 0.94;

% design specific excess power loss
Aircraft.Specs.Performance.PsLoss = 0.7689; % mean for twin-engine aircraft

% landing weight as a fraction of MTOW (computed from baseline)
Aircraft.Specs.Performance.Wland_MTOW = 0.8411;

% requirement type (0 = Roskam; 1 = Mattingly, 2 = de Vries et al.)
Aircraft.Specs.TLAR.ReqType = 0;

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

% wing loading
Aircraft.Specs.Aero.W_S.SLS = 634;

% wing properties
Aircraft.Specs.Aero.AR = 11.22091;

% lift coefficients (from Chau & Duensing and FINCH)
Aircraft.Specs.Aero.CL.Crs = 0.61;
Aircraft.Specs.Aero.CL.Tko = 2.0;
Aircraft.Specs.Aero.CL.Lnd = 3.5;

% parasite drag coefficients (computed)
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

% MTOW
Aircraft.Specs.Weight.MTOW = UnitConversionPkg.ConvMass(190890, "lbm", "kg");

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% propulsion system          %
% specifications             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% thrust-weight ratio
Aircraft.Specs.Propulsion.T_W.SLS = 0.298;

% number of engines
Aircraft.Specs.Propulsion.NumEngines = 2;


%% RUN THE CONSTRAINT ANALYSIS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% determine which constraints to use (0 = 14 CFR 25; 1 = novel)
Aircraft.Settings.ConstraintType = 1;

% create a constraint diagram
ConstraintDiagramPkg.ConstraintDiagram(Aircraft);

% add the existing sizing point
hold on
scatter(Aircraft.Specs.Aero.W_S.SLS, Aircraft.Specs.Propulsion.T_W.SLS, 48, "o", "MarkerEdgeColor", "red", "MarkerFaceColor", "red");

end