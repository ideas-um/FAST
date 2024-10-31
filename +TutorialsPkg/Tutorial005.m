function [] = Tutorial005()
%
% [] = Tutorial005()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 jun 2024
%
% This is a tutorial for reviewing a parametric mission profile. The file
% reviewed in the tutorial is ParametricRegional.m, and will be opened
% here.
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
FilePath = fullfile("+MissionProfilesPkg", "ParametricRegional.m");

% retrieve the file
open(FilePath);


end