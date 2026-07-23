function [CDcomp] = CompressibilityDrag(Aircraft)
%
% [CDcomp] = CompressibilityDrag(Aircraft)
% modified by Paul Mokotoff, prmoko@umich.edu
% patterned after Aviary's "compute" method in compressibility_drag.py,
% translated by Cursor, an AI Code Editor
% last updated: 05 jun 2025
%
% compute the compressibility drag coefficient.
%
% INPUTS:
%     Aircraft - data structure with the aircraft geometry and mission
%                history.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     CDcomp   - compressibility drag coefficient.
%                size/type/units: 1-by-1 / double / []
%


%% GET MACH NUMBERS %%
%%%%%%%%%%%%%%%%%%%%%%

% get the segment id
SegsID = Aircraft.Mission.Profile.SegsID;

% get the beginning and ending control point indices
SegBeg = Aircraft.Mission.Profile.SegBeg(SegsID);
SegEnd = Aircraft.Mission.Profile.SegEnd(SegsID);

% get the mach number from the mission
Mach = Aircraft.Mission.History.SI.Performance.Mach(SegBeg:SegEnd);

% get the design mach number
DesignMach = Aircraft.Specs.Aero.DesignMach;


%% COMPUTE THE COMPRESSIBILITY DRAG COEFFICIENT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% gather interpolation tables
[PCWtable, BSUBtable, PCARtable, BSUPtable, WFItable] = InitializeTables();

% calculate mach number difference relative to the design mach number
DelMach = Mach - DesignMach;

% find indices for supersonic and subsonic regions
IdxSuper = find(DelMach >  0.05);
IdxSub   = find(DelMach <= 0.05);

% initialize output array
CDcomp = zeros(size(Mach));

% calculate drag for supersonic regions if any exist
if (~isempty(IdxSuper))
    CDcomp(IdxSuper) = ComputeSupersonic(Aircraft, Mach, IdxSuper, PCARtable, BSUPtable, WFItable);
end

% calculate drag for subsonic regions if any exist
if (~isempty(IdxSub))
    CDcomp(IdxSub) = ComputeSubsonic(Aircraft, Mach, IdxSub, PCWtable, BSUBtable);
end


end

% ----------------------------------------------------------
% ----------------------------------------------------------
% ----------------------------------------------------------

function [CDcomp] = ComputeSupersonic(Aircraft, Mach, Idx, PCAR, BSUP, WFI)
%
% [CDcomp] = ComputeSupersonic(Aircraft, Mach, Idx, PCAR, BSUP, WFI)
% modified by Paul Mokotoff, prmoko@umich.edu
% patterned after Aviary's "_compute_supersonic" method in
% compressibility_drag.py, translated by Cursor, an AI Code Editor
% last updated: 06 jun 2025
%
% compute the compressibility drag coefficient in supersonic regions.
%
% INPUTS:
%     Aircraft - data structure with the aircraft geometry.
%                size/type/units: 1-by-1 / struct / []
%
%     Mach     - mach number as a function of time in the mission history.
%                size/type/units: npnt-by-1 / double / []
%
%     Idx      - indices of points in the supersonic regime.
%                size/type/units: mpnt-by-1 / struct / []
%
%     PCAR     - griddedInterpolant for compressibility drag coefficient.
%                size/type/units: 1-by-1 / griddedInterpolant / []
%
%     BSUP     - griddedInterpolant for fuselage supersonic effects.
%                size/type/units: 1-by-1 / griddedInterpolant / []
%
%     WFI      - griddedInterpolant for wing-fuselage interactions.
%                size/type/units: 1-by-1 / griddedInterpolant / []
%
% OUTPUTS:
%     CDcomp   - computed compressibility drag coefficient.
%                size/type/units: mpnt-by-1 / array / []
%


%% PARSE INPUTS %%
%%%%%%%%%%%%%%%%%%

% get the supersonic mach numbers
SupMach = Mach(Idx);

% get the design mach number
DesignMach = Aircraft.Specs.Aero.DesignMach;

% get the wing geometry
AR       = Aircraft.Specs.Aero.Wing.AR;
TC       = Aircraft.Specs.Aero.Wing.t_c;
MaxCam   = Aircraft.Specs.Aero.Wing.MaxCamber;
Sweep    = Aircraft.Specs.Aero.Wing.Sweep;
TR       = Aircraft.Specs.Aero.Wing.TR;
WingArea = Aircraft.Specs.Aero.Wing.S * UnitConversionPkg.ConvLength(1, "m", "ft") ^ 2;

