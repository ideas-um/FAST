function [Aircraft] = EvalLanding(Aircraft)
%
% [Aircraft] = EvalLanding(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 13 dec 2024
%
% Evaluate the landing segment. The landing segment only uses two control
% points (treats it as a single segment) and cannot be changed by the user.
% It is assumed that: (1) the landing takes 30-seconds; (2) only 30% of the
% power available from each power source can be used for "reverse thrust".
%
% INPUTS:
%     Aircraft - aircraft being flown.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - aircraft flown after landing with the mission history
%                updated in "Aircraft.Mission.History.SI".
%                size/type/units: 1-by-1 / struct / []
%


%% SETUP %%
%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get information from the   %
% mission profile            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the segment id
SegsID = Aircraft.Mission.Profile.SegsID;

% get the beginning and ending control point indices
SegBeg = Aircraft.Mission.Profile.SegBeg(SegsID);
SegEnd = Aircraft.Mission.Profile.SegEnd(SegsID);

% get the landing altitude
AltLand = Aircraft.Mission.Profile.AltBeg(SegsID);

% get the landing velocity
VLand = Aircraft.Mission.Profile.VelBeg(SegsID);

% get the velocity type
VType = Aircraft.Mission.Profile.TypeBeg(SegsID);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% assumptions                %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% landing is 30 seconds
LandTime = 30;

% only two control points (one interval)
npoint = 2;

% no temperature variation
dISA = 0;

% constant acceleration due to gravity (m/s^2)
g = 9.81;

% values that remain zero during landing
dh_dt = zeros(npoint, 1);
FPA   = zeros(npoint, 1);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% allocate memory in arrays  %
% for the mission history    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% allocate memory in temporary arrays
Dist  = zeros(npoint, 1);
Time  = zeros(npoint, 1);

% memory for the fuel and battery energy remaining
Eleft_ES = zeros(npoint, 1);

% get the energy source types
Fuel = Aircraft.Specs.Propulsion.PropArch.SrcType == 1;
Batt = Aircraft.Specs.Propulsion.PropArch.SrcType == 0;

% if not first segment, get accumulated quantities
if (SegBeg > 1)
    
    % initialize aircraft mass
    Mass = repmat(Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg), npoint, 1);
    
    % get distance flown and time aloft
    Dist(:) = Aircraft.Mission.History.SI.Performance.Dist(SegBeg);
    Time(1) = Aircraft.Mission.History.SI.Performance.Time(SegBeg);
    
    % initialize fuel and battery energy remaining
    Eleft_ES = repmat(Aircraft.Mission.History.SI.Energy.Eleft_ES(SegBeg, :), npoint, 1);
        
else
    
    % initialize aircraft mass: assume maximum takeoff weight
    Mass = repmat(Aircraft.Specs.Weight.MTOW, npoint, 1);
    
    % check for any fuel
    if (any(Fuel))
        
        % compute the fuel energy remaining
        Eleft_ES(:, Fuel) = Aircraft.Specs.Power.SpecEnergy.Fuel * Aircraft.Specs.Weight.Fuel;
        
    end
    
    % check for any battery
    if (any(Batt))
        
        % compute the battery energy remaining
        Eleft_ES(:, Batt) = Aircraft.Specs.Power.SpecEnergy.Batt * Aircraft.Specs.Weight.Batt;
        
    end
    
end

% remember the power splits
Aircraft.Mission.History.SI.Power.LamDwn(SegBeg:SegEnd, :) = Aircraft.Specs.Power.LamDwn.Lnd;
Aircraft.Mission.History.SI.Power.LamUps(SegBeg:SegEnd, :) = Aircraft.Specs.Power.LamUps.Lnd;


%% FLY THE LANDING SEGMENT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup times and trajectory %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the time flown between control points (known a-priori)
dTime = diff(linspace(0, LandTime, npoint)');

% accumulate the time
Time(2:end) = Time(1) + cumsum(dTime);

% convert the landing velocity to TAS
[~, TASLand, ~, ~, ~, Rho, ~] = MissionSegsPkg.ComputeFltCon( ...
                                AltLand, dISA, VType, VLand);

% initialize the trajectory
Alt = repmat(  AltLand,    npoint, 1) ;
TAS = linspace(TASLand, 0, npoint   )';

% update the mission history
Aircraft.Mission.History.SI.Performance.TAS( SegBeg:SegEnd) = TAS ;
Aircraft.Mission.History.SI.Performance.Rho( SegBeg:SegEnd) = Rho ;
Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg:SegEnd) = Mass;

% remember the fuel and battery energy remaining
Aircraft.Mission.History.SI.Energy.Eleft_ES(SegBeg:SegEnd, :) = Eleft_ES;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% additional outputs to be   %
% computed and returned      %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% convert airspeeds
[EAS, ~, Mach, ~, ~, ~, ~] = MissionSegsPkg.ComputeFltCon( ...
                             AltLand, dISA, "TAS", TAS);

% compute the instantaneous acceleration (which is 0 at the final point)
dV_dt = [diff(TAS) ./ dTime; 0];

% compute the energy height
EnHt = Alt + TAS .^ 2 / (2 * g);

% compute the potential energy
PE = Mass .* g .* Alt;

% compute the kinetic   energy
KE = 0.5 .* Mass .* TAS .^ 2;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% propulsion analysis, find  %
% the power available and    %
% fuel burn                  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the power available
Aircraft = PropulsionPkg.PowerAvailable(Aircraft);

% get the power available
Pav = Aircraft.Mission.History.SI.Power.TV(SegBeg:SegEnd);

% assume 30% of the power is used for landing
Preq = 0.3 * Pav;

% since the final TAS = 0, assume no thrust or power is required
Preq(end) = 0;

% compute the specific excess power (will be 0)
Ps = zeros(2, 1);

% store variables in the mission history
Aircraft.Mission.History.SI.Power.Req(       SegBeg:SegEnd) = Preq;
Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg:SegEnd) = Mass;
Aircraft.Mission.History.SI.Performance.Time(SegBeg:SegEnd) = Time;
Aircraft.Mission.History.SI.Performance.Mach(SegBeg:SegEnd) = Mach;
Aircraft.Mission.History.SI.Performance.Alt( SegBeg:SegEnd) = Alt ;

% perform the propulsion analysis
Aircraft = PropulsionPkg.PropAnalysis(Aircraft);


%% FILL THE STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%

% performance metrics
Aircraft.Mission.History.SI.Performance.Dist(SegBeg:SegEnd) = Dist ;
Aircraft.Mission.History.SI.Performance.EAS( SegBeg:SegEnd) = EAS  ;
Aircraft.Mission.History.SI.Performance.RC(  SegBeg:SegEnd) = dh_dt;
Aircraft.Mission.History.SI.Performance.Acc( SegBeg:SegEnd) = dV_dt;
Aircraft.Mission.History.SI.Performance.FPA( SegBeg:SegEnd) = FPA  ;
Aircraft.Mission.History.SI.Performance.Ps(  SegBeg:SegEnd) = Ps   ;

% energy quantities
Aircraft.Mission.History.SI.Energy.PE(SegBeg:SegEnd) = PE;
Aircraft.Mission.History.SI.Energy.KE(SegBeg:SegEnd) = KE;

% current segment
Aircraft.Mission.History.Segment(SegBeg:SegEnd) = "Landing";

% ----------------------------------------------------------

end