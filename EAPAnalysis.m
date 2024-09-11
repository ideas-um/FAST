function [Aircraft] = EAPAnalysis(Aircraft, Type, MaxIter)
%
% [Aircraft] = EAPAnalysis(Aircraft, Type, MaxIter)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 05 jun 2024
%
% For a given aircraft, either:
%
%     (1) perform sizing (an on-design analysis) by iterating over its
%     MTOW, block fuel, battery weight, electric generator weight, and
%     electric motor weight.
%
%     (2) assess its performance (an off-design analysis) by flying a
%     specified mission consisting of takeoff, climb, and cruise segments.
%
% INPUTS:
%     Aircraft - aircraft structure for aircraft to be analyzed.
%                size/type/units: 1-by-1 / struct / []
%
%     Type     - analysis type, which can be either:
%                    a) +1, on -design analysis (sizing + performance).
%                    b) -1, off-design analysis (         performance).
%                size/type/units: 1-by-1 / int / []
%
%     MaxIter  - maximum iterations during sizing.
%                size/type/units: 1-by-1 / int / []
%
% OUTPUTS:
%     Aircraft - updated aircraft structure.
%                size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING AND SETUP %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check inputs               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% assume on-design analysis
if (nargin < 2)
    Type = +1;
end

% assume 50 iterations
if (nargin < 3)
    MaxIter = 50;
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get info from the aircraft %
% structure                  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check for fuel and batteries
Fuel = Aircraft.Specs.Propulsion.PropArch.ESType == 1;
Batt = Aircraft.Specs.Propulsion.PropArch.ESType == 0;

% initial weights
MTOW  = Aircraft.Specs.Weight.MTOW;
Wfuel = Aircraft.Specs.Weight.Fuel;
Wbatt = Aircraft.Specs.Weight.Batt;

% get the wing loading
W_S = Aircraft.Specs.Aero.W_S.SLS;

% check for battery cells in series/parallel
SerCells = Aircraft.Specs.Power.Battery.SerCells;
ParCells = Aircraft.Specs.Power.Battery.ParCells;

% if there are cells in series/parallel, use a detailed battery model
if ((~isnan(SerCells)) && (~isnan(ParCells)))
    
    % flag the detailed battery model
    Aircraft.Settings.DetailedBatt = 1;
    
else
    
    % no detailed battery model needed
    Aircraft.Settings.DetailedBatt = 0;
    
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% weights setup              %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% throw an error if maximum takeoff weight isn't a number
if (isnan(MTOW))
    error("ERROR - EAPAnalysis: MTOW is NaN."); 
end

% if fuel weight is not a number, assume none is carried
if (isnan(Wfuel))
    Wfuel = zeros(1, max(1, sum(Fuel)));
end

% if battery weight is not a number, assume none is carried
if (isnan(Wbatt))
    Wbatt = zeros(1, max(1, sum(Batt)));
end

% throw an error if wing loading isn't a number
if (isnan(W_S))
    error("ERROR - EAPAnalysis: Wing loading is NaN");
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% geometry/visualization     %
% setup                      %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calculate initial wing area
S = MTOW / W_S;

% input it back into aircraft structure
Aircraft.Specs.Aero.S = S;

% check if the aircraft should be visualized
if (Aircraft.Settings.VisualizeAircraft == 1) && (Aircraft.Settings.Analysis.Type ~= -2)

    % store a nominal wing area (used for scaling geometry up/down)
    Snominal = S;

    % use value prescribed in aircraft specification
    LengthNominal = UnitConversionPkg.ConvLength(Aircraft.Geometry.LengthSet,'m','ft');

    % call geometry with reference num being 1 for nominal
    Aircraft = VisualizationPkg.GeometryDriver(Aircraft, 1, 1, LengthNominal);

end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% iteration setup            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% assume the sizing converges
Aircraft.Settings.Converged = 1;

% define convergence tolerance
EPS = 1.0e-3;

% iteration counter
iter = 0;


%% SIZE THE AIRCRAFT %%
%%%%%%%%%%%%%%%%%%%%%%%

% Initialize new MTOW if off-design
if Type < 0
    Aircraft.Specs.Weight.MTOW = ...
        Aircraft.Specs.Weight.OEW   +...
        Aircraft.Specs.Weight.Crew   +...
        Aircraft.Specs.Weight.Payload   +...
        Aircraft.Specs.Weight.Fuel   +...
        Aircraft.Specs.Weight.Batt;
end

% initialize the mission history
Aircraft = DataStructPkg.InitMissionHistory(Aircraft);

% print initial size
fprintf(1, "Initial Size:          \n"                                                    );
fprintf(1, "    MTOW  = %.6e lbm   \n",     UnitConversionPkg.ConvMass(MTOW , "kg", "lbm"));
fprintf(1, "    Wbatt = %.6e lbm   \n",     UnitConversionPkg.ConvMass(Wbatt, "kg", "lbm"));
fprintf(1, "    Wfuel = %.6e lbm   \n",     UnitConversionPkg.ConvMass(Wfuel, "kg", "lbm"));
fprintf(1, "    S     = %.6e ft^2\n\n", S * UnitConversionPkg.ConvLength(1, "m", "ft") ^ 2);

