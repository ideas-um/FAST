function [] = Boeing777()
%
% [] = Boeing777()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 25 sep 2025
%
% create a constraint diagram for a boeing 777, found in the aircraft
% design metabook.
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
Aircraft.Specs.Performance.Alts.Crs = UnitConversionPkg.ConvLength(40000, "ft", "m"); % approx 4,000 ft less than A320 absolute ceiling
Aircraft.Specs.Performance.Alts.Srv = UnitConversionPkg.ConvLength(42000, "ft", "m"); % approx 2,000 ft less than A320 absolute ceiling

% stall speed
Aircraft.Specs.Performance.Vels.Stl = sqrt(2 * 695.5 * 9.81 / 2 / 1.225);

% cruise mach number
Aircraft.Specs.Performance.Vels.Crs = 0.84;

% runway lengths and obstacle clearances
Aircraft.Specs.Performance.TOFL    = UnitConversionPkg.ConvLength(12000, "ft", "m");
Aircraft.Specs.Performance.LFL     = UnitConversionPkg.ConvLength(12000, "ft", "m");
Aircraft.Specs.Performance.ObstLen = UnitConversionPkg.ConvLength( 1000, "ft", "m");

% multiplicative factors for OEI conditions
Aircraft.Specs.Performance.TempInc = 1.25;
Aircraft.Specs.Performance.MaxCont = 1 / 0.94;

% design specific excess power loss
Aircraft.Specs.Performance.PsLoss = 0.6238;

% landing weight as a fraction of MTOW
Aircraft.Specs.Performance.Wland_MTOW = 0.65;

% requirement type (0 = Roskam; 1 = Mattingly, 2 = de Vries et al.)
Aircraft.Specs.TLAR.ReqType = 0;

% constraints to use
Aircraft.Specs.Performance.ConstraintFuns = ["Jet25_111"; "Jet25_119"; "Jet25_121a"; "Jet25_121b"; "Jet25_121c"; "Jet25_121d"; "JetCeil"; "JetCrs"; "JetLFL"; "JetTOFL"];

% labels to use
Aircraft.Specs.Performance.ConstraintLabs = ["25.111"; "25.119"; "25.121a"; "25.121b"; "25.121c"; "25.121d"; "Ceiling"; "Cruise"; "Landing"; "TOFL"];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% aerodynamic parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% wing loading
Aircraft.Specs.Aero.W_S.SLS = 695.5;

% aspect ratio
Aircraft.Specs.Aero.AR = 9.8;

% lift coefficients
Aircraft.Specs.Aero.CL.Crs = 0.9;
Aircraft.Specs.Aero.CL.Tko = 2.0;
Aircraft.Specs.Aero.CL.Lnd = 2.6;

% parasite drag coefficients
Aircraft.Specs.Aero.CD0.Tko = 0.06097;
Aircraft.Specs.Aero.CD0.Crs = 0.01597;
Aircraft.Specs.Aero.CD0.Lnd = 0.11597;

% Oswald efficiency factors
Aircraft.Specs.Aero.e.Crs = 0.8514;
Aircraft.Specs.Aero.e.Tko = 0.8012;
Aircraft.Specs.Aero.e.Lnd = 0.7512;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% weights                    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% MTOW
Aircraft.Specs.Weight.MTOW = 347815;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% propulsion system          %
% specifications             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% thrust-weight ratio
Aircraft.Specs.Propulsion.T_W.SLS = 0.2888;

% number of engines
Aircraft.Specs.Propulsion.NumEngines = 2;


%% RUN THE CONSTRAINT ANALYSIS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% determine which constraints to use (0 = 14 CFR 25; 1 = novel)
Aircraft.Settings.ConstraintType = 0;

% create a constraint diagram
ConstraintDiagramPkg.ConstraintDiagram(Aircraft);

% add the existing sizing point
hold on
scatter(Aircraft.Specs.Aero.W_S.SLS, Aircraft.Specs.Propulsion.T_W.SLS, 48, "o", "MarkerEdgeColor", "red", "MarkerFaceColor", "red");


end