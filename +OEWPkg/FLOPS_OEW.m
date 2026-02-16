function [OEW] = FLOPS_OEW(Params)
%
% [OEW] = FLOPS_OEW(Params)
% written by Maxfield Arnson,
% last updated: 19 nov 2025
%
% This function calculates the OEW of the aircraft using FLOPS regressions
% it is not currently used in FAST, but it is available for reference or for use if desired.
%
% INPUTS:
%   Params - vector of input parameters
%               size/type/units: 15-by-1 / double / [see below]
%               1....Range (m) ** uncommon unit, but its what FAST uses internally
%               2....Pax (unitless)
%               3....Neng (unitless)
%               4....Thrust (N)
%               5....Wing_Area (m^2)
%               6....Fuel_Weight (kg)
%               7....Height (m)
%               8....Sweep (degrees)
%               9....Fus_Length (m)
%               10...Span (m)
%               11...Taper Ratio (unitless)
%               12...MTOW (kg)
%               13...Fan Diameter (m)
%               14...Length Engine (m)
%               15...Engine Dry Weight (kg)
%
% OUTPUTS:
%   OEW - Operating Empty Weight
%               size/type/units: 1-by-1 / double / kg



% Overall OEW Component Additions

Structs = FLOPS_Structural(Params);
Propulsion = FLOPS_Propulsion(Params);
Systems = FLOPS_Systems(Params);
Empty_Weight = Structs + Propulsion + Systems;

Ops = FLOPS_Operational(Params);

OEW = Empty_Weight + Ops;

end % OEWPkg.FLOPS.FLOPS_OEW






% ---------------------------------------------
% ------------OEW Buildup Functions------------
% ---------------------------------------------

%% Structural
function [EW] = FLOPS_Structural(Params)

% Wing Weight
Wing = Wing_Weight(Params);

% Horizontal Tail Weight
[Htail, HtailArea] = Htail_Weight(Params);

% Vertical Tail Weight
[Vtail, VtailArea] = Vtail_Weight(Params);

% Fuselage
Fuselage = Fus_Weight(Params);

% Gear
Gear = Gear_Weight(Params);

% Paint
Paint = Paint_Weight(Params, HtailArea, VtailArea);

% Nacelle
Nacelle = Nacelle_Weight(Params);

% Final Sum Up
EW = Wing + Htail + Vtail + Fuselage + Gear + Paint + Nacelle;

end

function [Htail_Weight, HtailArea] = Htail_Weight(Params)
Height = UnitConversionPkg.ConvLength(Params(7),'m','ft');
Sweep = Params(8);
Neng = Params(3);
WingArea = Params(5) * UnitConversionPkg.ConvLength(1,'m','ft')^2;
Fus_Length = UnitConversionPkg.ConvLength(Params(9),'m','ft');
Span = UnitConversionPkg.ConvLength(Params(10),'m','ft');
MTOW = UnitConversionPkg.ConvMass(Params(12),'kg','lbm');

Fus_Width = Height/3; % ASSUMPTION: Fus height is 1/3 of actual height

FlapR = 1/3;

HHT = 0; % ASSUMPTION: Body mounted tail 

M_Crs = 0.8;

NEW = abs(Neng - 3) * Neng;

VolCoeff = 56.9 * Fus_Width ^ 0.5 * FlapR^0.82 * (1 - 0.46*HHT) * (1 -0.1 * NEW)...
    / (M_Crs * Sweep);

Hfac = WingArea^2 / Span / Fus_Length;

HtailArea = VolCoeff * Hfac;

Htail_Weight = 0.53 * HtailArea * MTOW^0.20 * (0.2 + 0.5);


end

function [Vtail_Weight, VtailArea] = Vtail_Weight(Params)
Height = UnitConversionPkg.ConvLength(Params(7),'m','ft');
Sweep = Params(8);
Neng = Params(3);
WingArea = Params(5) * UnitConversionPkg.ConvLength(1,'m','ft')^2;
Fus_Length = UnitConversionPkg.ConvLength(Params(9),'m','ft');
Span = UnitConversionPkg.ConvLength(Params(10),'m','ft');
MTOW = UnitConversionPkg.ConvMass(Params(12),'kg','lbm');

Fus_Depth = Height/3; % ASSUMPTION: Fus height is 1/3 of actual height

HHT = 0; % ASSUMPTION: Body mounted tail 

