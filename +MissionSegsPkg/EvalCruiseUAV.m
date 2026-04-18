function [Aircraft] = EvalCruiseUAV(Aircraft)
%
% [Aircraft] = EvalCruiseUAV(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 15 apr 2026
%
% evaluate the cruise segment using a breguet range equation for
% conventionally powered UAVs and a modified one (parameterized by energy)
% for electrically-powered UAVs.
%
% INPUTS:
%     Aircraft - aircraft being flown.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - aircraft flown after cruise with the mission history
%                updated in "Aircraft.Mission.History.SI".
%                size/type/units: 1-by-1 / struct / []
%


%% GET MISSION PROFILE INFORMATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the mission/segment ids
MissID = Aircraft.Mission.Profile.MissID;
SegsID = Aircraft.Mission.Profile.SegsID;

% get the current cruise target
Target = Aircraft.Mission.Profile.CrsTarget;

% check for distance- or time-based target
TargetType = Aircraft.Mission.Profile.Target.Type(MissID);

% get the beginning and ending control point indices
SegBeg = Aircraft.Mission.Profile.SegBeg(SegsID);
SegEnd = Aircraft.Mission.Profile.SegEnd(SegsID);

% set number of points in the segment
npnt = Aircraft.Mission.Profile.SegPts(SegsID);


%% INFORMATION ABOUT THE AIRCRAFT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the overall efficiency (combined aero-propulsive efficiency)
EtaOv = Aircraft.Specs.Performance.EtaOv;

% get the propulsion architecture type
Arch = Aircraft.Specs.Propulsion.PropArch.Type;


%% GET INITIAL CONDITIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the initial altitude, speed, and type
Alt   = Aircraft.Mission.Profile.AltBeg( SegsID);
Vel   = Aircraft.Mission.Profile.VelBeg( SegsID);
VType = Aircraft.Mission.Profile.TypeBeg(SegsID);

if (SegBeg > 1)
    
    % get the weight at the beginning of the segment
    W0 = Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg);
    
    % get the current fuel burn
    BegFburn = Aircraft.Mission.History.SI.Weight.Fburn(SegBeg);
    
    % get the time and distance flown already
    BegTime = Aircraft.Mission.History.SI.Performance.Time(SegBeg);
    BegDist = Aircraft.Mission.History.SI.Performance.Dist(SegBeg);
    
    % get the current energy expenditures
    BegEnergy = Aircraft.Mission.History.SI.Energy.E_ES(    SegBeg);
    BegEleft  = Aircraft.Mission.History.SI.Energy.Eleft_ES(SegBeg);
    
else
    
    % get MTOW
    W0 = Aircraft.Specs.Weight.MTOW;
    
    % no fuel burn yet
    BegFburn = 0;
    
    % no distance/time flown
    BegTime = 0;
    BegDist = 0;
    
    % no energy expenditure
    BegEnergy = 0;
    
    % check for fuel or battery
    Fuel = Aircraft.Specs.Propulsion.PropArch.SrcType == 1;
    Batt = Aircraft.Specs.Propulsion.PropArch.SrcType == 0;
    
    % assume full fuel/battery energy (convert to joules, remove later)
    if (any(Fuel))
        BegEleft = Aircraft.Specs.Power.SpecEnergy.Fuel * Aircraft.Specs.Weight.Fuel * 3.6e+6;
    end
    
    if (any(Batt))
        BegEleft = Aircraft.Specs.Power.SpecEnergy.Batt * Aircraft.Specs.Weight.Batt * 3.6e+6;
    end
end


%% COMPUTE THE RANGE OR ENDURANCE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get acceleration due to gravity
g = MissionSegsPkg.Gravity(Alt);

% get the true airspeed
[EAS, TAS, Mach, ~, ~, Rho] = MissionSegsPkg.ComputeFltCon(Alt, 0, VType, Vel);

% check for turbofan or turboprop/piston aircraft
if     (strcmpi(Arch, "C"))
    
    % get the specific fuel consumption
    c = Aircraft.Specs.Propulsion.SFC;
    
    % get the fuel specific energy
    efuel = Aircraft.Specs.Power.SpecEnergy.Fuel;
    
