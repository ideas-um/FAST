function [Aircraft, MissionHistory] = Main(InputAircraft, ProfileFxn)
%
% [Aircraft, MissionHistory] = Main(InputAircraft, ProfileFxn)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 06 may 2024
%
% NOTE: please see README.m in the root directory for all
%       disclaimers and how to run FAST.
%
% Perform on- and off-design analysis for a user-requested aircraft
% configuration by flying a user-requested mission profile.
%
% INPUTS:
%     InputAircraft  - function handle for the aircraft to be sized or an 
%                      already existing aircraft struct. Since all aircraft
%                      are in the "AircraftSpecsPkg" folder, the function
%                      handle must be provided as
%                      "AircraftSpecsPkg.MyAircraft", where "MyAircraft" is
%                      the .m file in the "AircraftSpecsPkg" folder
%                      describing the aircraft's configuration.
%                      size/type/units: 1-by-1 / struct or function handle / []
%
%     ProfileFxn     - function handle for the mission profile to be flown.
%                      These typically reside in the "MissionProfilesPkg"
%                      folder.
%                      size/type/units: 1-by-1 / function handle / []
%
% OUTPUTS:
%     Aircraft       - a structure containing information about the
%                      aircraft after it has been sized and the mission
%                      profile that it flew during the analysis process.
%                      size/type/units: 1-by-1 / struct / []
%
%     MissionHistory - a (possibly empty) table with the mission history
%                      after the aircraft flies the prescribed mission
%                      profile.
%                      size/type/units: 1-by-1 or 0-by-0 / table / []
%


%% USER-SPECIFIED AIRCRAFT CONFIGURATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initial cleanup
%clc, 
close all

% call user-specified input aircraft
Aircraft = InputAircraft;

% call pre-specprocessing, it will fill in unspecified fields with NaNs if the user forgets one
Aircraft = DataStructPkg.PreSpecProcessing(Aircraft);

% check that an analysis type was provided
if (isnan(Aircraft.Settings.Analysis.Type))
    
    % assume on-design
    warning("WARNING - Main: Analysis type not provided. Assuming on-design (+1).");
    
    % set analysis type to be on-design
    Aircraft.Settings.Analysis.Type = +1;
    
end

% if on-design, use regressions/projections to obtain more knowledge about the aircraft
if (Aircraft.Settings.Analysis.Type > 0)
    Aircraft = DataStructPkg.SpecProcessing(Aircraft);
end

% create the propulsion architecture
Aircraft = PropulsionPkg.CreatePropArch(Aircraft);

% identify any parallel connections (for propulsion analysis)
Aircraft = PropulsionPkg.PropArchConnections(Aircraft);


%% USER-SPECIFIED MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch nargin
    case 1
        warning("A user-specified mission was not provided. As a default, FAST will use a notional mission parameterized by the input aircraft specifications. Proceed (Y/N)?")
        doc MissionProfilesPkg.NotionalMission00
        proceedvar = input("",'s');
    if strcmpi(proceedvar,"y")
        ProfileFxn = @MissionProfilesPkg.NotionalMission00;
    else
        warning("Aircraft analysis canceled. For more information on specific mission profiles, please see documentation on the MissionProfilesPkg.")
        doc MissionProfilesPkg.README
        return;
    end
end

% call the respective mission profile function
Aircraft = ProfileFxn(Aircraft);

% process the mission profile
Aircraft = MissionSegsPkg.ProcessProfile(Aircraft);


%% AIRCRAFT ANALYSIS %%
%%%%%%%%%%%%%%%%%%%%%%%

% set the analysis type, done from the aircraft specifications function
%    +1: on -design analysis
%    -1: off-design analysis
Type = Aircraft.Settings.Analysis.Type;

% maximum number of sizing iterations, done from the AircraftSpecsPkg file
MaxIter = Aircraft.Settings.Analysis.MaxIter;

% check if power optimization settings are available
if (isfield(Aircraft, "PowerOpt") == 1)

    % call the optimization routine
    Aircraft = OptimizationPkg.DesOptimize(Aircraft);
     
else
    
    % analyze the aircraft without any optimization
    Aircraft = EAPAnalysis(Aircraft, Type, MaxIter);
    
end


%% MISSION PROFILE PLOTTING %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% plot the results, if desired (if 1, generate plots; if 0, no plotting)
if (Aircraft.Settings.Plotting == 1)
    PlotPkg.PlotMission(Aircraft);
end

% assign mission profile to sized aircraft structure so it can be
% referenced in retrofitting
Aircraft.Mission.ProfileFxn = ProfileFxn;

% ----------------------------------------------------------

%% MISSION HISTORY TABLE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if a second output argument exists
if ((nargout > 1) && (Aircraft.Settings.Table == 0))
    
    % warn the user that an empty table is returned
    warning("WARNING - Main: two output arguments were provided, but Aircraft.Settings.Table is 0. An empty table will be returned. Set Aircraft.Settings.Table to 1 for a table to be returned.");
    
end

% check if a table should be made
if (Aircraft.Settings.Table == 1)
    
    % make the table
    MissionHistory = MissionHistTable(Aircraft);
    
else
    
    % return an empty table
    MissionHistory = table();
    
end

% ----------------------------------------------------------
end