% get the fuselage geometry
FuseArea      = Aircraft.Specs.Aero.Fuse.Area * UnitConversionPkg.ConvLength(1, "m", "ft") ^ 2;
FuseLen_Diam  = Aircraft.Specs.Aero.Fuse.Len_Diam;
FuseDiam_Span = Aircraft.Specs.Aero.Fuse.Diam_Span;

% get the base area
BaseArea = Aircraft.Specs.Aero.BaseArea * UnitConversionPkg.ConvLength(1, "m", "ft") ^ 2;


%% COMPUTE THE COEFFICIENT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the number of points
mpnt = length(SupMach);

% compute the mach number difference
DelMach = SupMach - DesignMach;

% modify the aspect ratio
ART = AR * tan(Sweep / 57.2958) + (1 - TR) / (1 + TR);

% prepare interpolation points
X = zeros(mpnt, 2);
X(:, 1) = DelMach;
X(:, 2) = ART;

% interpolate CD3
CD3 = PCAR(X);

% change negative values to 0
CD3(CD3 <= 0) = 0;

% calculate compressibility drag coefficient
CDcomp = CD3 .* (TC ^ (5/3) * (1 + 0.1 * MaxCam));

% contribution of fuselage
if (FuseArea > 0)
    
    % compute a scale factor
    SOS = 1 + BaseArea / FuseArea;
    
    % remember the interpolation points
    X(:, 1) = SupMach;
    X(:, 2) = SOS;
    
    % interpolate CD4
    CD4 = BSUP(X);
    
    % any negative values are reset to 0
    CD4(CD4 <= 0) = 0;
    
    % calculate fuselage compressibility drag
    FuselageCompressDragCoeff = CD4 .* (FuseArea / WingArea * (1 / FuseLen_Diam ^ 2));
    
    % update the compressibility drag coefficient
    CDcomp = CDcomp + FuselageCompressDragCoeff;
    
    % get the span ratio
    X(:, 2) = FuseDiam_Span;
    
    % interpolate CD5
    CD5 = WFI(X);
    
    % if the taper ratio is 1, change it (special case)
    if (TR == 1)
        TR = 0.5;
    end
    
    % calculate interference drag
    IntCompressDragCoeff = CD5 .* (1 / (1 - TR) / cos(Sweep / 57.2958));
    
    % add the interference drag to the compressibility drag
    CDcomp = CDcomp + IntCompressDragCoeff;
    
end


end

% ----------------------------------------------------------
% ----------------------------------------------------------
% ----------------------------------------------------------

function [CDcomp] = ComputeSubsonic(Aircraft, Mach, Idx, PCW, BSUB)
%
% [CDcomp] = ComputeSubsonic(Aircraft, Mach, Idx, PCWtable, BSUBtable)
% modified by Paul Mokotoff, prmoko@umich.edu
% patterned after Aviary's "_compute_subsonic" method in
% compressibility_drag.py, translated by Cursor, an AI Code Editor
% last updated: 06 jun 2025
%
% compute the compressibility drag coefficient in subsonic regions.
%
% INPUTS:
%     Aircraft - data structure with the aircraft geometry.
%                size/type/units: 1-by-1 / struct / []
%
%     Mach     - mach numbers from the mission history.
%                size/type/units: npnt-by-1 / double / []
%
%     Idx      - indices of points in the subsonic regime.
%                size/type/units: mpnt-by-1 / struct / []
%
%     PCW      - griddedInterpolant for compressibility drag coefficient.
%                size/type/units: 1-by-1 / griddedInterpolant / []
%
%     BSUB     - griddedInterpolant for fuselage subsonic effects.
%                size/type/units: 1-by-1 / griddedInterpolant / []
%
% OUTPUTS:
%     CDcomp   - computed compressibility drag coefficient.
%                size/type/units: mpnt-by-1 / array / []
%


%% PARSE INPUTS %%
%%%%%%%%%%%%%%%%%%

% get the subsonic mach numbers
SubMach = Mach(Idx);

% get the wing geometry
TC       = Aircraft.Specs.Aero.Wing.t_c;
MaxCam   = Aircraft.Specs.Aero.Wing.MaxCamber;
WingArea = Aircraft.Specs.Aero.Wing.S * UnitConversionPkg.ConvLength(1, "m", "ft") ^ 2;

% get the fuselage geometry
FuseArea     = Aircraft.Specs.Aero.Fuse.Area * UnitConversionPkg.ConvLength(1, "m", "ft") ^ 2;
FuseLen_Diam = Aircraft.Specs.Aero.Fuse.Len_Diam;

