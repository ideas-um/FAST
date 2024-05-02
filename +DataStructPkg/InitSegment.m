function [Aircraft, ielem] = InitSegment(Aircraft, Segment, SegsID)
%
% [Aircraft, ielem] = InitSegment(Aircraft, Segment, SegsID)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 mar 2024
%
% At the beginning of each segment, check to see if there is a prior
% mission history. If so, overwrite data at the last point (shared by
% previous and current segment) and allocate memory for all points in the
% upcoming segment. If not, initialize the arrays to contain 0s for the
% respective number of control points in the upcoming segment
%
% INPUTS:
%     Aircraft - aircraft structure to access the mission history and
%                settings to get the number of control points in the
%                segment.
%                size/type/units: 1-by-1 / struct / []
%
%     Segment  - the current segment being flown, either:
%                    a) takeoff
%                    b) climb
%                    c) cruise
%                    d) descent
%                    e) landing
%                size/type/units: 1-by-1 / string / []
%
%     SegsID   - segment ID associated with the segment being flown.
%                size/type/units: 1-by-1 / int / []
%
% OUTPUTS:
%     Aircraft - updated structure with more memory allocated.
%                size/type/units: 1-by-1 / struct / []
%
%     ielem    - index of array element to start writing to for the segment
%                that will be flown.
%                size/type/units: 1-by-1 / int / []
%


%% SETUP %%
%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get number of points in    %
% the segment                %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% find the appropriate segment
if     (strcmpi(Segment, "takeoff") == 1)
    
    % get number of points in takeoff
    npnt = Aircraft.Settings.TkoPoints;
    
elseif (strcmpi(Segment, "climb"  ) == 1)
    
    % get number of points in climb
    npnt = Aircraft.Settings.ClbPoints;
    
elseif (strcmpi(Segment, "cruise" ) == 1)
   
    % get number of points in cruise
    npnt = Aircraft.Settings.CrsPoints;
    
elseif (strcmpi(Segment, "descent") == 1)
    
    % get number of points in descent
    npnt = Aircraft.Settings.DesPoints;
    
elseif (strcmpi(Segment, "landing") == 1)
    
    % only two points at landing
    npnt = 2;
    
else
    
    % throw error
    error("ERROR - InitSegment: invalid segment being flown. Must be 'takeoff', 'climb', 'cruise', 'descent', or 'landing'.");
    
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check if this is the first %
% segment                    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if the array is empty
if (isempty(Aircraft.Mission.History.SI.Performance.Time))
    
    % filling empty array - start writing at beginning
    ielem = 1;
    
else
    
    % check if the first segment is being flown
    if (SegsID == 1)
        
        % get the array's current length - start writing at next element
        ielem = length(Aircraft.Mission.History.SI.Performance.Time) + 1;
        
    else
        
        % get the array's current length - start writing at last element
        ielem = length(Aircraft.Mission.History.SI.Performance.Time)    ;
        
        % previous/current segment share a point, allocate one fewer point
        npnt = npnt - 1;
        
    end    
end


%% ALLOCATE ADDITIONAL MEMORY %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% append array of zeros      %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% add 'npnt' extra spaces in memory
ExtraSpace = zeros(npnt, 1);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% aircraft performance data  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% shorthand to access performance data
Perf = Aircraft.Mission.History.SI.Performance;

% time flown
Perf.Time = [Perf.Time; ExtraSpace];

% distance flown
Perf.Dist = [Perf.Dist; ExtraSpace];

% true/equivalent airspeed as a function of time
Perf.TAS = [Perf.TAS; ExtraSpace];
Perf.EAS = [Perf.EAS; ExtraSpace];

% rate of climb as a function of time
Perf.RC = [Perf.RC; ExtraSpace];

% altitude as a function of time
Perf.Alt = [Perf.Alt; ExtraSpace];

% acceleration as a function of time
Perf.Acc = [Perf.Acc; ExtraSpace];

% flight path angle as a function of time
Perf.FPA = [Perf.FPA; ExtraSpace];

% mach number as a function of time
Perf.Mach = [Perf.Mach; ExtraSpace];

% densirty as a function of time
Perf.Rho = [Perf.Rho; ExtraSpace];

% return newly allocated arrays to the structure
Aircraft.Mission.History.SI.Performance = Perf;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% propulsion data            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% shorthand to acccess propulsion data
Prop = Aircraft.Mission.History.SI.Propulsion;

% thrust as a function of time
Prop.Treq = [Prop.Treq; ExtraSpace];

% thermal (gas turbine) efficiency as a function of time
Prop.Eta = [Prop.Eta; ExtraSpace];

% thrust-specific fuel consumption as a function of time
Prop.TSFC = [Prop.TSFC; ExtraSpace];

% fuel flow as a function of time
Prop.MDotFuel = [Prop.MDotFuel; ExtraSpace];

% return newly allocated arrays to the structure
Aircraft.Mission.History.SI.Propulsion = Prop;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% aircraft weights           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% shorthand to access weight data
Weight = Aircraft.Mission.History.SI.Weight;

% aircraft weights as a function of time
Weight.CurWeight = [Weight.CurWeight; ExtraSpace];
Weight.Fburn     = [Weight.Fburn    ; ExtraSpace];

% return newly allocated arrays to the structure
Aircraft.Mission.History.SI.Weight = Weight;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% power quantities           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% shorthand to access power data
Power = Aircraft.Mission.History.SI.Power;

% aircraft power as a function of time
Power.Av   = [Power.Av  ; ExtraSpace];
Power.Req  = [Power.Req ; ExtraSpace];
Power.Out  = [Power.Out ; ExtraSpace];
Power.Fuel = [Power.Fuel; ExtraSpace];
Power.Batt = [Power.Batt; ExtraSpace];
Power.EM   = [Power.EM  ; ExtraSpace];
Power.EG   = [Power.EG  ; ExtraSpace];
Power.Prop = [Power.Prop; ExtraSpace];

% power split as a function of time
Power.Phi = [Power.Phi; ExtraSpace];

% state of charge as a function of time
Power.SOC = [Power.SOC; ExtraSpace];

% return newly allocated arrays to the structure
Aircraft.Mission.History.SI.Power = Power;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% energy quantities          %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% shorthand to access energy data
Energy = Aircraft.Mission.History.SI.Energy;

% aircraft energy as a function of time
Energy.KE   = [Energy.KE  ; ExtraSpace];
Energy.PE   = [Energy.PE  ; ExtraSpace];
Energy.Fuel = [Energy.Fuel; ExtraSpace];
Energy.Batt = [Energy.Batt; ExtraSpace];

% return newly allocated arrays to the structure
Aircraft.Mission.History.SI.Energy = Energy;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% current mission segment    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% shorthand to access the data
MissSeg = Aircraft.Mission.History.Segment;

% define array for strings representing the segment
CurSeg = repmat("", npnt, 1);

% allocate the memory
MissSeg = [MissSeg; CurSeg];

% retun newly allocated array
Aircraft.Mission.History.Segment = MissSeg;
    
% ----------------------------------------------------------

end