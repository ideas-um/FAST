function [g] = Gravity(Alt)
%
% [g] = Gravity(Alt)
% written by Janki Patel
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 mar 2024
%
% Calculate the acceleration due to gravity at a given altitude.
%
% INPUTS:
%     Alt - current altitude.
%           size/type/units: m-by-n / double / [m]
%
% OUTPUTS:
%     g   - acceleration due to gravity.
%           size/type/units: m-by-n / double / [m / s^2]
%

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% constants                  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% gravity at sea-level
GravSL = 9.80665;

% radius of earth
EarthRad = 6.371009e+06;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% compute gravitational      %
% acceleration               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute gravitational acceleration
g = GravSL .* (EarthRad ./ (EarthRad + Alt)) .^ 2; % m / s^2

% ----------------------------------------------------------

end 