% get the base area
BaseArea = Aircraft.Specs.Aero.BaseArea * UnitConversionPkg.ConvLength(1, "m", "ft") ^ 2;

% get the design mach number
DesignMach = Aircraft.Specs.Aero.DesignMach;


%% COMPUTE THE SUBSONIC CONTRIBUTIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the number of points
mpnt = length(SubMach);

% compute the mach number difference
DelMach = SubMach - DesignMach;

% scale thickness to chord
TOC = TC ^ (2 / 3);

% prepare interpolation points
X = zeros(mpnt, 2);
X(:, 1) = DelMach;
X(:, 2) = TOC;

% interpolate CD1
CD1 = PCW(X);

% reset negative values to 0
CD1(CD1 <= 0) = 0;

% calculate compressibility drag coefficient
CDcomp = CD1 .* (TC ^ (5 / 3) * (1 + 0.1 * MaxCam));

% check if the fuselage contributes
if (FuseArea > 0)
    
    % compute a scale factor
    SOS = 1 + BaseArea / FuseArea;
    
    % prepare for interpolation
    X(:, 1) = SubMach;
    X(:, 2) = SOS;
    
    % interpolate CD2
    CD2 = BSUB(X);
    
    % reset negative values to 0
    CD2(CD2 <= 0) = 0;
    
    % calculate fuselage compressibility drag
    FuselageCompressDragCoeff = CD2 .* (FuseArea / WingArea * (1 / FuseLen_Diam ^ 2));
    
    % account for the fuselage contribution
    CDcomp = CDcomp + FuselageCompressDragCoeff;

end


end

% ----------------------------------------------------------
% ----------------------------------------------------------
% ----------------------------------------------------------

function [PCWtable, BSUBtable, PCARtable, BSUPtable, WFITable] = InitializeTables()
%
% [PCWtable, BSUBtable, PCARtable, BSUPtable, WFITable] = InitializeTables()
% modified by Paul Mokotoff, prmoko@umich.edu
% patterned after Aviary's tables in compressibility_drag.py, translated by
% Cursor, an AI Code Editor
% last updated: 27 may 2025
%
% setup griddedInterpolants for computing transonic impacts of flying.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     PCWtable  - table for pressure coefficient on the wing.
%                 size/type/units: 1-by-1 / griddedIntrerpolant / []
%
%     BSUBtable - table for base subsonic conditions.
%                 size/type/units: 1-by-1 / griddedIntrerpolant / []
%
%     PCARtable - table for pressure coefficient due to aspect ratio.
%                 size/type/units: 1-by-1 / griddedIntrerpolant / []
%
%     BSUPtable - table for base supersonic conditions.
%                 size/type/units: 1-by-1 / griddedIntrerpolant / []
%
%     WFItable  - table for wing-fuselage interactions.
%                 size/type/units: 1-by-1 / griddedIntrerpolant / []
%


%% SETUP THE TABLES %%
%%%%%%%%%%%%%%%%%%%%%%

% PCW table (Pressure Coefficient Wing)
PCW = [
    13007.0, 0.100, 0.120, 0.140, 0.160, 0.180, 0.220, 0.300;
    -0.800, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00;
    -0.200, 0.0600, 0.040, 0.020, 0.0200, 0.0100, 0.0080, 0.0020;
    -0.160, 0.0720, 0.050, 0.030, 0.0260, 0.0170, 0.0160, 0.0060;
    -0.120, 0.1000, 0.060, 0.040, 0.0380, 0.0250, 0.0240, 0.0120;
    -0.080, 0.1250, 0.080, 0.050, 0.0490, 0.0350, 0.0330, 0.0190;
    -0.040, 0.1600, 0.120, 0.080, 0.0680, 0.0540, 0.0470, 0.0300;
    -0.020, 0.2000, 0.160, 0.120, 0.1100, 0.0700, 0.0590, 0.0390;
    0.000, 0.2800, 0.220, 0.160, 0.1200, 0.0930, 0.0770, 0.0520;
    0.010, 0.3400, 0.270, 0.200, 0.1520, 0.1180, 0.0930, 0.0610;
    0.020, 0.4400, 0.330, 0.240, 0.1970, 0.1530, 0.1170, 0.0730;
    0.030, 0.6400, 0.450, 0.310, 0.2550, 0.2030, 0.1480, 0.0870;
    0.040, 1.1000, 0.660, 0.410, 0.3250, 0.2700, 0.1870, 0.1030;
    0.050, 1.9000, 1.020, 0.560, 0.4000, 0.3500, 0.2350, 0.1270
];

