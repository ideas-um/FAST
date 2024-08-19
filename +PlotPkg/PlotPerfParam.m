function [] = PlotPerfParam(x, y, lx, ly, name)
%
% [] = PlotPerfParam(x, y, lx, ly, name)
% written by Paul Mokotoff, prmoko@umich.edu
% updated 19 aug 2024
%
% Plot a given parameter from the mission analysis.
%
% INPUTS:
%     x    - independent variable.
%            size/type/units: 1-by-1 / double / []
%
%     y    -   dependent variable.
%            size/type/units: 1-by-1 / double / []
%
%     lx   - x-axis label.
%            size/type/units: 1-by-1 / string / []
%
%     ly   - y-axis label.
%            size/type/units: 1-by-1 / string / []
%
%     name - name to title the plot.
%            size/type/units: 1-by-1 / string / []
%
% OUTPUTS:
%     none
%

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% plotting                   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% plot performance parameters
plot(x, y, '-', 'LineWidth', 2);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% format plot                %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set title, if one is given
if (nargin >= 5)
    title(sprintf("%s Profile", name));
end

% set axis labels
xlabel(lx);
ylabel(ly);

% turn on gridlines
grid on

% larger font size
set(gca, 'FontSize', 14);

% ----------------------------------------------------------

end