function [FAR] = JetAEOClimb(W_S, T_W, Aircraft)
%
% [FAR] = JetAEOClimb(W_S, T_W, Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 19 sep 2025
%
% derive the constraints for takeoff climb with all engines operative.
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
CL      = Aircraft.Specs.Aero.CL.Tko;
CD0     = Aircraft.Specs.Aero.CD0.Tko - 0.025;
AR      = Aircraft.Specs.Aero.AR;
e       = Aircraft.Specs.Aero.e.Tko;
TempInc = Aircraft.Specs.Performance.TempInc;
ReqType = Aircraft.Specs.TLAR.ReqType;
Vstall  = Aircraft.Specs.Performance.Vels.Stl;
G       = Aircraft.Specs.Performance.ExtraGrad;


%% EVALUATE THE CONSTRAINT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% correction for one-engine inoperative
OEI = ConstraintDiagramPkg.OEIMultiplier(Aircraft);

% correction for standard temperature increase and one engine inoperative
CorrFactor = TempInc * OEI;

% required speed ratio is 1.2
ks = 1.2;

% return performance requirement as an inequality constraint
if (ReqType == 0)
    
    % use Roskam's equation
    FAR = CorrFactor * (ks ^ 2 * CD0 / CL + CL / ks ^ 2 / pi / AR / e + G) - T_W;
    
elseif (ReqType == 1)
    
    % convert wing loading to english units
    W_S = W_S .* 9.81 .* UnitConversionPkg.ConvForce(1, "N", "lbf") ./ UnitConversionPkg.ConvLength(1, "m", "ft") ^ 2;
    
    % compute the density at sea level (metric)
    [~, ~, ~, ~, ~, RhoSLS] = MissionSegsPkg.ComputeFltCon(0, 0, "Mach", 0);
    
    % convert density to english units
    RhoSLS = RhoSLS * UnitConversionPkg.ConvMass(1, "kg", "slug") / UnitConversionPkg.ConvLength(1, "m", "ft") ^ 3;
        
    % convert the stall speed to english units
    Vstall = Vstall * UnitConversionPkg.ConvVel(1, "m/s", "ft/s");
    
    % compute the dynamic pressure
    q = 0.5 .* RhoSLS .* (Vstall .* ks) .^ 2;
    
    % check for turboprop/piston aircraft
    if (strcmpi(aclass, "Turboprop") || strcmpi(aclass, "Piston"))
        
        % get the airspeed and convert to m/s
        V = UnitConversionPkg.ConvVel(Vstall * ks, "ft/s", "m/s");
        
        % convert to T/W
        T_W = 1 ./ (V .* T_W);
        
    end
    
    % use Mattingly's equation
    FAR = CorrFactor .* (q .* CD0 ./ W_S + W_S ./ q ./ (pi * AR * e) + G) - T_W;
    
elseif (ReqType == 2)
    
    % only consider the temperature increase
    CorrFactor = CorrFactor / OEI;
    
    % convert wing loading to english units
    W_S = W_S .* 9.81 .* UnitConversionPkg.ConvForce(1, "N", "lbf") ./ UnitConversionPkg.ConvLength(1, "m", "ft") ^ 2;
    
    % compute the density at sea level (metric)
    [~, ~, ~, ~, ~, RhoSLS] = MissionSegsPkg.ComputeFltCon(0, 0, "Mach", 0);
    
    % convert density to english units
    RhoSLS = RhoSLS * UnitConversionPkg.ConvMass(1, "kg", "slug") / UnitConversionPkg.ConvLength(1, "m", "ft") ^ 3;
    
    % scale the lift coefficient based on the stall speed
    CL = CL / ks ^ 2;
    
    % use the lift coefficient to compute the dynamic pressure
    qinf = W_S ./ CL;
    
    % compute the flight speed
    Vinf = sqrt(2 .* qinf ./ RhoSLS);
    
    % check for turboprop/piston aircraft
    if (strcmpi(aclass, "Turboprop") || strcmpi(aclass, "Piston"))
        
        % get the airspeed and convert to m/s
        V = UnitConversionPkg.ConvVel(Vinf, "ft/s", "m/s");
        
        % convert to T/W
        T_W = 1 ./ (V .* T_W);
        
    end
    
    % compute the required thrust-weight ratio
    FAR = CorrFactor .* (qinf ./ W_S .* (CD0 + CL ^ 2 / (pi * AR * e)) + G) - T_W;
    
else
    
    % throw error
    error("ERROR - JetAEOClimb: ReqType must be either 0 (Roskam), 1 (Mattingly), or 2 (de Vries et al.).");
    
end

% ----------------------------------------------------------

end