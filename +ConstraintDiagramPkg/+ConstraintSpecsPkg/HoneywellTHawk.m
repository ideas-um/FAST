function [Aircraft] = HoneywellTHawk()
%
% [Aircraft] = HoneywellTHawk()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 28 apr 2026
% 
% model the Honeywell RQ-16 T-Hawk UAS system.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Aircraft - aircraft data structure to be used for analysis
%                size/type/units: 1-by-1 / struct / []
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
Aircraft.Specs.TLAR.Class = "UAV";

% get the FAA requirements for the aircraft
Aircraft.Specs.TLAR.CFRPart = 107;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% performance parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% cruise altitude (m) and speed (m/s)
Aircraft.Specs.Performance.Alts.Crs = 0;
Aircraft.Specs.Performance.Vels.Crs = 20.56;

% constraints to use
Aircraft.Specs.Performance.ConstraintFuns = ["UAVMaxKE"; "UAVMaxSpeed"; "UAVCrs"];

% labels to use
Aircraft.Specs.Performance.ConstraintLabs = ["Max. KE"; "Max. Speed"; "Cruise"];

% maximum allowable speed (m/s)
Aircraft.Specs.Performance.VMax = 25;

% maximum allowable kinetic energy (J)
Aircraft.Specs.Performance.KEMax = 2500;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% aerodynamic parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% lift coefficient
Aircraft.Specs.Aero.CL.Crs = 1.0;

% nominal L/D
Aircraft.Specs.Aero.L_D.Crs = 2.0;

% baseline wing loading (kg/m^2)
Aircraft.Specs.Aero.W_S.SLS = 10;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% weights                    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% maximum takeoff weight (kg)
Aircraft.Specs.Weight.MTOW = 7.71;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% propulsion system          %
% specifications             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% number of engines
Aircraft.Specs.Propulsion.NumEngines = 1;

% power loading (kW/kg)
Aircraft.Specs.Power.P_W.SLS = 0.16;


%% RUN THE CONSTRAINT ANALYSIS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% determine which constraints to use (0 = 14 CFR 25; 1 = novel)
Aircraft.Settings.ConstraintType = 0;

% create a constraint diagram
ConstraintDiagramPkg.ConstraintDiagram(Aircraft);

% format the axis sizes
axis square

% turn on gridlines
grid on

% get the axis object
A = gca;

% set the grid to be semi-transparent and move it to the top
A.GridAlpha = 0.5;
A.Layer = "top";

% add minor gridlines
A.XMinorGrid = "on";
A.YMinorGrid = "on";

% increase font size
set(gca, "FontSize", 28);

% ----------------------------------------------------------

end