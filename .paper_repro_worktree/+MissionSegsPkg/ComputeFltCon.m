function [EAS, TAS, Mach, Tinf, Pinf, rhoinf, visc] = ComputeFltCon(Alt, dISA, VelType, Vel)
%
% [EAS, TAS, Mach, Tinf, Pinf, rhoinf, visc] = ComputeFltCon(Alt, dISA, VelType, Vel)
% written by Gokcin Cinar, taken from E-PASS
% documentation modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 mar 2024
%
% Compute the flight conditions at a given altitude, standard atmospheric
% temperature deviation, and flight speed.
%
% INPUTS:
%     Alt     - altitude on the flight path.
%               size/type/units: m-by-n / double / [m]
%
%     dISA    - deviation from the International Standard Atmosphere's
%               temperature.
%               size/type/units: 1-by-1 or m-by-n / double / [K]
%
%     VelType - the velocity type, either:
%                   a) "TAS"  - true airspeed
%                   b) "EAS"  - equivalent airspeed
%                   c) "Mach" - mach number
%               size/type/units: 1-by-1 / string / []
%
%     Vel     - the velocity along the flight path (as the type specified
%               in the previous argument).
%               size/type/units: m-by-n / double / [m/s] (EAS/TAS) or []
%               (Mach)
%
% OUTPUTS:
%     EAS     - equivalent airspeed at the given flight conditions.
%               size/type/units: m-by-n / double / [m/s]
%
%     TAS     - true airspedd at the given flight conditions.
%               size/type/units: m-by-n / double / [m/s]
%
%     Mach    - mach number at the given flight conditions.
%               size/type/units: m-by-n / double / []
%
%     Tinf    - freestream temperature at the given flight conditions.
%               size/type/units: m-by-n / double / []
%
%     Pinf    - freestream pressure at the given flight conditions.
%               size/type/units: m-by-n / double / [Pa]
%
%     rhoinf  - freestream density at the given flight conditions.
%               size/type/units: m-by-n / double / [kg / m^3]
%
%     visc    - air viscosity at the given flight conditions.
%               size/type/units: m-by-n / double / [N * s / m^2]
%


%% COMPUTE THE ATMOSPHERIC CONDITIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gamma = 1.4;    % ratio of specific heats for air
R = 287;        % specific heat of air, J/kg/K

% get standard sea-level properties
[~, ~, rhoSLStd] = MissionSegsPkg.StdAtm(0);

% get standard atmosphere properties
[TISA, PISA, ~] = MissionSegsPkg.StdAtm(Alt);

TISA = reshape(TISA,size(Alt)); % For compatibility with R2019b and older versions
PISA = reshape(PISA,size(Alt)); % For compatibility with R2019b and older versions

% actual temperature
Tinf = TISA + dISA;

% actual pressure
Pinf = PISA;

% actual density
rhoinf = Pinf./(R*Tinf);


%% COMPUTE THE AIRSPEEDS AND MACH NUMBER %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% actual speed of sound
A = sqrt(gamma * R * Tinf);

% Air viscosity (Ns/m^2)
% 3rd order polynomial fit as function of altitude
visc = -1.51*10^-19.*Alt.^3 + 1.64*10^-14.*Alt.^2 - 4.67*10^-10.*Alt + 1.81*10^-5; 

% if Mach number has been provided as input
if strcmpi(VelType,'Mach')
    
    Mach = Vel;
    
    % compute true airspeed (TAS)
    TAS = Vel.*A;
    
    % compute equivalent airspeed (EAS)
    EAS = TAS.*sqrt(rhoinf./rhoSLStd);
    
end

% if TAS has been provided as input
if strcmpi(VelType,'TAS')
    
    TAS = Vel;
    
    % compute equivalent airspeed (EAS)
    EAS  = TAS.*sqrt(rhoinf./rhoSLStd);
    
    % compute Mach number
    Mach = TAS./A;
    
end

% if EAS has been provided as input
if strcmpi(VelType,'EAS')
    
    EAS = Vel;
    
    % compute true airspeed (TAS)
    TAS = EAS.*sqrt(rhoSLStd./rhoinf);
    
    % compute Mach number
    Mach = TAS./A;
    
end

% ----------------------------------------------------------

end