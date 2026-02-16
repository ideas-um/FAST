function [OutTable] = DemoNewBatteryModel()
%
% [OutTable] = DemoNewBatteryModel()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 16 feb 2026
%
% size a notional electrified ERJ175 with and without a detailed battery
% model to showcase the differences in system-level performance
%
% INPUTS:
%     none
%
% OUTPUTS:
%     OutTable - table comparing system-level performance between both
%                configurations analyzed.
%                size/type/units: 1-by-1 / table / []
%

% initial cleanup
clc, close all

% get the electrified ERJ
Aircraft = AircraftSpecsPkg.ERJ175LR();

% add a PHE system
Aircraft.Specs.Propulsion.PropArch.Type = "PHE";

% downstream power splits
Aircraft.Specs.Power.LamDwn.SLS = 0.05;
Aircraft.Specs.Power.LamDwn.Tko = 0.05;
Aircraft.Specs.Power.LamDwn.Clb = 0.01;
Aircraft.Specs.Power.LamDwn.Crs = 0.00;
Aircraft.Specs.Power.LamDwn.Des = 0.00;
Aircraft.Specs.Power.LamDwn.Lnd = 0.00;

% upstream power splits
Aircraft.Specs.Power.LamUps.SLS = 1;
Aircraft.Specs.Power.LamUps.Tko = 1;
Aircraft.Specs.Power.LamUps.Clb = 1;
Aircraft.Specs.Power.LamUps.Crs = 0;
Aircraft.Specs.Power.LamUps.Des = 0;
Aircraft.Specs.Power.LamUps.Lnd = 0;


%% SIZE WITHOUT DETAILED MODEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% battery cells in series and parallel
Aircraft.Specs.Power.Battery.ParCells = NaN;
Aircraft.Specs.Power.Battery.SerCells = NaN;

% initial battery SOC
Aircraft.Specs.Power.Battery.BegSOC = NaN;

% size the aircraft
NoModel = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);


%% SIZE WITH DETAILED MODEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% battery cells in series and parallel
Aircraft.Specs.Power.Battery.ParCells = 100;
Aircraft.Specs.Power.Battery.SerCells =  62;

% initial battery SOC
Aircraft.Specs.Power.Battery.BegSOC = 100;

% size the aircraft
WtModel = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);


%% COMPARE SYSTEM-LEVEL PERFORMANCE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% label the configurations
Mode = ["No Detailed Model"; "New Detailed Model"];

% get the weights
MTOW = [NoModel.Specs.Weight.MTOW; WtModel.Specs.Weight.MTOW];
OEW  = [NoModel.Specs.Weight.OEW ; WtModel.Specs.Weight.OEW ];
Fuel = [NoModel.Specs.Weight.Fuel; WtModel.Specs.Weight.Fuel];
Batt = [NoModel.Specs.Weight.Batt; WtModel.Specs.Weight.Batt];

% get the energy (convert to kWh)
Enrg = [NoModel.Mission.History.SI.Energy.E_ES(end, 2); WtModel.Mission.History.SI.Energy.E_ES(end, 2)] ./ 3.6e+6;

% create a table
OutTable = table(Mode, MTOW, OEW, Fuel, Batt, Enrg);

% name the rows
OutTable.Properties.VariableNames = ["Configuration", "MTOW (kg)", "OEW (kg)", "Fuel (kg)", "Battery (kg)", "Battery Energy (kWh)"];


end