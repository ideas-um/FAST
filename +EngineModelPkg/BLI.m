function [Reduced_Mach] = BLI(Aircraft, OffParams)
% [ReducedV] = Viscosity(Temperature)
% Written by Yi-Chih Arenas Wang
% Updated 09/12/2024
%
% This function returns the velocity reduced considering boundary layer
% ingestion (BLI). It requires the fan diameter to decide boundary layer
% ingestion and average velocity. 
%
% INPUTS:
%
% Aircraft = the specs of aircraft, especially the length of fuselage
%       size: scalar double
%
% Mach_inf = the freestream speed during mission
%       size: scalar double
% 
% Alt      = the altitude of operating condition
%
% OUTPUTS:
%
% ReducedV = the reduced velocity with boundary layer
%       size: scalar double

% get the flight conditions
Alt  = OffParams.FlightCon.Alt; 
Mach = OffParams.FlightCon.Mach;

% compute the true airspeed, temperature, freestream density and viscosity at altitude
[EAS, TAS, Mach, Tinf, Pinf, rhoinf, visc] = MissionSegsPkg.ComputeFltCon(Alt, 0, "Mach", Mach);

% compute Reynolds number of the airflow around the fuselage
%Re_x = rhoinf * TAS * Aircraft.Geometry.LengthSet / EngineModelPkg.SpecHeatPkg.Viscosity(Tinf);
Re_x = rhoinf * TAS * Aircraft.Geometry.LengthSet / visc;

% compute the engine model
Engine = EngineModelPkg.TurbofanNonlinearSizing(AircraftModelingPkg.Susan_Modeling.SUSAN_test, -9.2*10^6 * 0.2); %-5.98*10^6 for 35%

% compute the radius of fan
h = Engine.FanDiam / 2; %Aircraft.Specs.Propulsion.SizedEngine.FanDiam / 2;

% correction factor
f = 1.24;

% compute the boundary layer thickness
delta = f * 0.382 / Re_x^(1/5) * Aircraft.Geometry.LengthSet;

% compute the average airspeed with boundary layer
if h < delta
    Vavg = 7/8 * (h / delta)^(1/7) * TAS;

else
    Vavg = ( (-1/8) * ( 1 / (h / delta) ) + 1 ) * TAS;

end

% compute reudced velocity
gamma = 1.4;                   % ratio of specific heats for air
R = 287;                       % specific heat of air, J/kg/K
A = sqrt(gamma * R * Tinf);    % actual speed of sound
Reduced_Mach = Vavg / A;


end