% BSUB table (Base Subsonic)
BSUB = [
    17004.0, 1.00, 1.20, 1.40, 1.50;
    0.2000, 0.00, 0.00, 0.00, 0.00;
    0.5000, 0.00, 0.00, 0.00, 0.00;
    0.7000, 0.00, 0.00, 0.00, 0.00;
    0.7800, 0.00, 0.00, 0.00, 0.00;
    0.8200, 0.00, 0.00, 0.150, 0.210;
    0.8400, 0.00, 0.150, 0.200, 0.350;
    0.8600, 0.090, 0.220, 0.400, 0.520;
    0.8800, 0.200, 0.380, 0.610, 0.780;
    0.9000, 0.380, 0.580, 0.910, 1.100;
    0.9100, 0.530, 0.750, 1.100, 1.330;
    0.9200, 0.730, 0.950, 1.300, 1.600;
    0.9300, 0.950, 1.200, 1.650, 1.930;
    0.9400, 1.300, 1.550, 2.050, 2.490;
    0.9500, 1.750, 2.200, 2.900, 3.650;
    0.9600, 2.450, 3.250, 4.500, 6.400;
    0.9650, 3.000, 4.220, 6.300, 8.450;
    0.9700, 3.900, 5.600, 9.500, 11.500
];

% PCAR table (Pressure Coefficient Aspect Ratio)
PCAR = [
    16009.0, 1.00, 1.50, 2.00, 2.50, 3.00, 3.50, 4.00, 5.00, 6.00;
    0.050, 2.400, 1.700, 1.170, 0.850, 0.730, 0.670, 0.600, 0.540, 0.520;
    0.070, 3.100, 2.250, 1.580, 1.100, 0.890, 0.770, 0.700, 0.620, 0.600;
    0.090, 3.550, 2.610, 1.880, 1.240, 0.990, 0.870, 0.750, 0.670, 0.650;
    0.110, 3.850, 2.880, 2.030, 1.330, 1.070, 0.920, 0.800, 0.710, 0.680;
    0.130, 3.970, 3.050, 2.140, 1.410, 1.120, 0.960, 0.840, 0.740, 0.710;
    0.150, 4.000, 3.100, 2.170, 1.480, 1.160, 0.990, 0.860, 0.750, 0.720;
    0.200, 3.900, 3.000, 2.200, 1.550, 1.200, 1.000, 0.860, 0.740, 0.700;
    0.250, 3.680, 2.850, 2.160, 1.570, 1.200, 1.000, 0.830, 0.700, 0.650;
    0.300, 3.430, 2.700, 2.100, 1.550, 1.170, 0.920, 0.770, 0.630, 0.580;
    0.400, 3.030, 2.450, 1.900, 1.470, 1.100, 0.880, 0.730, 0.590, 0.530;
    0.500, 2.750, 2.220, 1.710, 1.370, 1.020, 0.840, 0.730, 0.570, 0.520;
    0.600, 2.490, 2.000, 1.550, 1.260, 0.970, 0.810, 0.740, 0.560, 0.510;
    0.700, 2.250, 1.800, 1.410, 1.170, 0.910, 0.790, 0.710, 0.550, 0.510;
    0.800, 1.990, 1.620, 1.300, 1.100, 0.880, 0.750, 0.700, 0.550, 0.500;
    0.900, 1.800, 1.500, 1.200, 1.000, 0.840, 0.700, 0.660, 0.540, 0.500;
    1.000, 1.650, 1.400, 1.100, 0.950, 0.800, 0.700, 0.660, 0.540, 0.500
];

% BSUP table (Base Supersonic)
BSUP = [
    14006.0, 1.00, 1.10, 1.20, 1.30, 1.40, 1.50;
    1.000, 24.50, 20.00, 16.20, 13.40, 11.10, 9.50;
    1.050, 30.70, 23.60, 20.00, 16.00, 12.90, 10.50;
    1.100, 33.00, 26.20, 21.50, 17.40, 14.00, 11.10;
    1.150, 34.30, 27.30, 22.30, 18.20, 14.80, 11.60;
    1.200, 34.70, 27.70, 22.50, 18.50, 15.00, 11.90;
    1.250, 34.50, 27.50, 22.40, 18.20, 14.90, 11.90;
    1.300, 33.80, 27.00, 22.00, 17.60, 14.50, 11.70;
    1.350, 32.90, 26.40, 21.70, 17.30, 14.20, 11.40;
    1.400, 32.40, 25.90, 21.40, 17.20, 14.10, 11.00;
    1.500, 32.00, 25.60, 21.10, 17.00, 14.10, 10.90;
    1.600, 32.00, 25.60, 21.00, 17.00, 14.10, 10.90;
    1.800, 32.00, 25.60, 21.00, 17.00, 14.20, 11.40;
    2.000, 32.00, 25.60, 21.00, 17.10, 14.40, 11.80;
    2.200, 32.00, 25.60, 21.00, 17.30, 14.60, 12.00
];

