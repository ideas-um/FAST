function [] = TestInteriorPoint()
%
% [] = TestInteriorPoint()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 mar 2024
%
% Test the interior point function developed in this package.
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


%% PLOT CONTOURS %%
%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% define the domain          %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% number of points in the linspace
npnt = 500;

% bound the domain
x1 = linspace(-20, +20, npnt);
x2 = linspace(-20, +20, npnt);

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
        F0(ipnt, jpnt) = OptimizationPkg.TestObj([X1(ipnt, jpnt); X2(ipnt, jpnt)]);
        g              = OptimizationPkg.TestCon([X1(ipnt, jpnt); X2(ipnt, jpnt)]);
        G1(ipnt, jpnt) = g(1);
        G2(ipnt, jpnt) = g(2);
        G3(ipnt, jpnt) = g(3);
    end
end

% create a figure
figure
hold on
set(gcf, 'Position', get(0, 'Screensize'));

% plot the constraints
contourf(X1, X2, G1, [0, Inf]);
contourf(X1, X2, G2, [0, Inf]);
contourf(X1, X2, G3, [0, Inf]);

% overlay the objective
contour( X1, X2, F0, [linspace(-20, -2.8284, 10), linspace(-2, 10, 10)]);
colorbar


%% OPTIMIZE %%
%%%%%%%%%%%%%%

% initial guess
x0 = [-15; +17];

% optimize
[xopt, fopt, xhist, fhist, optim, feas] = OptimizationPkg.InteriorPoint(@OptimizationPkg.TestObj, x0, @OptimizationPkg.TestCon)

% plot the history
plot(xhist(1, :), xhist(2, :), '-o', 'LineWidth', 2, 'Color', 'black');

% format plot
title('Optimization with Interior Point Method');
xlabel('X1');
ylabel('X2');

% ----------------------------------------------------------

end