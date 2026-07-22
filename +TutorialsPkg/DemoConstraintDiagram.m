function [] = DemoConstraintDiagram()
%
% [] = DemoConstraintDiagram()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 16 feb 2026
%
% generate constraint diagrams under multiple requirement frameworks and
% propulsion system failures.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     none
%

% initial cleanup
clc, close all


%% SIZE A BOEING 777 %%
%%%%%%%%%%%%%%%%%%%%%%%

% open the file for running
open (fullfile("+ConstraintDiagramPkg", "+ConstraintSpecsPkg", "Boeing777.m"));

% size for 2-, 3-, and 4-engines to showcase capabilities


%% SIZE AN ELYSIAN E9X %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% open the file for running
open (fullfile("+ConstraintDiagramPkg", "+ConstraintSpecsPkg", "ElysianE9X.m"));

% size using Mattingly's and deVries' requirements under different
% propulsion system failure severities (corresponding to Ps losses of
% 0.1624, 0.6000, and 0.9711)

end