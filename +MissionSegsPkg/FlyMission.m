function [Aircraft] = FlyMission(Aircraft)
%
% [Aircraft] = FlyMission(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 mar 2024
%
% Evaluate the mission profile.
%
% INPUTS:
%     Aircraft - structure with mission profile to be flown.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - updated aircraft structure, which fills the
%                "Aircraft.Mission.History.SI" structure.
%                size/type/units: 1-by-1 / struct / []
%

% ----------------------------------------------------------

%% SETUP %%
%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% values for iterating and   %
% remembering the missions   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define a convergence tolerance
EPS06 = 1.0e-06;

% get maximum number of iterations for evaluating the mission
MaxIter = Aircraft.Settings.Analysis.MaxIter;

% there is no prior mission, so no previous target has been reached
TargetOld = 0;

% no mission history yet
ielem = 0;


%% FLY THE MISSION(S) %%
%%%%%%%%%%%%%%%%%%%%%%%%

% remember the mission profile
Mission = Aircraft.Mission.Profile;

% get the number of missions to fly
nmiss = length(Mission.Target.Valu);

% assume the SOC doesn't reach its cutoff during flight
Aircraft.Mission.History.Flags.SOCOff = zeros(nmiss, 1);

% loop through each mission
for imiss = 1:nmiss
    
    % remember themission id
    Mission.MissID = imiss;
    
    % find the segments associated with the mission
    MissSegs = find(Mission.ID == imiss);
    
    % get the mission target
    Target = Mission.Target.Valu(imiss);
        
    % check if there is a target or not (no target if NaN)
    if (isnan(Target))
        
        % there is no cruise segment
        icrs = 0;
        
    else
        
        % find the cruise segment in the mission
        icrs = find(contains(Mission.Segs(MissSegs), "Cruise"));
        
        % confirm that there is a cruise segment, otherwise throw a warning
        if (~any(icrs))
            warning("ERROR - FlyMission: mission %d doesn't have a cruise segment. Cannot confirm if target is acheived.", ...
                imiss);
            
        end
        
        % account for previous missions in cruise segment index
        icrs = icrs + MissSegs(1) - 1;

        % get the mission type
        type = Mission.Target.Type(imiss);
        
        % if the target type is "Time", convert it to a distance target
        if (strcmp(type, "Time") == 1)
            
            % get the cruise altitudes
            AltBeg = Mission.AltBeg(icrs);
            AltEnd = Mission.AltEnd(icrs);
            
            % get the velocities
            VelBeg = Mission.VelBeg(icrs);
            VelEnd = Mission.VelEnd(icrs);
            
            % get the velocity types
            TypeBeg = Mission.TypeBeg(icrs);
            TypeEnd = Mission.TypeEnd(icrs);
            
            % convert the velocities to TAS
            [~, TASBeg, ~, ~, ~, ~, ~] = MissionSegsPkg.ComputeFltCon( ...
                AltBeg, 0, TypeBeg, VelBeg);
            
            [~, TASEnd, ~, ~, ~, ~, ~] = MissionSegsPkg.ComputeFltCon( ...
                AltEnd, 0, TypeEnd, VelEnd);
            
            % convert the time target from minutes to seconds
            dt = 60 * Target;
            
            % assume constant acceleration during cruise
            dV_dt = (TASEnd - TASBeg) / dt;
            
            % estimate the distance flown (assume all-cruise)
            Target = TASBeg * dt + 0.5 * dV_dt * dt * dt;

        end        
    end
    
    % initialize the iteration
    iter = 0;

    % set the target for cruise (accumulate distance)
    Mission.CrsTarget = TargetOld + Target;
    
    % assume the SOC doesn't reach its cutoff during flight
    Aircraft.Mission.History.Flags.SOCOff(imiss) = 0;
    
    % iterate to find how long the cruise segment should be
    while (iter < MaxIter)
        
        % clear the mission
        Aircraft = DataStructPkg.ClearMission(Aircraft, ielem);
                
        % fly the segment
        for isegs = MissSegs(1):MissSegs(end)
            
            % after the first iteration, don't fly segments before cruise
            if ((iter > 0) && (isegs < icrs))
                continue
            end
            
            % get the segments index
            Mission.SegsID = isegs;
            
            % update the aircraft structure
            Aircraft.Mission.Profile = Mission;
        
            % get the segment name
            SegName = Mission.Segs(isegs);
            
            % get the last point in the segment
            SegEnd = Mission.SegEnd(isegs);
            
            % define the function call
            FunName = strcat("MissionSegsPkg.Eval", SegName);

            % fly the segment
            Aircraft = feval(FunName, Aircraft);

            % remember how many elements are filled (offset by 1 for reset)
            if ((iter < 1) && (isegs < icrs))
                ielem = SegEnd + 1;              
            end
        end

        % check if the target is not a number
        if (isnan(Target))
            
            % there is no iteration needed, so break out
            break
            
        else
            
            % get the mission history
            History = Aircraft.Mission.History.SI;
            
            % get the distance flown (offset by previous target)
            Dist = History.Performance.Dist(SegEnd) - TargetOld;
            
            % difference between actual distance flown and the target
            dDist = Target - Dist;
            
            % compute the relative error
            RelErr = abs(dDist) / Target;
            
            % check convergence
            if (RelErr < EPS06)
                break
            end
            
            % get the mission profile to update
            Mission = Aircraft.Mission.Profile;
            
            % update the cruise target
            Mission.CrsTarget = Mission.CrsTarget + dDist;
            
            % iterate
            iter = iter + 1;
       
        end        
    end
    
    % check if there's more missions to fly
    if (imiss < nmiss)
        
        % remember index that the mission ends
        ielem = SegEnd + 1;
    
        % account for the previous mission(s) flown
        TargetOld = History.Performance.Dist(SegEnd);
        
    end
end
    
% ----------------------------------------------------------

end