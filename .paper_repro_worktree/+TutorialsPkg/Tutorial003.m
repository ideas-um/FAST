function [] = Tutorial003()
%
% [] = Tutorial003()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 jun 2024
%
% This is a tutorial for reviewing an aircraft specification file. The file
% reviewed in the tutorial is Example.m, and will be opened here.
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


%% OPEN THE EXAMPLE %%
%%%%%%%%%%%%%%%%%%%%%%

% get the file path
FilePath = fullfile("+AircraftSpecsPkg", "Example.m");

% retrieve the file
open(FilePath);


end