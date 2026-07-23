function [] = TestWindmillingDrag()
%
% [] = TestWindmillingDrag()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 10 jun 2025
%
% test the .mat file and griddedInterpolant's created to model the drag
% coefficient from a windmilling engine.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     none
%

% initial cleanup
clc, close all


%% LOAD INTERPOLANTS %%
%%%%%%%%%%%%%%%%%%%%%%%

% load the interpolants
Interpolants = load(fullfile("+AerodynamicsPkg", "WindmillingDrag.mat"));

% get each interpolant
TheoryCD = Interpolants.InterpTheoryCD;
DeltaCD  = Interpolants.InterpDeltaCD;

% specific thrust for both tests
SpecThrust = (150 : 5 : 850)';


%% THEORETICAL CD %%
%%%%%%%%%%%%%%%%%%%%

% get the theoretical CD
CD = TheoryCD(SpecThrust);

% create a figure
figure;

% plot the results
plot(SpecThrust, CD, "-", "LineWidth", 2, "Color", "black");

% format the plot
xlabel("Specific Thrust (Ns/kg)");
ylabel("Theoretical Drag Coefficient");
grid on
set(gca, "FontSize", 18);
axis([200, 800, 0, 0.4]);


%% DELTA CD %%
%%%%%%%%%%%%%%

% get mach numbers
Mach = [0.2; 0.4; 0.6; 0.8; 1.0];

% make pairs of specific thrusts and mach numbers
[SpecGrid, MachGrid] = ndgrid(SpecThrust, Mach);

% evaluate the interpolant
DeltaGrid = DeltaCD(SpecGrid, MachGrid);

% create a figure
figure;
hold on;

% plot the results
plot(SpecThrust, DeltaGrid(:, 1), "-", "LineWidth", 2);
plot(SpecThrust, DeltaGrid(:, 2), "-", "LineWidth", 2);
plot(SpecThrust, DeltaGrid(:, 3), "-", "LineWidth", 2);
plot(SpecThrust, DeltaGrid(:, 4), "-", "LineWidth", 2);
plot(SpecThrust, DeltaGrid(:, 5), "-", "LineWidth", 2);

% format the plot
xlabel("Specific Thrust (Ns/kg)");
ylabel("Delta CD");
grid on
legend("Mach 0.2", "Mach 0.4", "Mach 0.6", "Mach 0.8", "Mach 1.0", "Location", "northeast");
set(gca, "FontSize", 18);
axis([200, 800, -0.1, +0.4]);

% ----------------------------------------------------------

end