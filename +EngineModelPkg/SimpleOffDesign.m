function [OffOutputs] = SimpleOffDesign(OnDesignEngine, OffParams, ElectricLoad, Aircraft)
%
% [OffOutputs] = SimpleOffDesign(OnDesignEngine, OffParams, ElectricLoad)
% written by Paul Mokotoff, prmoko@umich.edu and Yi-Chih Wang,
% ycwangd@umich.edu
% thanks to Swapnil Jagtap for the equation
% last updated: 08 aug 2024
%
% Simple off-design engine model using a fuel flow equation from the BADA
% Database.
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

% compute the true airspeed at altitude
[~, TAS] = MissionSegsPkg.ComputeFltCon(Alt, 0, "Mach", Mach);

% get the thrust required
ThrustReq = OffParams.Thrust;

% subtract the thrust provided by the electric motor
ThrustReq = ThrustReq - ElectricLoad / TAS;

% convert to kN
ThrustReq = ThrustReq / 1000;


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
if Aircraft.Specs.Power.LamTSPS.Tko == 0
    SLSThrust_conv = OnDesignEngine.Thrust.Net / 1000;
    c = 1;
else
    % The thrust_SLS_HE would be only calculated by
    % thrust_SLS_Conv - (ElectricLoad in takeoff / TAS) / 1000
    % The electricload for calculating thrust_SLS_HE is fixed per iteration
    % , which is ElectricLoad in takeoff. It should not change in different
    % mission segments like 0 in cruise. Once the thrust_SLS_HE is
    % obtained, the value should be used for all mission segments. It
    % doesn't change until next sizing iteration.
    SLSThrust_HE = 61.02 - ( ElectricLoad / TAS) / 1000;  

    % The thrust_SLS_Conv is the designed thrust obtained by running 
    % non-electrification case
    SLSThrust_conv = 61.02;

    c = 2 - SLSThrust_HE / SLSThrust_conv;

end
% compute the fraction of thrust required to SLS thrust

ThrustFrac = ThrustReq / (c * SLSThrust_conv);

% get the fuel flow
MDotAct = Cff3  * ThrustFrac ^ 3   + ...
          Cff2  * ThrustFrac ^ 2   + ...
          Cff1  * ThrustFrac       + ...
          Cffch * ThrustReq  * Alt ;

% compute the TSFC (convert thrust from kN to N)
TSFC = MDotAct / (ThrustReq * 1000);


%% FORMULATE OUTPUT STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember the fuel flow
OffOutputs.Fuel = MDotAct;

% remember the thrust output (convert to N from kN)
OffOutputs.Thrust = ThrustReq * 1000;

% remember the TSFCs (in both units)
OffOutputs.TSFC          =                            TSFC              ;
OffOutputs.TSFC_Imperial = UnitConversionPkg.ConvTSFC(TSFC, "SI", "Imp");


% ----------------------------------------------------------

end