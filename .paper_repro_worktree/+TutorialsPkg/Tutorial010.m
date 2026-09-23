function [] = Tutorial010()
%
% [] = Tutorial010()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 25 jun 2024
%
% This tutorial is for integrating the aircraft visualizations previously
% reviewed into FAST's sizing tool. An example with an A320neo is
% presented.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     none
%


%% SETUP %%
%%%%%%%%%%%

% initial cleanup
clc, close all


%% SIZE THE AIRCRAFT CONFIGURATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load the configuration
Aircraft = AircraftSpecsPkg.A320Neo;

% set the number of passengers to carry (modify this value to see the sized
% aircraft geometry change)
Aircraft.Specs.TLAR.MaxPax = 160;

% flag to visualize the aircraft while sizing:
%     1 = visualizations included
%     0 = visualizations ignored
Aircraft.Settings.VisualizeAircraft = 0;

% check if the aircraft should be visualized
if (Aircraft.Settings.VisualizeAircraft == 1)
    
    % connect a geometry to the aircraft
    Aircraft.Geometry.Preset = VisualizationPkg.GeometrySpecsPkg.Transport;    
    
    % specify a fuselage length
    Aircraft.Geometry.LengthSet = convlength(180, "ft", "m");
    
end

% run the sizing tool
Main(Aircraft, @MissionProfilesPkg.A320);


end