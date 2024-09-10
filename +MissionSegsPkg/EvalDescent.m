function [Aircraft] = EvalDescent(Aircraft)
%
% [Aircraft] = EvalDescent(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% patterned after code written by Gokcin Cinar in E-PASS
% last updated: 07 mar 2024
%
% Evaluate a descent segment by iterating over the rate of climb and
% instantaneous acceleration at each control point in the mission.
%
% INPUTS:
%     Aircraft - aircraft being flown.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - aircraft flown after descent with the mission history
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

% maximum rate of climb
RCMax = Aircraft.Specs.Performance.RCMax;

% lift-drag ratio
L_D = Aircraft.Specs.Aero.L_D.Des;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% information from the       %
% mission profile            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the segment id
SegsID = Aircraft.Mission.Profile.SegsID;

% set number of points in the segment
npoint = Aircraft.Mission.Profile.SegPts(SegsID);

% get the beginning and ending control point indices
SegBeg = Aircraft.Mission.Profile.SegBeg(SegsID);
SegEnd = Aircraft.Mission.Profile.SegEnd(SegsID);

% beginning and ending altitudes
AltBeg = Aircraft.Mission.Profile.AltBeg(SegsID);
AltEnd = Aircraft.Mission.Profile.AltEnd(SegsID);

% beginning and ending velocities
VelBeg = Aircraft.Mission.Profile.VelBeg(SegsID);
VelEnd = Aircraft.Mission.Profile.VelEnd(SegsID);

% beginning and ending velocity types
TypeBeg = Aircraft.Mission.Profile.TypeBeg(SegsID);
TypeEnd = Aircraft.Mission.Profile.TypeEnd(SegsID);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% physical quantities        %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% convert the rate of climb to a rate of descent (and reduce slightly)
RDMax = -0.8 * RCMax;

% acceleration due to gravity
g = 9.81; % m / s^2

% assume no temperature deviation
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


%% EVALUATE THE DESCENT SEGMENT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
Fuel = Aircraft.Specs.Propulsion.PropArch.ESType == 1;
Batt = Aircraft.Specs.Propulsion.PropArch.ESType == 0;

% guess a rate of descent and an instantaneous acceleration to iterate over
dh_dt = zeros(npoint, 1);
dV_dt = zeros(npoint, 1);

% remember prior rate of descent and acceleration for iterating
dh_dtOld = zeros(npoint, 1);
dV_dtOld = zeros(npoint, 1);

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

% update the mission history
Aircraft.Mission.History.SI.Performance.TAS( SegBeg:SegEnd) = TAS ;
Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg:SegEnd) = Mass;

% remember the fuel and battery energy remaining
Aircraft.Mission.History.SI.Energy.Eleft_ES(SegBeg:SegEnd, :) = Eleft_ES;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% iterate                    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% trajectory should converge within 10 iterations
while (iter < MaxIter)

    % print the iteration
