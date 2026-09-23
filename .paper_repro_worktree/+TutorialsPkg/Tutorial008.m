function [] = Tutorial008()
%
% [] = Tutorial008()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 25 jun 2024
%
% This tutorial is for viewing an aircraft geometry in standalone mode,
% which is achieved by loading a geometry specification file and calling
% "vGeometry" to view the aircraft's outer mold line.
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

% get the transport configuration file path
TransportFile = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "Transport.m");

% open the transport configuration file
open(TransportFile);


%% VIEW THE GEOMETRY %%
%%%%%%%%%%%%%%%%%%%%%%%

% load the aircraft geometry
Aircraft = VisualizationPkg.GeometrySpecsPkg.Transport();

% view the geometry
VisualizationPkg.vGeometry(Aircraft);


end