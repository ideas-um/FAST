function [] = PlotArchitecture(Architecture)
%
% [] = PlotArchitecture(Architecture)
% written by Nawa Khailany, nawakhai@umich.edu
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 22 mar 2024
%
% Plot a user-prescribed propulsion architecture.
%
% INPUTS:
%     Architecture - data structure with the propulsion architecture to be
%                    plotted.
%                    size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     none
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% get the thrust/power/energy sources and their connections
IdxNames = fieldnames(Architecture.Index     );
CNames   = fieldnames(Architecture.Connection);

% get the number of components and connections
IdxNums  = length(IdxNames);
CNums    = length(  CNames);


%% PLOT THE PROPULSION ARCHITECTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% allow for multiple plots (new figure created previously)
hold on

% loop through each source
for i = 1:IdxNums

    % plot a rectangle
    Architecture.Index.(IdxNames{i}).rect;

    % place label inside the rectangle
    Architecture.Index.(IdxNames{i}).text;

end

% loop through the connections
for i = 1:CNums

    % plot the connections
    plot([Architecture.Connection.(CNames{i})(1,1);Architecture.Connection.(CNames{i})(1,2);Architecture.Connection.(CNames{i})(1,3);Architecture.Connection.(CNames{i})(1,4)], ...
         [Architecture.Connection.(CNames{i})(2,1);Architecture.Connection.(CNames{i})(2,2);Architecture.Connection.(CNames{i})(2,3);Architecture.Connection.(CNames{i})(2,4)]);

end

% set background color to white
set(gcf,'color',[1 1 1]);

% format the axes
yticks([])
xticks([])
ax = gca;
ax.XAxis.Visible = 'off';
ax.YAxis.Visible = 'off';

% ----------------------------------------------------------

end