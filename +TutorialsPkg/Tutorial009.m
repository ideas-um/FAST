function [] = Tutorial009()
%
% [] = Tutorial009()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 25 jun 2024
%
% This tutorial is for understanding how a geometry specification file is
% built. A transport-like aircraft is provided as an example, and contains
% the three main components used to generate all geometries: (1)
% liftingSurface; (2) bluntBody; and (3) Engine. All liftingSurface
% components are prescribed within the .m file. Both bluntBody and Engine
% components are prescribed in separate .dat files and are loaded into the
% .m file.
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


%% REVIEW THE TRANSPORT CONFIGURATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the transport configuration file path
TransportFile = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "Transport.m");

% open the transport configuration file
open(TransportFile);

% load the aircraft geometry
Aircraft = VisualizationPkg.GeometrySpecsPkg.Transport();

% view the geometry
VisualizationPkg.vGeometry(Aircraft);


%% PAUSE BEFORE GOING TO NEXT CONFIGURUATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% alert user
fprintf(1, "Program paused to view geometry. Press any key to continue.\n");

% pause before continuing
pause


%% MODIFY THE TRANSPORT'S FUSELAGE LENGTH %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% change the length
Aircraft.Geometry.Fuselage.Length = 200;

% view the geometry again (fuselage lengthens, others remain the same)
VisualizationPkg.vGeometry(Aircraft);


%% PAUSE BEFORE GOING TO NEXT CONFIGURUATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% alert user
fprintf(1, "Program paused to view geometry. Press any key to continue.\n");

% pause before continuing
pause


%% REVIEW THE DELTA WING CONFIGURATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the delta wing configuration file path
DeltaWingFile = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "DeltaCanard.m");

% open the configuration file
open(DeltaWingFile);

% load the aircraft geometry
Aircraft = VisualizationPkg.GeometrySpecsPkg.DeltaCanard();

% view the geometry
VisualizationPkg.vGeometry(Aircraft);


end