function [FAR] = Jet25_119(W_S, T_W, Aircraft)
%
% [FAR] = Jet25_119(W_S, T_W, Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 04 dec 2025
%
% derive the constraints for a balked landing climb with all engines
% operative.
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
CL        = Aircraft.Specs.Aero.CL.Lnd;
CD0       = Aircraft.Specs.Aero.CD0.Lnd;
AR        = Aircraft.Specs.Aero.AR;
e         = Aircraft.Specs.Aero.e.Lnd;
TempInc   = Aircraft.Specs.Performance.TempInc;
WlandFact = Aircraft.Specs.Performance.Wland_MTOW;
ReqType   = Aircraft.Specs.TLAR.ReqType;
Vstall    = Aircraft.Specs.Performance.Vels.Stl;


%% EVALUATE THE CONSTRAINT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% correction for standard temperature increase and landing weight
CorrFactor = TempInc * WlandFact;

% get the constraint type
Type = Aircraft.Settings.ConstraintType;

% find climb gradient
if (Type == 0)
    
    % climb gradient is >= 3.2% regardless of number of engines
    G = 0.032;
    
elseif (Type == 1)
    
    % compute the climb gradient from a sigmoid curve
    G = ConstraintDiagramPkg.Sigmoid(Aircraft, 0, 0, 0, 3.2);
    
else
    
    % throw an error
    error("ERROR - Jet25_119: invalid Type selected, must be 0 or 1.");
    
end

% ratio of flight speed to stall speed is 1.3
ks = 1.3;

% return performance requirement as an inequality constraint
if (ReqType == 0)
    
    % check for turboprop/piston aircraft
    if (strcmpi(aclass, "Turboprop") || strcmpi(aclass, "Piston"))
        
        % get the airspeed and convert to m/s
        V = ks * Vstall;
        
        % convert to T/W
        T_W = 1 ./ (V .* T_W);
        
    end
    
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
    FAR = qinf ./ W_S .* (CD0 + CL ^ 2 / (pi * AR * e)) + G - T_W;
    
else
    
    % throw error
    error("ERROR - Jet25_119: ReqType must be either 0 (Roskam), 1 (Mattingly), or 2 (de Vries et al.).");
    
end

% ----------------------------------------------------------

end