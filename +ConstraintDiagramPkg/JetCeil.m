function [FAR] = JetCeil(W_S, T_W, Aircraft)
%
% [FAR] = JetCeil(W_S, T_W, Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 16 sep 2025
%
% derive the constraints for service ceiling.
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
CD0     = Aircraft.Specs.Aero.CD0.Crs;
AR      = Aircraft.Specs.Aero.AR;
e       = Aircraft.Specs.Aero.e.Crs;
zserv   = Aircraft.Specs.Performance.Alts.Srv; % keep in SI units for ComputeFltCon
ReqType = Aircraft.Specs.TLAR.ReqType;
CrsMach = Aircraft.Specs.Performance.Vels.Crs;


%% EVALUATE THE CONSTRAINT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get densities at sea-level and service ceiling
[~, ~   , ~, ~, ~, RhoSLS] = MissionSegsPkg.ComputeFltCon(0    , 0, "Mach", CrsMach);
[~, Vcrs, ~, ~, ~, RhoSrv] = MissionSegsPkg.ComputeFltCon(zserv, 0, "Mach", CrsMach);

% compute density ratio of service ceiling to sea-level
RhoRatio = RhoSrv / RhoSLS;

% use a small gradient
G = 0.001;

% return performance requirement as an inequality constraint
if (ReqType == 0)
    
    % use the metabook's equation
    FAR = (2 * sqrt(CD0 / pi / e / AR) + G) / RhoRatio ^ 0.6 - T_W;
    
elseif (ReqType == 1)

    % convert wing loading to english units
    W_S = W_S .* 9.81 .* UnitConversionPkg.ConvForce(1, "N", "lbf") ./ UnitConversionPkg.ConvLength(1, "m", "ft") ^ 2;
        
    % convert the density to english units
    RhoSLS = RhoSLS * UnitConversionPkg.ConvMass(1, "kg", "slug") / UnitConversionPkg.ConvLength(1, "m", "ft") ^ 3;
    
    % convert the cruise speed to english units
    Vcrs = Vcrs * UnitConversionPkg.ConvVel(1, "m/s", "ft/s");
    
    % compute the dynamic pressure
    q = 0.5 .* RhoSLS .* Vcrs .^ 2;
    
    % check for turboprop/piston aircraft
    if (strcmpi(aclass, "Turboprop") || strcmpi(aclass, "Piston"))
        
        % get the airspeed and convert to m/s
        V = UnitConversionPkg.ConvVel(Vcrs, "ft/s", "m/s");
        
        % convert to T/W
        T_W = 1 ./ (V .* T_W);
        
    end
    
    % use Mattingly's equation for service ceiling
    FAR = 1 ./ RhoRatio ^ 0.6 .* (q .* CD0 ./ W_S + W_S ./ q ./ (pi * AR * e) + G) - T_W;
    
else
    
    % throw error
    error("ERROR - JetCeil: ReqType must be either 0 (Roskam) or 1 (Mattingly).");
    
end

% ----------------------------------------------------------

end