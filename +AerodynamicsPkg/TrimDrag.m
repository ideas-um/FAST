function [dCD0] = TrimDrag(Aircraft)
%
% [dCD0] = TrimDrag(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 08 jan 2026
%
% estimate the trim drag from any failed engines.
%
% INPUTS:
%     Aircraft - data structure with the aircraft specifications and
%                mission history.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     dCD0     - parasite drag increment from trim drag.
%                size/type/units: n-by-1 / double / []
%


%% CHECK FOR WINDMILLING DRAG BEFORE PROCEEDING %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the segment id
SegsID = Aircraft.Mission.Profile.SegsID;

% get the beginning and ending control point indices
SegBeg = Aircraft.Mission.Profile.SegBeg(SegsID);
SegEnd = Aircraft.Mission.Profile.SegEnd(SegsID);

% get the windmilling drag
Dwm = Aircraft.Mission.History.SI.Aero.Dwm(SegBeg:SegEnd);

% check for windmilling drag
if (~any(Dwm))
    
    % get the number of control points
    npnt = SegEnd - SegBeg + 1;
    
    % return an array of zeros
    dCD0 = zeros(npnt, 1);

    % exit the program
    return
    
end


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% get the SLS thrust
Tsls = Aircraft.Specs.Propulsion.Engine.DesignThrust;

% get the moment arm between the fuselage and most outboard engine
Arm = Aircraft.Specs.Aero.Fuse.DistToEng;

% get vertical tail specifications
TAF = Aircraft.Specs.Aero.Vtail.TAF;
Eta = Aircraft.Specs.Aero.Vtail.Eta;
ARv = Aircraft.Specs.Aero.Vtail.AR;
ev  = Aircraft.Specs.Aero.Vtail.e;
Sv  = Aircraft.Specs.Aero.Vtail.S;

% get wing specifications
ARw = Aircraft.Specs.Aero.Wing.AR;
Sw  = Aircraft.Specs.Aero.Wing.S;

% get rudder specifications
Sr = Aircraft.Specs.Aero.Rudder.S;
br = Aircraft.Specs.Aero.Rudder.b;

% get the moment arm between the wing and vertical tail
% (distance between MACs)
lv = Aircraft.Specs.Aero.Vtail.VArm;

% compute the wingspan and vertical tailspan
bw = sqrt(ARw * Sw);
bv = sqrt(ARv * Sv / 2);

% get the density and airspeed
Rho = Aircraft.Mission.History.SI.Performance.Rho(SegBeg:SegEnd);
TAS = Aircraft.Mission.History.SI.Performance.TAS(SegBeg:SegEnd);

% compute the dynamic pressure
q = 0.5 .* Rho .* TAS .^ 2;


%% COMPUTE THE PARASITE DRAG INCREMENT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
% compute the required yaw moment from the vertical tail
Nv = (Tsls + Dwm) * Arm;

% compute the yaw moment coefficent
Cn = Nv ./ (q * Sw * bw);

% compute the vertical tail pitch airfoil derivative
Clav = 2 * pi * TAF;

% compute the vertical tail stability derivative (per degree)
CLav = Clav / (1 + Clav / (pi * ARv * ev)) * pi / 180;

% compute the flapped area fraction
Frac = Sr / Sv;

% compute the flap effectiveness parameter
Tau = FlapEffectiveness(Frac);

% compute the moment coefficient for the rudder
CnDeltar = Eta * lv * Sv / (Sw * bw) * CLav * Tau;

% compute the rudder deflection
Deltar = Cn / CnDeltar;

% compute the parasite drag
dCD0 = 0.0023 * br / bv * Deltar;

% ----------------------------------------------------------

end

% ----------------------------------------------------------
% ----------------------------------------------------------
% ----------------------------------------------------------

function [Tau] = FlapEffectiveness(Frac)
%
% [Tau] = FlapEffectiveness(Frac)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 02 jan 2026
%
% compute the flap effectiveness parameter for a given control surface area
% to lifting surface area ratio. interpolation table adopted from Nelson's
% Flight Stability and Automatic Control (Fig. 2.21).
%
% INPUTS:
%     Frac - fraction lifting surface area that is comprised of the control
%            surface area.
%            size/type/units: m-by-n / double / []
%
% OUTPUTS:
%     Tau  - flap effectiveness.
%            size/type/units: m-by-n / double / []
%

% interpolation data
x = [0.0000, 0.0250, 0.0500, 0.1000, 0.1500, 0.2000, 0.2500, 0.3000, 0.3500, 0.4000, 0.4500, 0.5000, 0.5500, 0.6000, 0.6500, 0.7000];
y = [0.0000, 0.0780, 0.1510, 0.2594, 0.3411, 0.4119, 0.4748, 0.5267, 0.5748, 0.6178, 0.6579, 0.6941, 0.7312, 0.7614, 0.7906, 0.8000];

% interpolate (table lookup)
Tau = interp1(x, y, Frac);

end