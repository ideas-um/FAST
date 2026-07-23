function [Aircraft] = WindmillDrag(Aircraft)
%
% [Aircraft] = WindmillDrag(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 05 jan 2026
%
% estimate the windmilling drag from any failed engines.
%
% INPUTS:
%     Aircraft - data structure with the aircraft specifications and
%                mission history.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - data structure with the windmilling drag in the mission
%                history.
%                size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% get the segment id
SegsID = Aircraft.Mission.Profile.SegsID;

% get the beginning and ending control point indices
SegBeg = Aircraft.Mission.Profile.SegBeg(SegsID);
SegEnd = Aircraft.Mission.Profile.SegEnd(SegsID);

% get the number of control points
npnt = SegEnd - SegBeg + 1;

% check for windmilling engines
CurWindmill = Aircraft.Mission.History.SI.Power.Windmill(SegBeg, :);

if (~any(CurWindmill))
    
    % return an array of zeros
    D = zeros(npnt, 1);
    
    % remember the windmilling drag
    Aircraft.Mission.History.SI.Aero.Dwm(SegBeg:SegEnd) = D;
    
    % stop running this function
    return

end

% get the number of windmilling engines
[~, neng] = size(CurWindmill);

% get the scale factor for the windmilling drag
ScaleWnd = Aircraft.Specs.Aero.ScaleWnd;

% load the interpolants
Interpolants = load(fullfile("+AerodynamicsPkg", "WindmillingDrag.mat"));

% get each interpolant
TheoryCD = Interpolants.InterpTheoryCD;
DeltaCD  = Interpolants.InterpDeltaCD;

% get the flight condtions
Rho  = Aircraft.Mission.History.SI.Performance.Rho( SegBeg:SegEnd);
TAS  = Aircraft.Mission.History.SI.Performance.TAS( SegBeg:SegEnd);
Mach = Aircraft.Mission.History.SI.Performance.Mach(SegBeg:SegEnd);

% get the number of sources
nsrc = length(Aircraft.Specs.Propulsion.PropArch.SrcType);

% get the engine specifications
Ainlet    = Aircraft.Specs.Propulsion.InletArea(CurWindmill(1) - nsrc);
SLSThrust = Aircraft.Specs.Propulsion.SLSThrust(CurWindmill(1) - nsrc);


%% COMPUTE THE SLS SPECIFIC THRUST %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the mass flow rate at the inlet (SLS conditions)
mdot = 1.225 .* Ainlet .* Aircraft.Specs.Performance.Vels.Tko;

% compute the specific thrust
SpecThrust = SLSThrust ./ mdot;


%% COMPUTE THE DRAG COEFFICIENT INCREMENT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% assume a specific thrust for now
Tspec = repmat(SpecThrust, npnt, 1);

% compute the theoretical drag coefficient
ThrCD = TheoryCD(Tspec);

% compute the drag coefficient change due to mach number
DelCD = DeltaCD(Tspec, Mach);

% if there are any NaNs, convert them to zeros
ThrCD(isnan(ThrCD)) = 0;
DelCD(isnan(DelCD)) = 0;

% compute the adjusted drag coefficient
TotCD = ThrCD - DelCD;

% compute drag from all windmilling engines
D = sum(TotCD, 2) .* 0.5 .* Rho .* TAS .^ 2 .* Ainlet .* neng .* ScaleWnd;

% return the windmilling drag
Aircraft.Mission.History.SI.Aero.Dwm(SegBeg:SegEnd) = D;

% ----------------------------------------------------------

end