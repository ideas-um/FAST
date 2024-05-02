function [Aircraft] = ProcessProfile(Aircraft)
%
% [Aircraft] = ProcessProfile(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 mar 2024
%
% Given a mission profile, check for valid inputs.
%
% INPUTS:
%     Aircraft - structure with a mission profile provided in
%                "Aircraft.Mission.Profile".
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - structure with a mission profile checked for completeness
%                and correctness.
%                size/type/units: 1-by-1 / struct / []
%


%% SETUP %%
%%%%%%%%%%%

% import the mission profile
Mission = Aircraft.Mission.Profile;

% tolerance for some input checks
EPS06 = 1.0e-06;


%% CHECK THE SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%

% get the number of segments
[nsegs, ncols] = size(Mission.Segs);

% check that segments are in a column vector
if (ncols > 1)
    error("ERROR - ProcessProfile: mission segments (.Segs) must be in a column vector.");
end

% allocate memory for remembering segment endpoints and points in the seg.
SegBeg = ones(nsegs, 1);
SegEnd = ones(nsegs, 1);
SegPts = ones(nsegs, 1);

% loop through each segment to check for a valid name
for isegs = 1:nsegs
    
    % get the segment name
    SegName = Mission.Segs(isegs);
    
    % check for a valid segment name
    if      (strcmpi(SegName, "Takeoff"  ) == 1)
        
        % get number of points in takeoff
        SegPts(isegs) = Aircraft.Settings.TkoPoints;
                
    elseif  (strcmpi(SegName, "Climb"    ) == 1)
        
        % get number of points in climb
        SegPts(isegs) = Aircraft.Settings.ClbPoints;
        
    elseif ((strcmpi(SegName, "Cruise"   ) == 1) || ...
            (strcmpi(SegName, "CruiseBRE") == 1) )
        
        % get number of points in cruise
        SegPts(isegs) = Aircraft.Settings.CrsPoints;
        
    elseif  (strcmpi(SegName, "Descent"  ) == 1)
        
        % get number of points in descent
        SegPts(isegs) = Aircraft.Settings.DesPoints;
        
    elseif  (strcmpi(SegName, "Landing"  ) == 1)
        
        % only two points in landing
        SegPts(isegs) = 2;
        
    else
    
        % print an error
        error("ERROR - ProcessProfile: mission segment, .Segs(%d), has an invalid name: %s.", ...
              isegs, SegName);

    end
    
    % get the initial segment index (accounting for a shared point)
    if (isegs > 1)
        SegBeg(isegs) = SegBeg(isegs-1) + SegPts(isegs-1) - 1;
    end
    
    % get the ending segment index
    SegEnd(isegs) = SegBeg(isegs) + SegPts(isegs) - 1;
    
end


%% CHECK THE MISSION TARGETS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% number of mission targets
[ntarget, ncols] = size(Mission.Target.Valu);

% check that mission targets are a column vector
if (ncols > 1)
    error("ERROR - ProcessProfile: mission targets (.Target.Valu) must be in a column vector.");
end

% number of mission target types
[ntype, ncols] = size(Mission.Target.Type);

% check that mission target types are a column vector
if (ncols > 1)
    error("ERROR - ProcessProfile: mission target types (.Target.Type) must be in a column vector.");
end

% check for same number of mission targets and types
if (ntarget ~= ntype)
    error("ERROR - ProcessProfile: there are %d mission targets (.Target) but %d mission types (.Target.Type) are given.", ...
          ntarget, ntype);
      
end

% check for valid mission targets and types
for itarget = 1:ntarget
    
    % if target is NaN, ignore the type and continue
    if (isnan(Mission.Target.Valu(itarget)))
        continue
        
    else
        
        % check that the target is positive
        if (Mission.Target.Valu(itarget) < EPS06)
            
            % throw an error
            error("ERROR - ProcessProfile: mission target (.Target.Valu(%d)) must be positive.", ...
                itarget);
            
        end
        
        % get the target name
        TarName = Mission.Target.Type(itarget);
        
        % check for valid name
        if ((strcmp(TarName, "Dist") == 0) && ...
            (strcmp(TarName, "Time") == 0) )
            
            % print an error
            error("ERROR - ProcessProfile: mission target, .Target.Type(%d), must be 'Dist' or 'Time'.", ...
                itarget);
            
        end
    end
end

% find the maximum mission id
MaxID = max(Mission.ID);

% check that maximum mission id is no more than the number of targets
if (MaxID > ntarget)
    error("ERROR - ProcessProfile: a mission id (.ID) is %d, but there's only %d mission targets", ...
          MaxID, ntarget);
      
end

% check that all mission id are positive
if (any(Mission.ID < 1))
    error("ERROR - ProcessProfile: all mission id (.ID) must be integers greater than or equal to 1");
end


%% CHECK/PROCESS THE ALTITUDES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check for non-negative beginning altitudes
if (any(Mission.AltBeg < -EPS06))
    error("ERROR - ProcessProfile: all beginning altitudes (.AltBeg) must be non-negative.");
end

% check for non-negative ending altitudes
if (any(Mission.AltEnd < -EPS06))
    error("ERROR - ProcessProfile: all ending altitudes (.AltEnd) must be non-negative.");
end

% get the number of beginning altitudes
[nAltBeg, ncols] = size(Mission.AltBeg);

% check that beginning altitudes are in a column vector
if (ncols > 1)
    error("ERROR - ProcessProfile: beginning altitudes (.AltBeg) must be given in a column vector.");  
end

% get the number of ending altitudes
[nAltEnd, ncols] = size(Mission.AltEnd);

% check that ending altitudes are in a column vector
if (ncols > 1)
    error("ERROR - ProcessProfile: ending altitudes (.AltEnd) must be given in a column vector.");
end

% check for same number of beginning/ending altitudes
if (nAltBeg ~= nAltEnd)
    error("ERROR - ProcessProfile: different number of beginning (%d) and ending (%d) altitudes. Check .AltBeg and .AltEnd.", ...
           nAltBeg, nAltEnd);
       
end


%% CHECK/PROCESS THE AIRSPEEDS AND THEIR TYPES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% regardless of unit, beginning airspeeds must be non-negative
if (any(Mission.VelBeg < -EPS06))
    error("ERROR - ProcessProfile: all beginning airspeeds (.VelBeg) must be non-negative.");
end

% regardless of unit, ending airspeeds must be non-negative
if (any(Mission.VelEnd < -EPS06))
    error("ERROR - ProcessProfile: all ending airspeeds (.VelEnd) must be non-negative.");
end

% get the number of beginning airspeeds
[nVelBeg, ncols] = size(Mission.VelBeg);

% check that the beginning airspeeds are in a column vector
if (ncols > 1)
    error("ERROR - ProcessProfile: all beginning airspeeds (.VelBeg) must be in a column vector.");
end

% get the number of ending airspeeds
[nVelEnd, ncols] = size(Mission.VelEnd);

% check that the ending airspeeds are in a column vector
if (ncols > 1)
    error("ERROR - ProcessProfile: all ending airspeeds (.VelEnd) must be in a column vector.");
end

% check for same number of beginning/ending airspeeds
if (nVelBeg ~= nVelEnd)
    error("ERROR - ProcessProfile: different number of beginning (%d) and ending (%d) airspeeds. Check .VelBeg and .VelEnd", ...
           nVelBeg, nVelEnd);
       
end

% get the number of beginning airspeed types
[nTypeBeg, ncols] = size(Mission.TypeBeg);

% check that the beginning types are in a column vector
if (ncols > 1)
    error("ERROR - ProcessProfile: all beginning airspeed types (.TypeBeg) must be in a column vector.");
end

% get the number of ending airspeed types
[nTypeEnd, ncols] = size(Mission.TypeEnd);

% check that the ending types are in a column vector
if (ncols > 1)
    error("ERROR - ProcessProfile: all ending airspeed types (.TypeEnd) must be in a column vector.");
end

% check for same number of beginning/ending airspeeds
if (nTypeBeg ~= nTypeEnd)
    error("ERROR - ProcessProfile: different number of beginning (%d) and ending (%d) airspeed types. Check .TypeBeg and .TypeEnd", ...
          nTypeBeg, nTypeEnd);
      
end

% loop through each beginning and ending type
for itype = 1:nTypeBeg
    
    % check for a valid beginning type
    if ((strcmp(Mission.TypeBeg(itype), "TAS" ) == 0) && ...
        (strcmp(Mission.TypeBeg(itype), "EAS" ) == 0) && ...
        (strcmp(Mission.TypeBeg(itype), "Mach") == 0) )
    
        % return error
        error("ERROR - ProcessProfile: beginning airspeed type %d must be 'TAS', 'EAS', or 'Mach'.", ...
              itype);
          
    end
    
    % check for a valid ending type
    if ((strcmp(Mission.TypeEnd(itype), "TAS" ) == 0) && ...
        (strcmp(Mission.TypeEnd(itype), "EAS" ) == 0) && ...
        (strcmp(Mission.TypeEnd(itype), "Mach") == 0) )
    
        % return error
        error("ERROR - ProcessProfile: ending airspeed type %d must be 'TAS', 'EAS', or 'Mach'.", ...
              itype);
        
    end
end

% check for the available rates of climb
[nrocs, ncols] = size(Mission.ClbRate);

% check that the climb rates are in a column vector
if (ncols > 1)
    error("ERROR - ProcessProfile: all climb rates (.ClbRate) must be in a column vector.");
end

% check that all climb rates are specified (even if they're NaN)
if (nrocs ~= nsegs)
    error("ERROR - ProcessProfile: there must be %d climb rates (including NaNs), but only %d are specified.", ...
          nsegs, nrocs);
end


%% UPDATE THE STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember the endpoints of each segment and the number of points in it
Mission.SegBeg = SegBeg;
Mission.SegEnd = SegEnd;
Mission.SegPts = SegPts;

% re-populate the mission profile
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end