function [MyHistoryTable] = Tutorial012()
%
% [MyHistoryTable] = Tutorial012()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 jun 2024
%
% This is a tutorial for loading a sized aircraft and viewing its mission
% history in a table and also using plots.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     MyHistoryTable - table with the mission history
%                      size/type/units: 1-by-1 / table / []
%


%% SETUP %%
%%%%%%%%%%%

% initial cleanup
clc, close all


%% GET THE AIRCRAFT %%
%%%%%%%%%%%%%%%%%%%%%%

% get the file path
FilePath = fullfile("+TutorialsPkg", "Tutorial012-SizedAircraft.mat");

% load the aircraft
LoadedAircraft = load(FilePath);

% extract out the aircraft
ERJ175LR = LoadedAircraft.ERJ175LR;


%% VIEW THE MISSION HISTORY %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% view the plots
PlotPkg.PlotMission(ERJ175LR);

% view as a table
MyHistoryTable = MissionHistTable(ERJ175LR);


end