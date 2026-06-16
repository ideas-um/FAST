function [Aircraft] = ConstantLD(Aircraft)
%
% [Aircraft] = ConstantLD(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 17 jun 2025
%
% estimate the lift-drag ratio with a constant L/D.
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


%% GET MACH NUMBERS %%
%%%%%%%%%%%%%%%%%%%%%%

% get the segment id
SegsID = Aircraft.Mission.Profile.SegsID;

% set number of points in the segment
npoint = Aircraft.Mission.Profile.SegPts(SegsID);

% get the beginning and ending control point indices
SegBeg = Aircraft.Mission.Profile.SegBeg(SegsID);
SegEnd = Aircraft.Mission.Profile.SegEnd(SegsID);

% get the segment type
Segment = Aircraft.Mission.History.Segment(SegBeg:SegEnd);


%% COMPUTE THE LIFT-DRAG RATIO %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% allocate memory for L/D
L_D = zeros(npoint, 1);

% check which segments are active
HasClb = strcmpi(Segment, "Climb"  ) == 1;
HasCrs = strcmpi(Segment, "Cruise" ) == 1;
HasDes = strcmpi(Segment, "Descent") == 1;

% get the respective lift-drag ratios
L_D(HasClb) = Aircraft.Specs.Aero.L_D.Clb;
L_D(HasCrs) = Aircraft.Specs.Aero.L_D.Crs;
L_D(HasDes) = Aircraft.Specs.Aero.L_D.Des;

% get the lift coefficient
CL = Aircraft.Mission.History.SI.Aero.CL(SegBeg:SegEnd);

% compute the drag coefficient
CD = CL ./ L_D;

% store results in the mission history
Aircraft.Mission.History.SI.Aero.CD( SegBeg:SegEnd) = CD ;
Aircraft.Mission.History.SI.Aero.L_D(SegBeg:SegEnd) = L_D;


end