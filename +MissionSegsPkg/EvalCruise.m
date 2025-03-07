function [Aircraft] = EvalCruise(Aircraft)
%
% [Aircraft] = EvalCruise(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 05 mar 2025
%
% Evaluate a cruise segment by iterating over the aircraft's mass. Climb/
% descent and accelerations are allowed in the segment.
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


%% SETUP %%
%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% specifications from the    %
% aircraft structure         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% maximum rate of climb/descent
dh_dt_max = Aircraft.Specs.Performance.RCMax;

% lift-drag ratio
L_D = Aircraft.Specs.Aero.L_D.Crs;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% information from the       %
% mission profile            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the segment and mission id
SegsID = Aircraft.Mission.Profile.SegsID;

% set number of points in the segment
npoint = Aircraft.Mission.Profile.SegPts(SegsID);

% get the beginning and ending control point indices
SegBeg = Aircraft.Mission.Profile.SegBeg(SegsID);
SegEnd = Aircraft.Mission.Profile.SegEnd(SegsID);

% beginning/ending cruise altitude
AltBeg = Aircraft.Mission.Profile.AltBeg(SegsID);
AltEnd = Aircraft.Mission.Profile.AltEnd(SegsID);

% beginning/ending cruise velocity
VelBeg = Aircraft.Mission.Profile.VelBeg(SegsID);
VelEnd = Aircraft.Mission.Profile.VelEnd(SegsID);

% beginning and ending speed types
TypeBeg = Aircraft.Mission.Profile.TypeBeg(SegsID);
TypeEnd = Aircraft.Mission.Profile.TypeEnd(SegsID);

% get the target
target = Aircraft.Mission.Profile.CrsTarget;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% physical quantities        %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% acceleration due to gravity
g = 9.81; % m / s^2

% assume no temperature deviation (for now)
dISA = 0;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% iteration setup            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define tolerance for testing convergence
EPS06 = 1.0e-6;

% iteration counter
iter = 0;

% maximum number of iterations
MaxIter = 10;


%% EVALUATE THE CLIMB SEGMENT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% iteration initialization   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% convert the beginning velocity to TAS
[~, TASBeg, ~, ~, ~, ~, ~] = MissionSegsPkg.ComputeFltCon( ...
                             AltBeg, dISA, TypeBeg, VelBeg);
                         
% convert the ending velocity to TAS
[~, TASEnd, ~, ~, ~, ~, ~] = MissionSegsPkg.ComputeFltCon( ...
                             AltEnd, dISA, TypeEnd, VelEnd);

% vector of equally spaced altitudes and velocities
Alt = linspace(AltBeg, AltEnd, npoint)'; % m
TAS = linspace(TASBeg, TASEnd, npoint)'; % m/s

% initialize arrays that accumulate (and start at 0)
Dist  = zeros(npoint, 1); % m
Time  = zeros(npoint, 1); % s

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
    Dist(1) = Aircraft.Mission.History.SI.Performance.Dist(SegBeg);
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
Aircraft.Mission.History.SI.Power.LamDwn(SegBeg:SegEnd, :) = repmat(Aircraft.Specs.Power.LamDwn.Crs, SegEnd - SegBeg + 1, 1);
Aircraft.Mission.History.SI.Power.LamUps(SegBeg:SegEnd, :) = repmat(Aircraft.Specs.Power.LamUps.Crs, SegEnd - SegBeg + 1, 1);

% remember initial quantities in the mission history
Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg:SegEnd) = Mass;

% remember the fuel and battery energy remaining
Aircraft.Mission.History.SI.Energy.Eleft_ES(SegBeg:SegEnd, :) = Eleft_ES;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% performance analysis for   %
% constant quantities        %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the flight conditions (ncases)
[EAS, ~, Mach, ~, ~, Rho, ~] = MissionSegsPkg.ComputeFltCon(Alt, dISA, "TAS", TAS);

% energy height (ncases)
EnHt = Alt + TAS .^ 2 ./ (2 * g);

% distance flown
Dist = linspace(Dist(1), target, npoint)';

% distance flown over each segment
dDist = diff(Dist);

% time to fly each segment
dTime = dDist ./ TAS(1:end-1);

% compute the acceleration
dV_dt = [diff(TAS) ./ dTime; 0];

% compute the rate of climb
dh_dt = [diff(Alt) ./ dTime; 0];

% find points that exceed the maximum r/c or r/d
irow = find(dh_dt >  dh_dt_max);
jrow = find(dh_dt < -dh_dt_max);

% update the rates of climb at these points
if ((any(irow)) || (any(jrow)))
    
    % update the rates of climb/descent
    dh_dt(irow) =  dh_dt_max;
    dh_dt(jrow) = -dh_dt_max;
    
    % recompute the time to fly each segment
    dTime = diff(Alt) ./ dh_dt(1:end-1);
    
    % recompute the acceleration
    dV_dt = [diff(TAS) ./ dTime; 0];
    
