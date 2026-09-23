function [] = NewTestInteriorPoint()
%
% [] = NewTestInteriorPoint()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 mar 2024
%
% Test the interior point function.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     none
%


%% PLOT CONTOURS %%
%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% define the domain          %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initial cleanup
clc, close all

% number of points in the linspace
npnt = 500;

% bound the domain
x1 = linspace(-10, +20, npnt);
x2 = linspace(-10, +20, npnt);

% make a grid
[X1, X2] = meshgrid(x1, x2);

% memory for the objective and constraints
F0 = zeros(npnt, npnt);
G1 = zeros(npnt, npnt);
G2 = zeros(npnt, npnt);
G3 = zeros(npnt, npnt);

% evaluate the objective and constraints
for ipnt = 1:npnt
    for jpnt = 1:npnt
        F0(ipnt, jpnt) = OptimizationPkg.NewTestObj([X1(ipnt, jpnt); X2(ipnt, jpnt)]);
        g              = OptimizationPkg.NewTestCon([X1(ipnt, jpnt); X2(ipnt, jpnt)]);
        G1(ipnt, jpnt) = g(1);
        G2(ipnt, jpnt) = g(2);
    end
end

% create a figure
figure
hold on
set(gcf, 'Position', get(0, 'Screensize'));

% plot the constraints
contourf(X1, X2, G1, [0, Inf]);
contourf(X1, X2, G2, [0, Inf]);

% overlay the objective
contour( X1, X2, F0, 50);
colorbar


%% OPTIMIZE %%
%%%%%%%%%%%%%%

% initial guess
x0 = [-10; +15];

% optimize
[xopt, fopt, xhist, fhist, optim, feas] = OptimizationPkg.InteriorPoint(@OptimizationPkg.NewTestObj, x0, @OptimizationPkg.NewTestCon)

% plot the history
plot(xhist(1, :), xhist(2, :), '-o', 'LineWidth', 2, 'Color', 'black');

% format plot
title('Optimization with Interior Point Method');
xlabel('X1');
ylabel('X2');

% ----------------------------------------------------------

end