M_Crs = 0.8; % ASSUMPTION: Cruise at Mach 0.8

NEF = mod(Neng,2);

VolCoeff = 0.0035 * Sweep ^ 0.57 * Fus_Depth ^ 0.5 * (1 + 0.2*HHT) * (1 + 0.33 * NEF)...
    / (M_Crs);

Vfac = WingArea * Span / Fus_Length;

VtailArea = VolCoeff * Vfac;

Vtail_Weight = 0.32 * MTOW^0.3 * (0.2 + 0.5)  * VtailArea^0.85;

end

function [Wing] = Wing_Weight(Params)
Sweep = Params(8);
WingArea = Params(5) * UnitConversionPkg.ConvLength(1,'m','ft')^2;
Span = UnitConversionPkg.ConvLength(Params(10),'m','ft');
Taper = Params(11);
AR = Span^2/WingArea;
MTOW = UnitConversionPkg.ConvMass(Params(12),'kg','lbm');
Neng = Params(3);

% W1
TLAM = tand(Sweep) - (2 - 2 * Taper)/(AR * (1 + Taper));
SLAM = TLAM / sqrt(1 + TLAM^2);
CAYA = AR - 5;
C4 = 1; % ASSUMPTION: No aeroelastic tailoring
C6 = 0; % ASSUMPTION; NO STRUTS OR AERO TAILORING
CAYL = (1 - SLAM^2) * (1 + C6 * SLAM^2 + 0.03 * CAYA * C4 * SLAM);
TCA = 0.15; % ASSUMPTION, WEIGHTED AVERAGE THICKNESS TO CHORD = 15%
EMS = 1; % ASSUMPTION: NO STRUT, EMS = 1
BT = 0.215 * (0.37 + 0.7*Taper) * (AR)^(EMS) /(CAYL*TCA); 
ULF = 3.75; % ASSUMPTION, default ultimate load factor
FCOMP = 0; % ASSUMPTION: No composites
VFACT = 1; % ASSUMPTION: No variable sweep wing
PCTL = 1; % ASSUMPTION, 85% of the lift is produced by the main wing
A = [8.8, 6.25, 0.68, 0.34, 0.6, 0.035, 1.5];
W1NIR = A(1) * BT * (1 + sqrt(A(2)/Span)) * ULF * Span * (1 - 0.4 * FCOMP)...
    * (1 - 0.1*0) * 1 * VFACT * PCTL * 1e-6;

NEW = abs(Neng - 3) * Neng;
CAYE = 1 -0.03 * NEW;
SFLAP = 0.33 * WingArea; % ASSUMPTION

W2 = A(3) * (1 - 0.17 * FCOMP) * SFLAP^A(4) * MTOW ^A(5);
W3 = A(6) * (1 - 0.3 * FCOMP) * WingArea^A(7);
W1 = (MTOW * CAYE * W1NIR + W2 + W3 ) /(1 + W1NIR) - W2 - W3;

W4 = 0; % NOT HWB

% Final Summation
Wing = W1 + W2 + W3 + W4;

end

function [Fuselage] = Fus_Weight(Params)
Height = UnitConversionPkg.ConvLength(Params(7),'m','ft');
Neng = Params(3);
Fus_Length = UnitConversionPkg.ConvLength(Params(9),'m','ft');

Fus_Diam = Height/3; % ASSUMPTION: Fus diam is 1/3 of actual height
NFUSE = 1; % ASSUMPTION 1 Fuselage
CARGF = 0; % Passenger transport, not cargo
NEF = mod(Neng,2);

Fuselage = 1.35 * (Fus_Length * Fus_Diam)^1.28 * (1 + 0.05 * NEF) ...
    * (1 + 0.38 * CARGF) * NFUSE;
end

function [Gear] = Gear_Weight(Params)
R = UnitConversionPkg.ConvLength(Params(1),'m','naut mi');
MTOW = UnitConversionPkg.ConvMass(Params(12),'kg','lbm');
DiamFan = UnitConversionPkg.ConvLength(Params(13),'m','ft');
Span = UnitConversionPkg.ConvLength(Params(10),'m','ft');
Height = UnitConversionPkg.ConvLength(Params(7),'m','ft');
Fus_Length = UnitConversionPkg.ConvLength(Params(9),'m','ft');

Fus_Diam = Height/3; % ASSUMPTION: Fus diam is 1/3 of actual height

