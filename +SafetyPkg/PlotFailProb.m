function [] = PlotFailProb()
%
% [] = PlotFailProb()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 apr 2025
%
% given some electrical components, predict their probability of failing.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     none
%

% get the components
Batt = SafetyPkg.ComponentDatabase("Battery"      );
EG   = SafetyPkg.ComponentDatabase("ACGenerator"  );
EM   = SafetyPkg.ComponentDatabase("ElectricMotor");

% vary the exposure time
dt = 0 : 1.0e+02 : 1.0e+04;

% get the failure rates
FR = [Batt.FailRate; EG.FailRate; EM.FailRate];

% compute the probabilities of failure
Pf = SafetyPkg.FailureModel(FR, dt);

% plot the results
plot(dt, Pf', "-", "LineWidth", 2);

% add axis labels
xlabel("Exposure Time (hr)");
ylabel("Probability of Failure");

% add a grid
grid on

% add a legend
legend("Battery", "Electric Generator", "Electric Motor", "Location", "northwest");

% change the font size
set(gca, "FontSize", 14);

end