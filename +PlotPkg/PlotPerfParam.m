function [] = PlotPerfParam(x, y, inst, lx, ly, name)
%
% [] = PlotPerfParam(x, y, inst, lx, ly, name)
% written by Paul Mokotoff, prmoko@umich.edu
% updated 29 aug 2024
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
%     inst - flag to indicate whether the dependent variable is an
%            instantaneous quantity (1) or a state variable (0)
%            size/type/units: 1-by-1 / int / []
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
% data formatting            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if the variable is instantaneous
if (inst == 1)
    
    % create a "step-like" function by reshaping the inputs arrays
    %
    %             |------------
    %             |
    % ------------|
    %
    
    % get the matrix size
    [nrow, ncol] = size(x);
    
    % allocate memory
    xnew = zeros(2*(nrow-1)+1, ncol);
    ynew = zeros(2*(nrow-1)+1, ncol);
    
    % loop through each column
    for icol = 1:ncol
        
        % transform data into a "step-like" function
        xnew(:, icol) = [reshape([x(1:end-1, icol)'; x(2:end  , icol)'], [], 1); x(end, icol)];
        ynew(:, icol) = [reshape([y(1:end-1, icol)'; y(1:end-1, icol)'], [], 1); y(end, icol)];
        
    end
    
    % remember the new result
    x = xnew;
    y = ynew;
    
end

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

% set title
title(sprintf("%s Profile", name));

% set axis labels
xlabel(lx);
ylabel(ly);

% turn on gridlines
grid on

% larger font size
set(gca, 'FontSize', 12, 'FontName', 'Times');

% ----------------------------------------------------------

end