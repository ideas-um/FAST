function [CDi] = InducedDrag(Aircraft)
%
% [CDi] = InducedDrag(Aircraft)
% modified by Paul Mokotoff, prmoko@umich.edu
% patterned after Aviary's "compute" method in induced_drag.py,
% translated by Cursor, an AI Code Editor
% last updated: 05 jun 2025
%
% INPUTS:
%     Aircraft - data structure with the aircraft geometry and mission
%                history.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     CDi      - induced drag coefficient.
%                size/type/units: npnt-by-1 / double / []
%


%% PARSE INPUTS %%
%%%%%%%%%%%%%%%%%%

% get the segment id
SegsID = Aircraft.Mission.Profile.SegsID;

% get the beginning and ending control point indices
SegBeg = Aircraft.Mission.Profile.SegBeg(SegsID);
SegEnd = Aircraft.Mission.Profile.SegEnd(SegsID);

% get the mach number
Mach = Aircraft.Mission.History.SI.Performance.Mach(SegBeg:SegEnd);
CL   = Aircraft.Mission.History.SI.Aero.CL(         SegBeg:SegEnd);

% get aircraft geometry
AR    = Aircraft.Specs.Aero.Wing.AR   ;
e     = Aircraft.Specs.Aero.Wing.e    ;
Sweep = Aircraft.Specs.Aero.Wing.Sweep;
TR    = Aircraft.Specs.Aero.Wing.TR   ;

% check option for extreme taper ratios
Redux = Aircraft.Specs.Aero.Wing.Redux;


%% COMPUTE THE INDUCED DRAG COEFFICIENT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check for the redux flag
if (Redux)
    
    % adjust for extreme taper ratios
    % Reference: DeYoung, John. "Advanced Supersonic Technology Concept Study Reference
    % Characteristics," NASA Contractor Report 132374.
    e0 = 1 + 0.1 * AR * (0.4226 * sqrt(AR) - 0.35 * TR - 0.143);
    
else
    
    % assume a perfect efficiency scale factor
    e0 = 1;
    
end

% modify the span efficiency factor
if (e <= 0.3)
    
    % add to the existing one
    SpanEfficiency = e0 + e;
    
else
    
    % scale the existing one
    SpanEfficiency = e0 * e;
    
end

% calculate the basic induced drag
CDi = CL .^ 2 ./ (pi * AR * SpanEfficiency);

% if forward sweep, add Warner Robins Factor
if (real(Sweep) < 0.0)
    
    % convert degrees to radians
    DegToRad = pi / 180;
    
    % compute scale factors
    TH = (1 - TR) / (1 + TR) / AR;
    TanSW = tan(Sweep / DegToRad);
    COSA = 1 / sqrt(1 + (TanSW - 3 * TH)^2);
    COSB = 1 / sqrt(1 + (TanSW + TH)^2);
    CAYT = 0.5 * ((1.1 - 0.11 / (1.1 - Mach * COSA)) / (1.1 - 0.11 / (1.1 - Mach * COSB)) - 1.0) ^ 2;
    
    % scale the induced drag coefficient
    CDi = CDi + CAYT .* CL .^ 2;
    
end


end