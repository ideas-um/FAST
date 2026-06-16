function [Aircraft] = DragPolar(Aircraft)
%
% [Aircraft] = DragPolar(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 05 jan 2026
%
% combine the drag coefficients into a single drag coefficient for further
% analysis. the zero-lift and lift-dependent drag coefficients are scaled
% prior to combining. sub/supersonic scale factors are are applied to the
% drag coefficients after combining into one. then, use the drag
% coefficient to compute the lift-drag ratio.
%
% INPUTS:
%     Aircraft - data structure with mission history and specifications.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - data structure with lift-drag ratio at the given flight
%                conditions.
%                size/type/units: 1-by-1 / struct / []
%


%% GET FLIGHT CONDITIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the segment id
SegsID = Aircraft.Mission.Profile.SegsID;

% get the beginning and ending control point indices
SegBeg = Aircraft.Mission.Profile.SegBeg(SegsID);
SegEnd = Aircraft.Mission.Profile.SegEnd(SegsID);

% get the flight conditions
Rho  = Aircraft.Mission.History.SI.Performance.Rho( SegBeg:SegEnd);
TAS  = Aircraft.Mission.History.SI.Performance.TAS( SegBeg:SegEnd);
Mach = Aircraft.Mission.History.SI.Performance.Mach(SegBeg:SegEnd);

% get the lift coefficient
CL = Aircraft.Mission.History.SI.Aero.CL(SegBeg:SegEnd);


%% COMPUTE CD %%
%%%%%%%%%%%%%%%%

% import the scale factors
ScaleCD0 = Aircraft.Specs.Aero.ScaleCD0;
ScaleCDI = Aircraft.Specs.Aero.ScaleCDI;
ScaleSub = Aircraft.Specs.Aero.ScaleSub;
ScaleSup = Aircraft.Specs.Aero.ScaleSup;

% compute the drag components
CD_SkinFric = AerodynamicsPkg.SkinFrictionDrag(Aircraft);
CD_Compress = AerodynamicsPkg.CompressibilityDrag(Aircraft);
CD_Pressure = AerodynamicsPkg.LiftDependentDrag(Aircraft);
CD_Induced  = AerodynamicsPkg.InducedDrag(Aircraft);

% compute the windmilling drag
Aircraft = AerodynamicsPkg.WindmillDrag(Aircraft);

% check for nonzero windmilling drag
Dwm = Aircraft.Mission.History.SI.Aero.Dwm(SegBeg:SegEnd);

% compute the drag coefficient contribution from the windmilling drag
if (any(Dwm))
    
    % get the wing area
    S = Aircraft.Specs.Aero.S;
    
    % compute the drag coefficient contribution
    CD_Windmilling = Dwm ./ (0.5 .* Rho .* TAS .^ 2 .* S);
    
else
    
    % return 0
    CD_Windmilling = 0;
    
end

% compute the trim drag
CD_Trim = AerodynamicsPkg.TrimDrag(Aircraft);

% compute CD0 (zero-lift drag coefficient)
CD0 = CD_SkinFric + CD_Compress + CD_Windmilling + CD_Trim;

% compute CDI (lift-dependent drag coefficient)
CDI = CD_Pressure + CD_Induced;

% compute the pre-scaled drag coefficients
PrescaleCD = CD0 .* ScaleCD0 + CDI .* ScaleCDI;

% index the supersonic ones
IdxSup = Mach > 1;

% scale all by the subsonic factor
CD = PrescaleCD .* ScaleSub;

% scale supersonic ones by its respective factor
CD(IdxSup) = CD(IdxSup) .* ScaleSup;

% store it in the mission history
Aircraft.Mission.History.SI.Aero.CD(SegBeg:SegEnd) = CD;


%% COMPUTE THE LIFT-DRAG RATIO %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the lift-drag ratio
L_D = CL ./ CD;

% store it in the mission history
Aircraft.Mission.History.SI.Aero.L_D(SegBeg:SegEnd) = L_D;


end