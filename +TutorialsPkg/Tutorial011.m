function [] = Tutorial011(iarch)
%
% [] = Tutorial011(iarch)
% written by Paul Mokotoff, prmoko@umich.edu
% adapted from Nawa Khailany
% last updated: 25 jun 2024
%
% This tutorial is for visualizing propulsion architectures. Before
% creating your own propulsion architectures, the user is encouraged to
% read the following reference to understand how the matrices for each
% propulsion architecture are formulated:
%
%     Cinar, G., Garcia, E., & Mavris, D. N. (2020). A framework for
%     electrified propulsion architecture and operation analysis. Aircraft
%     Engineering and Aerospace Technology, 92(5), 675-684.
%
% INPUTS:
%     iarch - selected propulsion architecture option.
%             size/type/units: 1-by-1 / int / []
%
% OUTPUTS:
%     none
%


%% SETUP %%
%%%%%%%%%%%

% initial cleanup
clc, close all


%% EXAMPLE PROPULSION ARCHITECTURES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the architecture from the input argument
if     (iarch == 0)
    
    % gas-turbine engines only
    B_PSES = [1; 1; 1; 1];
    B_PSPS = eye(4);
    B_TSPS = eye(4);
    
elseif (iarch == 1)
    
    % independent parallel hybrid
    B_PSES = [1, 0; 0, 1; 0, 1; 0, 1];
    B_PSPS = eye(4);
    B_TSPS = eye(4);

elseif (iarch == 2)

    % new LM100J architecture
    B_PSES = [1 0 0; 0 1 0; 0 1 1; 0 0 1];
    B_PSPS = eye(4);
    B_TSPS = eye(4);

elseif (iarch == 3)
    
    % conventional, multiple fuel tanks
    B_PSES = [1 1 0; 0 1 1];
    B_PSPS = [1 0; 0 1];
    B_TSPS = [1 0; 0 1];
    
else
    
    % throw an error
    error("ERROR - Tutorial011: invalid propulsion architecture index selected.");

end


%% PLOT THE PROPULSION ARCHITECTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create a figure
figure;

% get the propulsion architecture in a graphical form
PropArch = VisualizationPkg.PropulsionArchitecture(B_PSES, B_PSPS, B_TSPS);

% plot the architecture
VisualizationPkg.PlotArchitecture(PropArch);

% enlarge the figure
set(gcf, 'Position', get(0, 'Screensize'));


end