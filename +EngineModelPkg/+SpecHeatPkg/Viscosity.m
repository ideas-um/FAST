function [mu] = Viscosity(Temperature)
% [mu] = Viscosity(Temperature)
% Written by Yi-Chih Arenas Wang
% Updated 09/12/2024
%
% This function returns the viscosity of air under the temperature
% at different altitudes. The equations are based on Sutherland's Law.
%
%
% INPUTS:
%
% Temperature = the air temperature at different altitude
%       size: scalar double
%
%
% OUTPUTS:
%
% mu = the air viscosity at different altitude
%       size: scalar double

% The viscosity of air at sea level standard condition, unit: N.s/m^2
mu0 = 1.716 * 10^-5;

% The temperature of air at sea level standard condition, unit: K
T0  = 273;

% An effective temperature called the Sutherland constant, unit: K
Smu = 111;

% calculate the viscosity of air at different temperature based on
% Sutherland's Law
mu = mu0 * (Temperature / T0)^(3/2) * (T0 + Smu) / (Temperature + Smu);

end