DIH = 3; % Assumption, 3 degree dihedral
YEE = Span/2 * 0.3 * 12; 

WLDG = MTOW * (1 - 0.00004 * R); % Subsonic cruise
DFTE = 0; % 0 for transport AC
XMLG = 12 * DiamFan + (0.26 - tand(DIH)) * (YEE - 6 * Fus_Diam);
XNLG = 0.7 * XMLG;

MainGear = (0.0117 - 0.0012 * DFTE) * WLDG ^ 0.95 * XMLG ^ 0.43;
CARBAS = 0; % Land based aircraft, not carrier
NoseGear = (0.048 - 0.008 * DFTE) * WLDG ^ 0.67 * XNLG ^ 0.43 ...
    * (1 + 0.8 * CARBAS);

Gear = MainGear + NoseGear;

end

function [Nacelle] = Nacelle_Weight(Params)
Neng = Params(3);
Thrust_ea = UnitConversionPkg.ConvForce(Params(4),'N','lbf')...
    / Neng;
DiamFan = UnitConversionPkg.ConvLength(Params(13),'m','ft');
LengthEng = UnitConversionPkg.ConvLength(Params(14),'m','ft');

TNAC = Neng + 0.5 * (Neng - 2 * floor(Neng/2));

Nacelle = 0.25 * TNAC * DiamFan * LengthEng * Thrust_ea^0.36;

end

function [Paint] = Paint_Weight(Params,HtailArea,Vtail_Area)
Height = UnitConversionPkg.ConvLength(Params(7),'m','ft');
Fus_Length = UnitConversionPkg.ConvLength(Params(9),'m','ft');
DiamFan = UnitConversionPkg.ConvLength(Params(13),'m','ft');
LengthEng = UnitConversionPkg.ConvLength(Params(14),'m','ft');
WingArea = Params(5) * UnitConversionPkg.ConvLength(1,'m','ft')^2;
Neng = Params(3);

Fus_Diam = Height/3; % ASSUMPTION: Fus diam is 1/3 of actual height




% Area Density
RhoPaint = 0.03; % ASSUMPTION, 

% Wetted Areas
Wing = 2 * WingArea;
Htail = 2 * HtailArea;
Vtail = 2 * Vtail_Area;
Fuselage = pi * (Fus_Length / Fus_Diam - 1.7) * Fus_Diam^2;
Nacelle = Neng * DiamFan * pi * LengthEng;
Canard = 0; 

Paint = RhoPaint * (Wing + Htail + Vtail + Fuselage + Nacelle + Canard);

end

%% Propulsion
function [Propulsion] = FLOPS_Propulsion(Params)

Neng = Params(3);
Thrust_ea = UnitConversionPkg.ConvForce(Params(4),'N','lbf')...
    / Neng;
TNAC = Neng + 0.5 * (Neng - 2 * floor(Neng/2));
Fuel_Weight = UnitConversionPkg.ConvMass(Params(6),'kg','lbm');

Vmax = 0.85; % ASSUMPTION: max cruise speed Mach 0.85

ThrustReverser =  0.034 * Thrust_ea * TNAC; 

Controls = 0.26 * Neng * Thrust_ea ^ 0.5;
Starters = 11 * Neng * Vmax^0.32 * Neng ^ 1.8;

Misc = Controls + Starters;

FuelSystem = 1.07 * Fuel_Weight^0.58 * Neng * Vmax^0.34;

Engines =  Thrust_ea / 5.5;

Propulsion = Neng*Engines + ThrustReverser + Misc + FuelSystem;
end

%% Systems

function [Systems] = FLOPS_Systems(Params)
WingArea = Params(5) * UnitConversionPkg.ConvLength(1,'m','ft')^2;
MTOW = UnitConversionPkg.ConvMass(Params(12),'kg','lbm');
Pax = Params(2);
Height = UnitConversionPkg.ConvLength(Params(7),'m','ft');
Fus_Length = UnitConversionPkg.ConvLength(Params(9),'m','ft');
Neng = Params(3);
R = UnitConversionPkg.ConvLength(Params(1),'m','naut mi');
Sweep = Params(8);
Span = UnitConversionPkg.ConvLength(Params(10),'m','ft');
DiamFan = UnitConversionPkg.ConvLength(Params(13),'m','ft');

