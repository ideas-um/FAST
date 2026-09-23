function [Aircraft] = DesOptimize(Aircraft)
%
% [Aircraft] = DesOptimize(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 mar 2024
%
% Energy/Power/Thrust split optimization package driver.
%
% INPUTS:
%     Aircraft   - structure containing aircraft specifications, mission
%                  history, and information about which objective function
%                  should be optimized.
%                  size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft   - structure with the optimized energy/power/thrust splits.
%                  size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% process the powertrain     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember how many inputs each split has
nargTS   = Aircraft.Settings.nargTS  ;
nargTSPS = Aircraft.Settings.nargTSPS;
nargPSPS = Aircraft.Settings.nargPSPS;
nargPSES = Aircraft.Settings.nargPSES;

% get the number of thrust sources
[SumTS, ~] = size(Aircraft.Specs.Propulsion.PropArch.TSPS);

% get sum of components in each row (number of components "driving")
SumTSPS = sum( Aircraft.Specs.Propulsion.PropArch.TSPS, 2);
SumPSPS = sum( Aircraft.Specs.Propulsion.PropArch.PSPS, 2);
SumPSES = sum( Aircraft.Specs.Propulsion.PropArch.PSES, 2);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check which splits are to  %
% be optimized               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the optimization sub-structure
Opt = Aircraft.PowerOpt;

% check thrust operation splits
OptDesnTS   = OptimizationPkg.CheckFlag(Opt.Settings, "DesnTS"  );
OptOperTS   = OptimizationPkg.CheckFlag(Opt.Settings, "OperTS"  );

% check thrust-power splits
OptDesnTSPS = OptimizationPkg.CheckFlag(Opt.Settings, "DesnTSPS");
OptOperTSPS = OptimizationPkg.CheckFlag(Opt.Settings, "OperTSPS");

% check power-power splits
OptDesnPSPS = OptimizationPkg.CheckFlag(Opt.Settings, "DesnPSPS");
OptOperPSPS = OptimizationPkg.CheckFlag(Opt.Settings, "OperPSPS");

% check power-energy
OptDesnPSES = OptimizationPkg.CheckFlag(Opt.Settings, "DesnPSES");
OptOperPSES = OptimizationPkg.CheckFlag(Opt.Settings, "OperPSES");

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check if the splits can be %
% optimized                  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check that the thrust splits can be optimized
if (((OptDesnTS  == 1) || (OptOperTS   == 1)) && (nargTS   < 1))
    
    % throw an error
    error("ERROR - DesOptimize: TS   splits are to be optimized, but there are no parameters input.");
        
end

% check that the driven power splits can be optimized
if (((OptDesnTSPS == 1) || (OptOperTSPS == 1)) && (nargTSPS < 1))
    
    % throw an error
    error("ERROR - DesOptimize: TSPS splits are to be optimized, but there are no parameters input.");
    
end

% check that the driving power splits can be optimized
if (((OptDesnPSPS == 1) || (OptOperPSPS == 1)) && (nargPSPS < 1))
    
    % throw an error
    error("ERROR - DesOptimize: PSPS splits are to be optimized, but there are no parameters input.");
    
end

% check that the energy splits can be optimized
if (((OptDesnPSES == 1) || (OptOperPSES == 1)) && (nargPSES < 1))
    
    % throw an error
    error("ERROR - DesOptimize: PSES splits are to be optimized, but there are no parameters input.");

end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check if there are enough  %
% components in the          %
% powertrain to optimize the %
% desired splits             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check that the thrust splits can be optimized, if desired
if (((OptDesnTS   == 1) || (OptOperTS   == 1)) && (     SumTS  < 2  ))
    
    % throw an error
    error("ERROR - DesOptimize: TS splits are to be optimized, but there is only one thrust source.");
    
end

% check that the driven power splits can be optimized, if desired
if (((OptDesnTSPS == 1) || (OptOperTSPS == 1)) && (~any(SumTSPS > 1)))
    
    % throw an error
    error("ERROR - DesOptimize: TSPS splits are to be optimized, but there is only one component in each row.");
    
end

% check that the driving power splits can be optimized, if desired
if (((OptDesnPSPS == 1) || (OptOperPSPS == 1)) && (~any(SumPSPS > 1)))
    
    % throw an error
    error("ERROR - DesOptimize: PSPS splits are to be optimized, but there is only one component in each row.");
    
end
 
% check that the energy splits can be optimized, if desired
if (((OptDesnPSES == 1) || (OptOperPSES == 1)) && (~any(SumPSES > 1)))
    
    % throw an error
    error("ERROR - DesOptimize: PSES splits are to be optimized, but there is only one component in each row.");
    
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% count the number of        %
% operational splits         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if operational splits are needed
if ((OptOperTS   == 1) || (OptOperTSPS == 1) || ...
    (OptOperPSPS == 1) || (OptOperPSES == 1)  )

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % count the number of        %
    % splits to be optimized     %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % set counter for the operational splits
    nsplit = 0;

    % check for the thrust splits
    if (OptOperTS   == 1)
        nsplit = nsplit + nargTS  ;
    end

    % check for driven power splits
    if (OptOperTSPS == 1)
        nsplit = nsplit + nargTSPS;
    end

    % check for driving power splits
    if (OptOperPSPS == 1)
        nsplit = nsplit + nargPSPS;
    end

    % check for energy splits
    if (OptOperPSES == 1)
        nsplit = nsplit + nargPSES;
    end
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % find the segments to be    %
    % optimized in the mission   %
    % profile                    %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % check for segments to optimize in the mission profile
    if (~isfield(Aircraft.Mission.Profile, "PowerOpt"))
        
        % throw an error
        error("ERROR - DesOptimize: operational splits are to be optimized, but there is no specification of which segments should be optimized.");
        
    end
    
    % shorthand to access the mission profile
    Mission = Aircraft.Mission.Profile;
    
    % get the segments to optimize
    SegOpt = find(Mission.PowerOpt);
            
    % number of segments
    nsegs = length(SegOpt);
    
    % count the mission/control points to optimize
    npoint = 0;
    nmissn = 0;
    
    % loop through the segments
    for isegs = 1:nsegs
        
        % get the number of control points to optimize
        npoint = npoint + Mission.PowerOpt(SegOpt(isegs));
        
        % get the number of mission points to optimize
        nmissn = nmissn + Mission.SegPts(SegOpt(isegs)) - 1;
        
    end
    
    % remember the number of control points optimized
    Aircraft.PowerOpt.npoint = npoint;
    
    % remember the number of operational splits
    Aircraft.PowerOpt.nopers = nsplit * npoint;
        
    % allocate memory to remember the mission points and splits
    SegIndex = zeros(nmissn, 1);
    LamIndex = zeros(nmissn, 1);
    
    % keep a running count of the indices stored
    ivar = 1;
    ilam = 1;
    
    % assign splits from control points to mission points (linear spacing)
    for isegs = 1:nsegs
        
        % initial/final segment index
        ibeg = Mission.SegBeg(SegOpt(isegs));
        iend = Mission.SegEnd(SegOpt(isegs));
        
        % number of points in the segment
        npnt = Mission.SegPts(SegOpt(isegs));
        
        % number of control points
        nctrl = Mission.PowerOpt(SegOpt(isegs));
        
        % find where the mission/control points are placed (linear spacing)
        xpnt  = linspace(0, 1 - (1 / (npnt  - 1) ), npnt  - 1);
        xctrl = linspace(0, 1 - (1 /  nctrl      ), nctrl    );
        
        % get the final index (ignoring last point with -1)
        jvar = ivar + (iend - ibeg) - 1;
        
        % array of indices
        indx = ivar:jvar;
        
        % store the indices
        SegIndex(indx) = (ibeg:iend-1)';
        
        % find the correct split to use
        for ictrl = 1:nctrl
            
            % find the correct index
            indx = find(xpnt >= xctrl(ictrl));
            
            % remember the split index
            LamIndex(indx + ivar - 1) = ilam;
            
            % account for the control point
            ilam = ilam + 1;
            
        end
        
        % update the index for the next run (add one for next index)
        ivar = jvar + 1;
        
    end
    
    % remember the indices
    Aircraft.PowerOpt.SegIndex = repmat(SegIndex, nsplit, 1);
    Aircraft.PowerOpt.LamIndex = repmat(LamIndex, nsplit, 1);
    
else
    
    % no operational splits
    Aircraft.PowerOpt.npoint = 0;
    Aircraft.PowerOpt.nopers = 0;
    
    % no mission/control points needed
    Aircraft.PowerOpt.SegIndex = [];
    Aircraft.PowerOpt.LamIndex = [];
    
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% count the number of        %
% design splits              %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set counter for the operational splits
nsplit = 0;

% check for the thrust splits
if (OptDesnTS   == 1)
    nsplit = nsplit + nargTS  ;
end

% check for driven power splits
if (OptDesnTSPS == 1)
    nsplit = nsplit + nargTSPS;
end

% check for driving power splits
if (OptDesnPSPS == 1)
    nsplit = nsplit + nargPSPS;
end

% check for energy splits
if (OptDesnPSES == 1)
    nsplit = nsplit + nargPSES;
end

% remember the number of design splits
Aircraft.PowerOpt.ndesns = nsplit;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% count the total number of  %
% splits being optimized     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the number of design and operational splits
ndesns = Aircraft.PowerOpt.ndesns;
nopers = Aircraft.PowerOpt.nopers;

% compute the total number of design variables
ndvars = ndesns + nopers;

% remember the total number of design variables
Aircraft.PowerOpt.ndvars = ndvars;


%% OPTIMIZE THE SPLITS %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% start by assuming splits of 0
Splits = zeros(ndvars, 1);

% remember the aircraft output
Aircraft.PowerOpt.Results.FlownAC = [];

% time the process
tic;

% call the optimizer
[xopt, fopt, SplitHist, fhist, optim, feas, Aircraft] = ...
OptimizationPkg.InteriorPoint(@(x, NeedGrad) ...
OptimizationPkg.ObjPowerManagement(x, NeedGrad, Aircraft), ...
Splits, @OptimizationPkg.ConSizeOpt);

% stop the process
OptTime = toc;


%% STORE THE RESULTS %%
%%%%%%%%%%%%%%%%%%%%%%%

% stop the process
Aircraft.PowerOpt.WallTime = OptTime;

% scale objectives
if     (strcmpi(Aircraft.PowerOpt.ObjFun, "Energy"  ) == 1)
    
    % rescale the objective by the conventional LM100J energy expended
    fopt = fopt * 7.4335e+11;
    
elseif (strcmpi(Aircraft.PowerOpt.ObjFun, "FuelBurn") == 1)
    
    % rescale the objective by the conventional LM100J fuel burn
    fopt = fopt * 17207;
    
end

% remember the objective and design parameters
Aircraft.PowerOpt.Results.ObjFunVal = fopt;
Aircraft.PowerOpt.Results.OptParams = xopt;

% return the optimality and feasibility
Aircraft.PowerOpt.Results.Optimality = optim;
Aircraft.PowerOpt.Results.Feasiblity = feas ;

% remember the optimization history
Aircraft.PowerOpt.Results.ParamHist = SplitHist;
Aircraft.PowerOpt.Results.ObjFnHist =     fhist;

% ----------------------------------------------------------

end