function [] = Tutorial004()
%
% [] = Tutorial004()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 jun 2024
%
% This is a tutorial for reviewing a hard-coded mission profile. The file
% reviewed in the tutorial is RegionalJetMission02.m, and will be opened
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
FilePath = fullfile("+MissionProfilesPkg", "RegionalJetMission02.m");

% retrieve the file
open(FilePath);


end