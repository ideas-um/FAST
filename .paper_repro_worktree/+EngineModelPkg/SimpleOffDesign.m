function [OffOutputs] = SimpleOffDesign(Aircraft, OffParams, ElectricLoad, EngineIdx, MissionIdx)
%
% [OffOutputs] = SimpleOffDesign(Aircraft, OffParams, ElectricLoad, EngineIdx, MissionIdx))
% written by Paul Mokotoff, prmoko@umich.edu and Yi-Chih Wang,
% ycwangd@umich.edu
% last updated: 05 Oct 2024
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
%     EngineIdx    - index of the engine (power source) being evaluated.
%                    size/type/units: 1-by-1 / integer / []
%
%     MissionIdx   - index of the point in the mission history being
%                    evaluated.
%                    size/type/units: 1-by-1 / integer / []
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

% compute the thrust from the supplemental component(s) ... the fan
% efficiency is counted in PowerSupplementCheck and was removed from here
TsuppOffDesign = ElectricLoad / TAS;

% check that it is a number
if (isnan(TsuppOffDesign) || isinf(TsuppOffDesign))
    
    % otherwise, return 0
    TsuppOffDesign = 0;
    
end

% subtract the thrust provided by the electric motor
ThrustReq = ThrustReq - TsuppOffDesign;

% negative thrust required indicates the electric motor produces all power
if     (ThrustReq < -1.0e-06)
    
    % therefore, no thrust from the engine is needed
    ThrustReq = 0;

elseif (ThrustReq > Aircraft.Mission.History.SI.Power.Tav_PS(MissionIdx, EngineIdx))

    % set the thrust required to the thrust available
    ThrustReq = Aircraft.Mission.History.SI.Power.Tav_PS(MissionIdx, EngineIdx);
    
end

% convert to kN
ThrustReq = ThrustReq / 1000;

% get the design thrust and its supplement
ThrustEng  = Aircraft.Specs.Propulsion.SLSThrust( EngineIdx);
ThrustSupp = Aircraft.Specs.Propulsion.ThrustSupp(EngineIdx);

% find any thrust supplements < 0 (means power is siphoned off)
isupp = find(ThrustSupp < 0); % not necessary now, but will be for vectorizing

% check if any thrust supplements are < 0
if (any(isupp))
    
    % in this case, power is siphoned off ... the engine needs to be
    % larger, so the "conventional" thrust just comes from the engine only
    ThrustSupp(isupp) = 0;
    
end

% The thrust_SLS_Conv (kN) is the designed thrust obtained by running 
% non-electrification case
SLSThrust_conv = (ThrustEng + ThrustSupp) / 1000;


%% FUEL FLOW CALCULATIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% fuel flow rate coefficients of BADA equation
Cff3  =  Aircraft.Specs.Propulsion.Engine.Cff3 ;
Cff2  =  Aircraft.Specs.Propulsion.Engine.Cff2 ;
Cff1  =  Aircraft.Specs.Propulsion.Engine.Cff1 ;
Cffch =  Aircraft.Specs.Propulsion.Engine.Cffch;

% compute the thrust ratio ... if there is no electrification in takeoff,
% it will run non-electrification case, which c = 1
% (SLSThrust_HE = SLSThrust_Conv). the equation was formerly:
%     c = 2 - SLSThrust_HE / SLSThrust_conv;
%
% now, we just use a coefficient from the engine specification file
c = Aircraft.Specs.Propulsion.Engine.HEcoeff;
    
% compute the fraction of thrust required to SLS thrust
ThrustFrac = ThrustReq / (c * SLSThrust_conv);

% get the fuel flow
MDotAct = Cff3  * ThrustFrac ^ 3   + ...
          Cff2  * ThrustFrac ^ 2   + ...
          Cff1  * ThrustFrac       + ...
          Cffch * ThrustReq  * Alt ;

% compute the TSFC (convert thrust from kN to N)
TSFC    = MDotAct / (ThrustReq * 1000);


%% FORMULATE OUTPUT STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember the fuel flow
OffOutputs.Fuel = MDotAct; 

% remember the thrust output (convert to kN from N)
OffOutputs.Thrust = ThrustReq * 1000;

% remember the TSFCs (in both units)
OffOutputs.TSFC          =                            TSFC              ;
OffOutputs.TSFC_Imperial = UnitConversionPkg.ConvTSFC(TSFC, "SI", "Imp");
OffOutputs.C             =                               c              ;

% ----------------------------------------------------------

end