% iterate until convergence
while (iter < MaxIter)
           
    % clear mission history and/or size the aircraft after first iteration
    if (iter > 0)
        
        % iterate on OEW for on-design only
        if (Type > 0)
            Aircraft = OEWPkg.OEWIteration(Aircraft);
        end
        
        % clear arrays from the mission analysis
        Aircraft = DataStructPkg.ClearMission(Aircraft);

        if (Aircraft.Settings.VisualizeAircraft == 1)

            % calculate scale factor for the geometry
            SF = Aircraft.Specs.Aero.S / Snominal;
            
            % visualize geometry for updated aircraft size
            Aircraft = VisualizationPkg.GeometryDriver(Aircraft, 0, SF, LengthNominal);

        end
        
    else
        
        % get the initial propulsion system weight
        Aircraft = PropulsionPkg.PropulsionSizing(Aircraft);
        
    end
    
    % get the updated MTOW
    MTOW = Aircraft.Specs.Weight.MTOW;

    % fly the mission
    Aircraft = MissionSegsPkg.FlyMission(Aircraft);
            
    % get fuel burn
    Fburn = Aircraft.Mission.History.SI.Weight.Fburn(end);
    
    % compute the fuel burn weight changes
    dWfuel = Fburn - Wfuel;
        
    % check if a retrofit is being performed (fixed battery weight)
    if (Type == -2)
        
        % fixed battery weight
        dWbatt = 0;
        
    else
        
        % resize the battery for power and energy
        Aircraft = BatteryPkg.ResizeBattery(Aircraft);
        
        % find the difference between the new and old battery weight
        dWbatt = Aircraft.Specs.Weight.Batt - Wbatt;
            
    end
    
    % update mtow
    mtow_new = MTOW + dWfuel + sum(dWbatt);
    dmtow = mtow_new - MTOW;
    
    % assess convergence (relative tolerance/error)
    fuel_conv = abs(dWfuel) ./ Wfuel;
    batt_conv = abs(dWbatt) ./ Wbatt;
    mtow_conv = abs(dmtow ) ./ MTOW ;
    
    % check for NaN (i.e. there's no component in the system
    if (any(isnan(fuel_conv)))
        fuel_conv(isnan(fuel_conv)) = 0;
    end
    
    if (any(isnan(batt_conv)))
        batt_conv(isnan(batt_conv)) = 0;
    end
    
    % update component weights
    Wfuel = Wfuel + dWfuel;
    Wbatt = Wbatt + dWbatt;
    Wpax  = Aircraft.Specs.Weight.Payload;
    Wcrew = Aircraft.Specs.Weight.Crew;
    
    % remember the new weights
    Aircraft.Specs.Weight.MTOW = mtow_new;
    Aircraft.Specs.Weight.Fuel = Wfuel;
    Aircraft.Specs.Weight.Batt = Wbatt;

    % compute the OEW when sizing
    if (Type > -2)
        Aircraft.Specs.Weight.OEW  = mtow_new - sum(Wfuel) - sum(Wbatt) - Wpax - Wcrew;
    end
    
    % remember the OEW and wing area
    OEW = Aircraft.Specs.Weight.OEW;
    S   = Aircraft.Specs.Aero.S;

    % get the electric components' weights
    Wem = Aircraft.Specs.Weight.EM;
    Weg = Aircraft.Specs.Weight.EG;
    
    % print iteration result (in english units)
    fprintf(1, "Iteration %2d:\n"         , iter                                                 );
    fprintf(1, "    MTOW  = %.6e lbm   \n", UnitConversionPkg.ConvMass(mtow_new, "kg", "lbm")    );
    fprintf(1, "    OEW   = %.6e lbm   \n", UnitConversionPkg.ConvMass(OEW     , "kg", "lbm")    );
    fprintf(1, "    Wbatt = %.6e lbm   \n", UnitConversionPkg.ConvMass(Wbatt   , "kg", "lbm")    );
    fprintf(1, "    Wfuel = %.6e lbm   \n", UnitConversionPkg.ConvMass(Wfuel   , "kg", "lbm")    );
    fprintf(1, "    Wem   = %.6e lbm   \n", UnitConversionPkg.ConvMass(Wem     , "kg", "lbm")    );
    fprintf(1, "    Weg   = %.6e lbm   \n", UnitConversionPkg.ConvMass(Weg     , "kg", "lbm")    );
    fprintf(1, "    S     = %.6e ft^2\n\n", S * UnitConversionPkg.ConvLength(1 , "m" , "ft" ) ^ 2);
    
    % iterate
    iter = iter + 1;
    
    % if first iteration and sizing, need to run OEW iteration
    if ((iter == 1) && (Type > 0))
        continue;
    end
    
    % check if energy source weights have converged
    if ((~any(fuel_conv > EPS)) && ...
        (~any(batt_conv > EPS)) && ...
        (~any(mtow_conv > EPS))  )
        break;
    end 
end

% print warning if maximum iterations reached
if ((iter == MaxIter) && (Type > 0))
    
    % print a warning
    warning('WARNING - EAPAnalysis: maximum number of sizing iterations reached.');
    
    % show that it didn't converge
    Aircraft.Settings.Converged = 0;
    
end


%% DELETE UNNECESSARY VARIABLES FROM THE STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% length of the aircraft
if (isfield(Aircraft, "LengthSet"))
    Aircraft = rmfield(Aircraft, "LengthSet");
end

% geometry configuration
if (isfield(Aircraft, "Preset"))
    Aircraft = rmfield(Aircraft, "Preset");
end

% reference geometry
if (isfield(Aircraft, "RefParts"))
    Aircraft = rmfield(Aircraft, "RefParts");
end
   
% scaled geometry
if (isfield(Aircraft, "TempParts"))
    Aircraft = rmfield(Aircraft, "TempParts");
end

% ----------------------------------------------------------

end