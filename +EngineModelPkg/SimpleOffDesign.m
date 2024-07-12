function [OffOutputs] = SimpleOffDesign(OnDesignEngine, OffParams, ElectricLoad, Segment)
%
% [OffOutputs] = SimpleOffDesign(OnDesignEngine, OffParams, ElectricLoad)
% written by Paul Mokotoff, prmoko@umich.edu
% thanks to Swapnil Jagtap for the equation
% last updated: 12 jul 2024
%
% Simple off-design engine model using Boeing's fuel flow calculations
% calibrated for flight conditions requiring less than 100% thrust.
%
% INPUTS:
%     OnDesignEngine - the sized engine onboard the aircraft.
%                      size/type/units: 1-by-1 / struct / []
%
%     OffParams      - structure detailing the flight conditions.
%                      size/type/units: 1-by-1 / struct / []
%
%     ElectricLoad   - the contribution from an electric motor.
%                      size/type/units: 1-by-1 / double / [W]
%
% OUTPUTS:
%     OffOutputs     - structure detailing the fuel flow and TSFC while the
%                      engine is operating.
%                      size/type/units: 1-by-1 / struct / []
%


%% FLIGHT CONDITION CALCULATIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the flight conditions
Alt  = OffParams.FlightCon.Alt ;
Mach = OffParams.FlightCon.Mach;

% compute the temperature and pressure at altitude and sea-level
[~,   ~, ~, T0, P0] = MissionSegsPkg.ComputeFltCon(  0, 0, "Mach",    0);
[~, TAS, ~, T1, P1] = MissionSegsPkg.ComputeFltCon(Alt, 0, "Mach", Mach);

% compute the temperature and pressure ratios
Theta = T1 / T0;
Delta = P1 / P0;

% get the thrust required
ThrustReq = OffParams.Thrust;

% subtract the thrust provided by the electric motor
ThrustReq = ThrustReq - ElectricLoad / TAS;


%% FUEL FLOW CALCULATIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the fuel flow of the designed engine at SLS
MDotSLS = OnDesignEngine.Fuel.MDot;

% compute the fuel flow at full throttle
MDotFull = MDotSLS / (Theta ^ 3.8 / Delta * exp(0.2 * Mach ^ 2));

% check for the cruise segment
if (strcmpi(Segment, "Cruise") == 1)
    
    % get the SLS thrust produced by the engine
    ThrustSLS = OnDesignEngine.Specs.DesignThrust;
    
    % get the calibration factors
    c1 = OnDesignEngine.Cal.c1;
    c2 = OnDesignEngine.Cal.c2;
    
    % calibrate for a partially open throttle
    MDotAct = MDotFull * c1  * ThrustReq / (ThrustSLS * c2);
    
else
    
    % use the fuel flow rate at full throttle
    MDotAct = MDotFull;
    
end

% compute the TSFC
TSFC = MDotAct / ThrustReq;


%% FORMULATE OUTPUT STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember the fuel flow
OffOutputs.Fuel = MDotAct;

% remember the thrust output
OffOutputs.Thrust = ThrustReq;

% remember the TSFCs (in both units)
OffOutputs.TSFC          =                            TSFC              ;
OffOutputs.TSFC_Imperial = UnitConversionPkg.ConvTSFC(TSFC, "SI", "Imp");

% ----------------------------------------------------------

end