% WFI table (Wing Fuselage Interference)
WFI = [
    13010.0, 0.10, 0.120, 0.140, 0.150, 0.160, 0.170, 0.180, 0.190, 0.200, 0.220;
    1.000, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0;
    1.050, 0.0, 0.0, 0.00040, -0.00030, -0.00080, -0.00110, -0.00100, -0.00040, 0.00030, 0.00180;
    1.100, 0.0, 0.0, 0.00060, -0.00060, -0.00140, -0.00180, -0.00140, -0.00060, 0.00040, 0.00260;
    1.150, 0.0, 0.0, 0.00030, -0.00080, -0.00170, -0.00200, -0.00150, -0.00060, 0.00040, 0.00240;
    1.200, 0.0, 0.0, 0.00020, -0.00080, -0.00170, -0.00180, -0.00140, -0.00060, 0.00030, 0.00200;
    1.300, 0.0, 0.0, 0.00020, -0.00060, -0.00100, -0.00100, -0.00080, -0.00050, 0.00010, 0.00120;
    1.400, 0.0, 0.0, 0.00010, -0.00030, -0.00030, -0.00030, -0.00020, -0.00010, 0.00030, 0.00090;
    1.500, 0.0, 0.0, 0.00010, 0.00000, 0.00030, 0.00030, 0.00040, 0.00040, 0.00050, 0.00070;
    1.600, 0.0, 0.0, 0.00000, 0.00040, 0.00050, 0.00090, 0.00090, 0.00080, 0.00070, 0.00050;
    1.700, 0.0, 0.0, 0.00000, 0.00050, 0.00070, 0.00120, 0.00110, 0.00100, 0.00080, 0.00050;
    1.800, 0.0, 0.0, 0.00000, 0.00060, 0.00090, 0.00120, 0.00110, 0.00100, 0.00080, 0.00050;
    1.900, 0.0, 0.0, 0.00000, 0.00060, 0.00090, 0.00100, 0.00100, 0.00090, 0.00080, 0.00050;
    2.000, 0.0, 0.0, 0.00000, 0.00050, 0.00090, 0.00110, 0.00100, 0.00090, 0.00070, 0.00050
];


%% SETUP THE INTERPOLANTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% extract coordinates
PCW_x      = PCW(2:end, 1    );
PCW_y      = PCW(1    , 2:end);
PCW_values = PCW(2:end, 2:end);

% setup the interpolant
PCWtable = griddedInterpolant({PCW_x, PCW_y}, PCW_values, 'linear', 'linear');

% extract coordinates
BSUB_x      = BSUB(2:end, 1    );
BSUB_y      = BSUB(1    , 2:end);
BSUB_values = BSUB(2:end, 2:end);

% setup the interpolant
BSUBtable = griddedInterpolant({BSUB_x, BSUB_y}, BSUB_values, 'linear', 'linear');

% extract coordinates
PCAR_x      = PCAR(2:end, 1    );
PCAR_y      = PCAR(1    , 2:end);
PCAR_values = PCAR(2:end, 2:end);

% setup the interpolant
PCARtable = griddedInterpolant({PCAR_x, PCAR_y}, PCAR_values, 'linear', 'linear');

% extract coordinates
BSUP_x      = BSUP(2:end, 1    );
BSUP_y      = BSUP(1    , 2:end);
BSUP_values = BSUP(2:end, 2:end);

% setup the interpolant
BSUPtable = griddedInterpolant({BSUP_x, BSUP_y}, BSUP_values, 'linear', 'linear');

% extract coordinates
WFI_x      = WFI(2:end, 1    );
WFI_y      = WFI(1    , 2:end);
WFI_values = WFI(2:end, 2:end);

% setup the interpolant
WFITable = griddedInterpolant({WFI_x, WFI_y}, WFI_values, 'linear', 'linear');


end