Fus_Diam = Height/3; % ASSUMPTION: Fus diam is 1/3 of actual height
SFLAP = 0.33 * WingArea; % ASSUMPTION
Vmax = 0.85; % ASSUMPTION: max cruise speed Mach 0.85
FPA = Fus_Diam * Fus_Length;
SurfaceControls = 1.1 * Vmax^0.52 * SFLAP^0.6 * MTOW ^ 0.32;

APU = 54 * FPA ^ 0.3 + 5.4 * Pax^0.9;

NEW = abs(Neng - 3) * Neng;
NEF = mod(Neng,2);
NCrew = 2*any(Pax(Pax < 151)) + 3*any(Pax(Pax >= 151));
Instruments = 0.48 * FPA ^ 0.57 * Vmax ^ 0.5 *...
    (10 + 2.5 * NCrew + NEW + 1.5 * NEF);

HYDPR = 3000; % Hydraulics system pressure, ASSUMPTION default value used
VARSWP = 0; % ASSUMPTION No variable sweep wings
Hydraulics = 0.57 * (FPA + 0.27 * WingArea) * (1 +0.03 * NEW + 0.05 * NEF)...
    * (3000/HYDPR) ^ 0.35 * (1 + 0.04 * VARSWP) * Vmax^0.33;

NFUSE = 1;
Electrical = 92 * Fus_Length^0.4 * Fus_Diam^0.14 * NFUSE^0.27 * Neng^0.69 *...
    (1 + 0.044 * NCrew + 0.0015 * Pax);

Avionics = 15.8 * R^0.1 * NCrew^0.7 * FPA^0.43;

SeatWeight = 78; % ASSUMPTION all first class weight

NCEN = Neng - 2 * floor(Neng/2);
Cabin_Length = Fus_Length - 40 - 25 * NCEN;

Furnishings = 127 * NCrew + Pax*SeatWeight + 2.6 * Cabin_Length * 2 * Fus_Diam * NFUSE;
% ASSUMPTION 85% length is for passengers, fus height and width = 1/3 total
% binding box height

AirConditioning = (3.2 * (FPA * Fus_Diam)^0.6 + 9 * Pax ^ 0.83) * ...
    Vmax + 0.075 * Avionics;

AntiIce = Span / cosd(Sweep) + 3.8 * DiamFan * Neng + 1.5 * Fus_Diam;

Systems = SurfaceControls + APU + Instruments + Hydraulics +...
    Electrical + Avionics + Furnishings + AirConditioning + AntiIce;

end

%% Operational

function [WOp] = FLOPS_Operational(Params) 

% Input Processing for Operational Weight
R = UnitConversionPkg.ConvLength(Params(1),'m','naut mi');
Pax = Params(2);
Neng = Params(3);
Thrust_ea = UnitConversionPkg.ConvForce(Params(4),'N','lbf')...
    / Neng;
WingArea = Params(5) * UnitConversionPkg.ConvLength(1,'m','ft')^2;
Fuel_Weight = UnitConversionPkg.ConvMass(Params(6),'kg','lbm');


% Pilots
Flight_Crew = 225 * (2*any(Pax(Pax < 151)) + 3*any(Pax(Pax >= 151)));

% Galley Crew
Galley_Crew = 200 * any(Pax(Pax >= 151)) * (1 + 1 * ceil(Pax/250));

% Flight Attendants
Stewards = 155 * (1 + ceil(Pax/40)*any(Pax(Pax>=51)));

% Unusable Fuel
Unusable_Fuel = 11.5* Neng * Thrust_ea ^ 0.2 +...
    0.07 * WingArea +...
    1.6 * 3 * Fuel_Weight ^ 0.28; % Assumption, 3 fuel tanks

% Oil
Oil = 0.082 * Neng * Thrust_ea ^ 0.65;

% Passenger Service, ASSUMPTION: Max Mach and 3.5 scaling factor.
Passenger_Service = 3.5 * Pax * (R / 0.85)^0.225;

% Cargo Containers

% Piecewise Function for per pax cargo weight
Cargo_Weight = 35* any(R(R<=950)) + 40* any(R(R > 950 && R<=2900)) + 44 * any(R(R>2900));
Cargo_Containters = 175 * ceil(Pax * Cargo_Weight/950);



% Sum it up at the end
WOp = Flight_Crew + Galley_Crew + Stewards + Unusable_Fuel +...
    Oil + Passenger_Service + Cargo_Containters; 
end