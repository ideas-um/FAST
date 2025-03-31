function [SizedAircraft] = Tutorial002()
%
% [] = Tutorial002()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 jun 2024
%
% This is a tutorial for sizing an aircraft in FAST. The Example aircraft
% specification file is run with the ERJ mission profile.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     SizedAircraft - the converged aircraft design.
%                     size/type/units: 1-by-1 / struct / []
%


%% SETUP %%
%%%%%%%%%%%

% initial cleanup
clc, close all


%% AIRCRAFT SIZING %%
%%%%%%%%%%%%%%%%%%%%%

% size the aircraft
SizedAircraft = Main(AircraftSpecsPkg.Example, @MissionProfilesPkg.ParametricRegional);


end