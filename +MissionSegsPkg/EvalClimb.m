function [Aircraft] = EvalClimb(Aircraft)
%
% [Aircraft] = EvalClimb(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% patterned after code written by Gokcin Cinar in E-PASS
% last updated: 09 sep 2024
%
% Evaluate a climb segment by iterating over the power required. While
% iterating over the power required, the drag and specific excess power
% are also iterated upon. This changes the flight time between successive
% points in the climb segment. Once the flight time is updated, the rate of
% climb and flight path angle for each point in the climb segment are
% updated, respectively.
%
% INPUTS:
%     Aircraft - aircraft being flown.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - aircraft flown after climb with the mission history
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
dh_dtMax = Aircraft.Specs.Performance.RCMax;

% lift-drag ratio
L_D = Aircraft.Specs.Aero.L_D.Clb;

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

% beginning and ending speed types
TypeBeg = Aircraft.Mission.Profile.TypeBeg(SegsID);
TypeEnd = Aircraft.Mission.Profile.TypeEnd(SegsID);

% rate of climb (if prescribed)
dh_dtReq = Aircraft.Mission.Profile.ClbRate(SegsID);

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

% maximum number of iterations
MaxIter = 10;


%% INITIALIZE THE CLIMB SEGMENT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% segment initialization     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% vector of equally spaced altitudes
Alt = linspace(AltBeg, AltEnd, npoint)'; % m
                         
% convert the ending velocity to match the beginning one
% *** suppress warning that EASEnd and MachEnd may not be used ... they
% could be used in the following line for dynamic evaluation ***
[EASEnd, TASEnd, MachEnd] = MissionSegsPkg.ComputeFltCon(AltEnd, dISA, ...
                                           TypeEnd, VelEnd); %#ok<ASGLU>

% update the ending velocity type to match the beginning's type
VelEnd = eval(strcat(TypeBeg, "End"));

% create a linearly spaced array of velocities (matches beginning's type)
VelSeg = linspace(VelBeg, VelEnd, npoint)';

% convert to other velocity types
[EAS, TAS, ~, ~, ~, ~, ~] = MissionSegsPkg.ComputeFltCon(Alt, ...
                                                dISA, TypeBeg, VelSeg);

% ----------------------------------------------------------                                            

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% array initialization       %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize arrays that accumulate (and start at 0)
Dist = zeros(npoint, 1); % m
Time = zeros(npoint, 1); % s

% memory for the fuel and battery energy remaining
Eleft_ES = zeros(npoint, 1);

% get the energy source types
Fuel = Aircraft.Specs.Propulsion.PropArch.ESType == 1;
Batt = Aircraft.Specs.Propulsion.PropArch.ESType == 0;

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

% assume thrust split comes from the aircraft specifications
LamTS = repmat(Aircraft.Specs.Power.LamTS.Clb, npoint, 1);

% assume energy/power/thrust splits come from the aircraft specifications
LamTSPS = repmat(Aircraft.Specs.Power.LamTSPS.Clb, npoint, 1);
LamPSPS = repmat(Aircraft.Specs.Power.LamPSPS.Clb, npoint, 1);
LamPSES = repmat(Aircraft.Specs.Power.LamPSES.Clb, npoint, 1);

% check if the power optimization structure is available
if (isfield(Aircraft, "PowerOpt"))
    
    % check if the splits are available
    if (isfield(Aircraft.PowerOpt, "Splits"))
        
        % get the thrust/power/energy splits
        [LamTS, LamTSPS, LamPSPS, LamPSES] = OptimizationPkg.GetSplits( ...
        Aircraft, SegBeg, SegEnd, LamTS, LamTSPS, LamPSPS, LamPSES);
        
    end
end

% update the mission history
Aircraft.Mission.History.SI.Performance.TAS( SegBeg:SegEnd) = TAS ;
Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg:SegEnd) = Mass;

% remember the splits
Aircraft.Mission.History.SI.Power.LamTS(  SegBeg:SegEnd, :) = LamTS  ;
Aircraft.Mission.History.SI.Power.LamTSPS(SegBeg:SegEnd, :) = LamTSPS;
Aircraft.Mission.History.SI.Power.LamPSPS(SegBeg:SegEnd, :) = LamPSPS;
Aircraft.Mission.History.SI.Power.LamPSES(SegBeg:SegEnd, :) = LamPSES;

% remember the fuel and battery energy remaining
Aircraft.Mission.History.SI.Energy.Eleft_ES(SegBeg:SegEnd, :) = Eleft_ES;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% iteration initialization   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% iteration counter
iter = 0;

% guess the power required (to iterate over)
PreqOld = zeros(npoint, 1);

% if rate of climb is prescribed, set it now
if (~isnan(dh_dtReq))
    
    % get the required rate of climb
    dh_dt = [repmat(dh_dtReq, npoint-1, 1); 0];
        
else
    
    % assume rate of climb of 0 to start (will be overwritten)
    dh_dt = zeros(npoint, 1);
    
end


%% EVALUATE THE CLIMB SEGMENT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% iterate                    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% flight path angle should converge within 10 iterations
while (iter < MaxIter)

    % print the iteration
%     fprintf(1, "Climb Iteration %2d:\n", iter);
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %                        %
    % get the flight         %
    % conditions             %
    %                        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % calculate energy height
    EnHt = Alt + TAS .^ 2 ./ (2 * g);
    
    % difference in energy heigt
    dEnHt = diff(EnHt);
    
    % get the flight conditions (ncases)
    [EAS, ~, Mach, ~, ~, Rho, ~] = MissionSegsPkg.ComputeFltCon(...
                                   Alt, dISA, "TAS", TAS);
                               
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
    
    % get the power available
    Pav = Aircraft.Mission.History.SI.Power.TV(SegBeg:SegEnd);
    
    % for full throttle, recompute the operational power splits
    Aircraft = PropulsionPkg.RecomputeSplits(Aircraft, SegBeg, SegEnd);

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
    D = L ./ L_D;

    % compute the drag power (power to overcome drag)
    DV = D .* TAS;
            
    % compute the specific excess power
    Ps = (Pav - DV) ./ (Mass .* g);

    % check for invalid specific excess power values
    if (any(Ps < 0))
        warning('Target climb altitude cannot be reached (Ps < 0). Results may be faulty.')
    end
            
    % compute time to fly, depending if rate of climb is given
    if (isnan(dh_dtReq))
      
        % compute time to fly based on energy height
        dTime = dEnHt ./ Ps(1:end-1);
        
        % update the rate of climb (0 gets overwritten by next segment)
        dh_dt = [diff(Alt) ./ dTime; 0];
        
        % find points that exceed the maximum rate of climb
        irow = find(dh_dt > dh_dtMax);
        
        % adjust points that exceed the maximum rate of climb
        if (any(irow))
            
            % limit the rate of climb
            dh_dt(irow) = dh_dtMax;
            
            % recompute the time required to fly the segment
            dTime = diff(Alt) ./ dh_dt(1:end-1);
            
        end
        
        % compute the acceleration
        dV_dt = [diff(TAS) ./ dTime; 0];
                
    else
        
        % compute time to fly based on rate of climb
        dTime = diff(Alt) ./ dh_dt(1:end-1);

        % compute the acceleration
        dV_dt = [diff(TAS) ./ dTime; 0];
        
        % find the maximum realizable acceleration
        dV_dtMax = (Ps - dh_dt) .* g ./ TAS;

        % adjust points when the required acceleration can't be realized
        if (any(dV_dt > dV_dtMax))
            
            % assume maximum acceleration at all points
            dV_dt = dV_dtMax;
        
            % update velocity profile (assume maximum acceleration at all)
            TAS(2:end) = TAS(1) + cumsum(dV_dt(1:end-1) .* dTime);
        
            % avoid overspeeding
            TAS(TAS > TASEnd) = TASEnd;
            
            % re-compute the acceleration
            dV_dt = [diff(TAS) ./ dTime; 0];
            
        end
    end
    
    % cumulative time flown (ncases)
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
    Preq = dPE_dt + dKE_dt + DV;
    
    % thrust required
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
    Aircraft = PropulsionPkg.PropAnalysis(Aircraft);
    
    % extract updated mass from aircraft structure
    Mass = Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg:SegEnd);
    
    % ------------------------------------------------------
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %                        %
    % check convergence and  %
    % iterate as needed      %
    %                        %
    %%%%%%%%%%%%%%%%%%%%%%%%%%

    % check convergence on power required
    PreqCheck = abs(Preq - PreqOld) ./ Preq;
        
    % break if tolerance is reached at all points
    if (~any(PreqCheck > EPS06))
%         fprintf(1, "Breaking Climb...\n\n");
        break;
    end
    
    % remember the power required
    PreqOld = Preq;
        
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
Aircraft.Mission.History.SI.Performance.EAS( SegBeg:SegEnd) = EAS  ;
Aircraft.Mission.History.SI.Performance.RC(  SegBeg:SegEnd) = dh_dt;
Aircraft.Mission.History.SI.Performance.Acc( SegBeg:SegEnd) = dV_dt;
Aircraft.Mission.History.SI.Performance.FPA( SegBeg:SegEnd) = FPA  ;
Aircraft.Mission.History.SI.Performance.Ps(  SegBeg:SegEnd) = Ps   ;

% energy quantities
Aircraft.Mission.History.SI.Energy.PE(SegBeg:SegEnd) = PE;
Aircraft.Mission.History.SI.Energy.KE(SegBeg:SegEnd) = KE;

% current segment
Aircraft.Mission.History.Segment(SegBeg:SegEnd) = "Climb";

% ----------------------------------------------------------

end