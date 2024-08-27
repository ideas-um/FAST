function [OffOutputs] = SimpleOffDesign(Aircraft, OffParams, ElectricLoad)
%
% [OffOutputs] = SimpleOffDesign(OnDesignEngine, OffParams, ElectricLoad)
% written by Paul Mokotoff, prmoko@umich.edu and Yi-Chih Wang,
% ycwangd@umich.edu
% thanks to Swapnil Jagtap for the equation
% last updated: 27 aug 2024
%
% Simple off-design engine model using a fuel flow equation from the BADA
% Database.
%
% INPUTS:
%     Aircraft     - information about the aircraft being flown.
%                    size/type/units: 1-by-1 / struct / []
%
%     OffParams    - structure detailing the flight conditions.
%                    size/type/units: 1-by-1 / struct / []
%
%     ElectricLoad - the contribution from an electric motor.
%                    size/type/units: 1-by-1 / double / [W]
%
% OUTPUTS:
%     OffOutputs   - structure detailing the fuel flow and TSFC while the
%                    engine is operating.
%                    size/type/units: 1-by-1 / struct / []
%


%% FLIGHT CONDITION CALCULATIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the flight conditions
Alt  = OffParams.FlightCon.Alt; 
Mach = OffParams.FlightCon.Mach;

% compute the true airspeed at altitude
[~, TAS] = MissionSegsPkg.ComputeFltCon(Alt, 0, "Mach", Mach);

% get the thrust required
ThrustReq = OffParams.Thrust;

% compute the thrust from the electric motor
T_EM = ElectricLoad * Aircraft.Specs.Propulsion.Engine.EtaPoly.Fan / TAS;

% check that it is a number
if (isnan(T_EM))
    T_EM = 0;
end

% subtract the thrust provided by the electric motor
ThrustReq = ThrustReq - T_EM;

% negative thrust required indicates the electric motor produces all power
if (ThrustReq < -1.0e-06)
    
    % therefore, no thrust from the engine is needed
    ThrustReq = 0;
    
end

% convert to kN
ThrustReq = ThrustReq / 1000;

% The thrust_SLS_Conv (kN) is the designed thrust obtained by running 
% non-electrification case 
SLSThrust_conv = ( Aircraft.Specs.Propulsion.SLSThrust(1) + Aircraft.Specs.Propulsion.SLSThrust(3) ) / 1000;


%% FUEL FLOW CALCULATIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define constants (only for the CF34-8E5 engine)
Cff3  =  0.299;
Cff2  = -0.346;
Cff1  =  0.701;
Cffch =  8.e-7;

% get the engine's SLS thrust (in kN)
% if there is no electrification in takeoff, it will run
% non-electrification case, which c = 1 (SLSThrust_HE = SLSThrust_Conv)
SLSThrust_HE = Aircraft.Specs.Propulsion.SLSThrust(1) / 1000;
c = 2 - SLSThrust_HE / SLSThrust_conv;
    
% compute the fraction of thrust required to SLS thrust
ThrustFrac = ThrustReq / (c * SLSThrust_conv);

% get the fuel flow
MDotAct = Cff3  * ThrustFrac ^ 3   + ...
          Cff2  * ThrustFrac ^ 2   + ...
          Cff1  * ThrustFrac       + ...
          Cffch * ThrustReq  * Alt ;

% compute the TSFC (convert thrust from kN to N)
TSFC     = MDotAct / (ThrustReq * 1000);
TSFC_EMT = MDotAct / ( (ThrustReq * 1000 + ElectricLoad / TAS) );


%% FORMULATE OUTPUT STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember the fuel flow
OffOutputs.Fuel = MDotAct;

% remember the thrust output (convert to N from kN)
OffOutputs.Thrust = ThrustReq * 1000;

% remember the TSFCs (in both units)
OffOutputs.TSFC          =                            TSFC              ;
OffOutputs.TSFC_Imperial = UnitConversionPkg.ConvTSFC(TSFC, "SI", "Imp");
OffOutputs.C             =                               c              ;
OffOutputs.TSFC_with_EMT =                            TSFC_EMT          ;


% ----------------------------------------------------------

end