%     fprintf(1, "Descent Iteration %2d:\n", iter);
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %                        %
    % get the flight         %
    % conditions             %
    %                        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % get the flight conditions (ncases)
    [EAS, ~, Mach, ~, ~, Rho, ~] = MissionSegsPkg.ComputeFltCon(Alt, dISA, "TAS", TAS);
    
    % remember the flight conditions for computing the power available
    Aircraft.Mission.History.SI.Performance.TAS( SegBeg:SegEnd) = TAS ;
    Aircraft.Mission.History.SI.Performance.Rho( SegBeg:SegEnd) = Rho ;
    Aircraft.Mission.History.SI.Performance.Mach(SegBeg:SegEnd) = Mach;
    Aircraft.Mission.History.SI.Performance.Alt( SegBeg:SegEnd) = Alt ;
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %                        %
    % propulsion analysis,   %
    % find power available   %
    %                        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % compute the power available
    Aircraft = PropulsionPkg.PowerAvailable(Aircraft);
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %                        %
    % performance analysis   %
    %                        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % estimate the flight path angle
    FPA = asind(dh_dt ./ TAS);
    
    % estimate the lift
    L = Mass .* g .* cosd(FPA);
    
    % estimate the drag
    D = L / L_D;

    % calculate energy height
    EnHt = Alt + TAS .^ 2 ./ (2 * g);
    
    % compute power to overcome drag
    DV = D .* TAS;
    
    % compute the specific excess power (idle engine while gliding)
    Ps = -DV ./ (Mass .* g);

    % compute time to fly (negate quotient for a dTime > 0)
    dTime = diff(EnHt) ./ Ps(1:end-1);

    % update the rate of climb
    dh_dt = [diff(Alt) ./ dTime; 0];
    
    % find points that exceed the maximum rate of climb
    irow = find(dh_dt < RDMax);
    
    % adjust points that exceed the maximum rate of climb
    if (any(irow))
        
        % limit the rate of climb
        dh_dt(irow) = RDMax;
        
        % recompute the time required to fly the segment
        dTime = diff(Alt) ./ dh_dt(1:end-1);
                        
    end
    
    % compute the instantaneous acceleration
    dV_dt = [diff(TAS) ./ dTime; 0];
    
    % cumulative time flown
    Time(2:end) = Time(1) + cumsum(dTime);

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
    Preq = DV + dPE_dt + dKE_dt;
    
    % check for power required < 0 (this is okay on descent)
    ipoint = Preq < 0;
    
    % for any power required < 0, assume small power required (idle thrust)
    Preq(ipoint) = 0.0001;

    % thrust required (ncases)
    Treq = Preq ./ TAS;
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %                        %
    % propulsion analysis    %
    %                        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % store variables in the mission history
    Aircraft.Mission.History.SI.Power.Req(       SegBeg:SegEnd) = Preq;
    Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg:SegEnd) = Mass;
    Aircraft.Mission.History.SI.Performance.Time(SegBeg:SegEnd) = Time;
    
    % perform the propulsion analysis
    Aircraft = PropulsionPkg.PropAnalysisNew(Aircraft);
    
    % extract updated mass from aircraft structure
    Mass = Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg:SegEnd);
    
    % ------------------------------------------------------
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %                        %
    % check convergence and  %
    % iterate as needed      %
    %                        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%

    % check convergence
    dh_dtErr = abs(dh_dt - dh_dtOld) ./ dh_dt;
    dV_dtErr = abs(dV_dt - dV_dtOld) ./ dV_dt;
        
    % break if flight path angle tolerance is reached at all points
    if ((~any(abs(dh_dtErr) > EPS06)) && ...
        (~any(abs(dV_dtErr) > EPS06)) )
%         fprintf(1, "Breaking Descent...\n\n");
        break;
    end
    
    % set new rate of climb and instantaneous acceleration
    dh_dtOld = dh_dt;
    dV_dtOld = dV_dt;
        
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

% ground speed (ncases)
GS = TAS .* cosd(FPA);

% distance travelled in each segment (ncases-1)
dDist = GS(1:end-1) .* dTime;

% cumulative distance flown (ncases)
Dist(2:end) = Dist(1) + cumsum(dDist);


%% FILL THE STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%

% performance metrics
Aircraft.Mission.History.SI.Performance.Dist(SegBeg:SegEnd) = Dist ;
Aircraft.Mission.History.SI.Performance.TAS( SegBeg:SegEnd) = TAS  ;
Aircraft.Mission.History.SI.Performance.EAS( SegBeg:SegEnd) = EAS  ;
Aircraft.Mission.History.SI.Performance.RC(  SegBeg:SegEnd) = dh_dt;
Aircraft.Mission.History.SI.Performance.Acc( SegBeg:SegEnd) = dV_dt;
Aircraft.Mission.History.SI.Performance.FPA( SegBeg:SegEnd) = FPA  ;
Aircraft.Mission.History.SI.Performance.Ps(  SegBeg:SegEnd) = Ps   ;

% energy quantities
Aircraft.Mission.History.SI.Energy.PE(  SegBeg:SegEnd) = PE   ;
Aircraft.Mission.History.SI.Energy.KE(  SegBeg:SegEnd) = KE   ;

% current segment
Aircraft.Mission.History.Segment(SegBeg:SegEnd) = "Descent";

% ----------------------------------------------------------

end