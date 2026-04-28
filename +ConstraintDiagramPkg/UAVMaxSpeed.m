function [FAR] = UAVMaxSpeed(W_S, T_W, Aircraft)
%
% [FAR] = UAVMaxSpeed(W_S, T_W, Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 28 apr 2026
%
% ensure that the UAV does not exceed the maximum speed allowed.
%
% INPUTS:
%     W_S      - grid of wing loading values.
%                size/type/units: m-by-p / double / [kg/m^2]
%
%     T_W      - grid of thrust-weight ratios.
%                size/type/units: m-by-p / double / [N/N]
%
%     Aircraft - information about the configuration being analyzed
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     FAR      - inequality constraints pertaining to the performance
%                requirement.
%                size/type/units: m-by-p / double / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% retrieve parameters from the aircraft structure
CL   = Aircraft.Specs.Aero.CL.Crs;
Alt  = Aircraft.Specs.Performance.Alts.Crs;
VMax = Aircraft.Specs.Performance.VMax;


%% EVALUATE THE CONSTRAINT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% convert wing loading from kg/m^2 to N/m^2
W_S = W_S .* 9.81;

% compute the density at the cruise altitude (kg/m^3)
[~, ~, ~, ~, ~, RhoSLS] = MissionSegsPkg.ComputeFltCon(Alt, 0, "Mach", 0);

% compute the constraint
FAR = 2 .* W_S ./ (RhoSLS .* CL) - VMax ^ 2;

% ----------------------------------------------------------

end