end

% cumulative time flown (ncases)
Time(2:end) = Time(1) + cumsum(dTime);

% compute the flight path angle
FPA = asind(dh_dt ./ TAS);

% remember the aispeed and density as a function of time
Aircraft.Mission.History.SI.Performance.TAS( SegBeg:SegEnd) = TAS ;
Aircraft.Mission.History.SI.Performance.Rho( SegBeg:SegEnd) = Rho ;
Aircraft.Mission.History.SI.Performance.Mach(SegBeg:SegEnd) = Mach;
Aircraft.Mission.History.SI.Performance.Alt( SegBeg:SegEnd) = Alt ;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        %
% propulsion analysis,   %
% find power available   %
%                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the power available
Aircraft = PropulsionPkg.PowerAvailable(Aircraft);

% get the power available
Pav = Aircraft.Mission.History.SI.Power.TV(SegBeg:SegEnd);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% iterate on the aircraft's  %
% mass                       %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% segment should converge within 10 iterations
while (iter < MaxIter)

    % print the iteration
%     fprintf(1, "Cruise Iteration %2d:\n", iter);
    
    % ------------------------------------------------------
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %                        %
    % performance analysis   %
    %                        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % estimate the lift (ncases)
    L = Mass .* g .* cosd(FPA);
    
    % estimate the drag (ncases)
    D = L / L_D;
    
    % compute power to overcome drag --- new (ncases)
    DV = D .* TAS;
    
    % compute the specific excess power (ncases)
    Ps = (Pav - DV) ./ (Mass .* g);
    
    % check if any specific power values are < 0
    irow = find(Ps < 0);
    
    % check for specific excess power values
    if (any(irow))
        
        % set negative specific power to 0
        Ps(irow) = 0;
        
        % throw warning
        warning('Excess Power (Ps) < 0 for some segments in cruise.');
        
    end
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %                        %
    % energy analysis        %
    %                        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % potential energy (ncases)
    PE = Mass .* g .* Alt;
    
    % kinetic energy (ncases)
    KE = 0.5 .* Mass .* TAS .^ 2;
    
    % power overcame (ncases)
    dPE_dt = Mass .* g   .* dh_dt;
    dKE_dt = Mass .* TAS .* dV_dt;
    
    % power required (ncases)
    Preq = dPE_dt + dKE_dt + DV;
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %                        %
    % propulsion analysis,   %
    % compute the fuel burn  %
    %                        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % remember the original mass
    MassOld = Mass;
    
    % store variables in the mission history
    Aircraft.Mission.History.SI.Power.Req(       SegBeg:SegEnd) = Preq;
    Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg:SegEnd) = Mass;
    Aircraft.Mission.History.SI.Performance.Time(SegBeg:SegEnd) = Time;
    
    % perform the propulsion analysis
    Aircraft = PropulsionPkg.PropAnalysis(Aircraft);
    
    % extract updated mass from the aircraft structure
    Mass = Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg:SegEnd);
    
    % ------------------------------------------------------
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %                        %
    % check convergence and  %
    % iterate as needed      %
    %                        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%

    % check convergence on mass
    MassCheck = abs(Mass - MassOld) ./ MassOld;
        
    % break if flight path angle tolerance is reached at all points
    if (~any(MassCheck > EPS06))
%         fprintf(1, "Breaking Cruise...\n\n");
        break;
    end
            
    % iterate
    iter = iter + 1;
    
end


%% POST-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% compute output parameters  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% cumulative time flown (ncases)
Time(2:end) = Time(1) + cumsum(dTime);


%% FILL THE STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%

% performance metrics
Aircraft.Mission.History.SI.Performance.Dist(SegBeg:SegEnd) = Dist ;
Aircraft.Mission.History.SI.Performance.Time(SegBeg:SegEnd) = Time ;
Aircraft.Mission.History.SI.Performance.EAS( SegBeg:SegEnd) = EAS  ;
Aircraft.Mission.History.SI.Performance.RC(  SegBeg:SegEnd) = dh_dt;
Aircraft.Mission.History.SI.Performance.Acc( SegBeg:SegEnd) = dV_dt;
Aircraft.Mission.History.SI.Performance.FPA( SegBeg:SegEnd) = FPA  ;
Aircraft.Mission.History.SI.Performance.Ps(  SegBeg:SegEnd) = Ps   ;

% energy quantities
Aircraft.Mission.History.SI.Energy.PE(  SegBeg:SegEnd) = PE   ;
Aircraft.Mission.History.SI.Energy.KE(  SegBeg:SegEnd) = KE   ;

% current segment
Aircraft.Mission.History.Segment(SegBeg:SegEnd) = "Cruise";

% ----------------------------------------------------------

end