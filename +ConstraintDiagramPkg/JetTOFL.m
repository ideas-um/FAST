function [FAR] = JetTOFL(W_S, T_W, Aircraft)
%
% [FAR] = JetTOFL(W_S, T_W, Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 04 dec 2025
%
% derive the constraints for takeoff field length.
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

% get the aircraft class
aclass = Aircraft.Specs.TLAR.Class;

% retrieve parameters from the aircraft structure
CL          = Aircraft.Specs.Aero.CL.Tko;
BalFieldLen = Aircraft.Specs.Performance.TOFL;
Vstall      = Aircraft.Specs.Performance.Vels.Stl;

% convert the balanced field length
BalFieldLen = BalFieldLen * UnitConversionPkg.ConvLength(1, "m", "ft");

% assume a 95% density ratio for a "hot day"
RhoRwy = 0.95;


%% EVALUATE THE CONSTRAINT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the takeoff parameter, based on FAR 25
Top25 = BalFieldLen / 37.5;

% convert wing loading to english units
W_S = W_S .* 9.81 .* UnitConversionPkg.ConvForce(1, "N", "lbf") ./ UnitConversionPkg.ConvLength(1, "m", "ft") ^ 2;

% check for turboprop/piston aircraft
if (strcmpi(aclass, "Turboprop") || strcmpi(aclass, "Piston"))
        
    % convert to T/W
    T_W = 1 ./ (1.2 * Vstall .* T_W);
    
end

% Roskam and Mattingly's equations match
FAR = W_S ./ (RhoRwy * CL * Top25) - T_W;

% ----------------------------------------------------------

end