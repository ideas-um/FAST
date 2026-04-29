function [FAR] = UAVCrs(W_S, T_W, Aircraft)
%
% [FAR] = UAVCrs(W_S, T_W, Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 28 apr 2026
%
% derive the constraints for cruise performance.
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

% get the L/D
L_D = Aircraft.Specs.Aero.L_D.Crs;

% get the cruise speed
V = Aircraft.Specs.Performance.Vels.Crs;

% convert from P/W to T/W
T_W = 1 ./ (V .* T_W);

% assume that the UAS system is operating a sea-level, no power lapsing
FAR = 1 ./ L_D - T_W;


end