%     % check the target type
%     if     (strcmpi(TargetType, "Dist"))
        
        % get the range
        R = Target;
        
        % compute the final weight as a function of the range
        W1 = W0 / exp(R * c / EtaOv);
        
        % compute the time to fly
        E = R / TAS;
        
%     elseif (strcmpi(TargetType, "Time"))
%         
%         % get the endurance (minutes to seconds)
%         E = Target;
%         
%         % compute the final weight as a function of the endurance
%         W1 = (E * c / EtaOv + W0 ^ (-1/2)) ^ -2;
%         
%         % get the distance flown
%         R = E * TAS;
%                 
%     else
%         
%         % throw an error
%         error("ERROR - EvalCruiseUAV: invalid mission target type.");
%         
%     end
    
    % compute the fuel burn
    Wfuel = W0 - W1;
    
    % compute the energy expended
    EExpended = efuel * Wfuel;
        
elseif (strcmpi(Arch, "E"))
    
    % get the battery specific energy
    ebatt = Aircraft.Specs.Power.SpecEnergy.Batt;
    
    % convert units from Wh/kg to Ws/kg
    ebatt = ebatt * 3600;
    
%     % check the target type
%     if     (strcmpi(TargetType, "Dist"))
        
        % get the range
        R = Target;
        
        % compute the battery weight as a function of the range
        Wbatt = R * W0 / EtaOv / ebatt;
        
        % compute the time to fly
        E = R / TAS;
        
%     elseif (strcmpi(TargetType, "Time"))
%         
%         % get the endurance (minutes to seconds)
%         E = Target;
%         
%         % compute the battery weight as a function of the endurance
%         Wbatt = E * W0 ^ (3/2) / EtaOv / ebatt;
%         
%         % get the distance flown
%         R = E * TAS;
%         
%     else
%         
%         % throw an error
%         error("ERROR - EvalCruiseUAV: invalid mission target type.");
%         
%     end
    
    % no weight change
    W1 = W0;
    
    % no fuel burn
    Wfuel = 0;
    
    % battery energy expended
    EExpended = ebatt * Wbatt;
    
else
    
    % throw an error
    error("ERROR - EvalCruiseUAV: invalid aircraft class selected.");
    
end


%% ASSUME STATE VARIABLES CHANGE LINEARLY %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember the time and distance flown
Time = linspace(BegTime, BegTime + E, npnt);
Dist = linspace(BegDist, BegDist + R, npnt);

% remember the aircraft weight
Weight = linspace(W0      , W1              , npnt);
Fburn  = linspace(BegFburn, BegFburn + Wfuel, npnt);

% compute the energy expenditure
E_ES  = linspace(BegEnergy, BegEnergy + EExpended, npnt);
Eleft = linspace(BegEleft , BegEleft  - EExpended, npnt);

% compute the potential energy
PE = Weight .* g .* Alt;
KE = 0.5 .* Weight .* TAS .^ 2;


%% FILL THE AIRCRAFT STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% performance metrics
Aircraft.Mission.History.SI.Performance.Time(SegBeg:SegEnd) = Time;
Aircraft.Mission.History.SI.Performance.Dist(SegBeg:SegEnd) = Dist;
Aircraft.Mission.History.SI.Performance.TAS( SegBeg:SegEnd) = TAS ;
Aircraft.Mission.History.SI.Performance.EAS( SegBeg:SegEnd) = EAS ;
Aircraft.Mission.History.SI.Performance.Alt( SegBeg:SegEnd) = Alt ;
Aircraft.Mission.History.SI.Performance.Mach(SegBeg:SegEnd) = Mach;
Aircraft.Mission.History.SI.Performance.Rho( SegBeg:SegEnd) = Rho ;

Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg:SegEnd) = Weight;
Aircraft.Mission.History.SI.Weight.Fburn(    SegBeg:SegEnd) = Fburn ;

Aircraft.Mission.History.SI.Energy.KE(      SegBeg:SegEnd) = PE   ;
Aircraft.Mission.History.SI.Energy.PE(      SegBeg:SegEnd) = KE   ;
Aircraft.Mission.History.SI.Energy.E_ES(    SegBeg:SegEnd) = E_ES ;
Aircraft.Mission.History.SI.Energy.Eleft_ES(SegBeg:SegEnd) = Eleft;

% current segment
Aircraft.Mission.History.Segment(SegBeg:SegEnd) = "CruiseUAV";


end 