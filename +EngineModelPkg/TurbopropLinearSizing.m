function [SizedEngine] = TurbopropLinearSizing(EngSpecFunc)
%
% [SizedEngine] = TurbopropLinearSizing(EngSpecFunc)
% Written by Maxfield Arnson
% Updated 11/20/2023
%
% This function computes the thermodynamic cycle inside of a turboprop
% engine with less fidelity than the nonlinear function. This function is
% used to provide an initial guess on mass flow rate for the sizing
% iteration. it takes the same input specification file as its nonlinear
% counterpart.
% 
% INPUTS:
%
% EngSpecFun = Structure defined by a specification file created by a user
%       size: 1x1 struct
%
%
% OUTPUTS:
%
% SizedEngine = Structure describing information about the engine. The only
%           utilized output is SizedEngine.MDot0
%       size: 1x1 struct

%% Initialization
gl = 7/5; % Gamma (ratio of specific heats) at low  temperatures
gh = 4/3; % Gamma (ratio of specific heats) at high temperatures
R = 287; % [J/kgK] gas constant for air
cpl = gl*R/(gl-1); % specific heat at constant pressure at low  temps
cph = gh*R/(gh-1); % specific heat at constant pressure at high temps


%% Fuel Properties

LHV_fuel = 43.17e6; % [J/kg] lower heating value of Jet-A

%% Pull Engine Specifications

% Design Specs
M0 = EngSpecFunc.Mach;
h = EngSpecFunc.Alt;
OPR = EngSpecFunc.OPR;
Tt4 = EngSpecFunc.Tt4Max;
%Thrust = EngSpecFunc.DesignThrust;
ReqPower = EngSpecFunc.ReqPower;
NPR = EngSpecFunc.NPR;

% Efficiencies
eta1 = EngSpecFunc.EtaPoly.Inlet;
eta3 = EngSpecFunc.EtaPoly.Compressors;
eta4 = EngSpecFunc.EtaPoly.Combustor;
eta49 = EngSpecFunc.EtaPoly.Turbines;
eta7 = EngSpecFunc.EtaPoly.Turbines;
eta9 = EngSpecFunc.EtaPoly.Nozzles;



%% Station 0 (Ambient)
m2 = 1; % Normalized by itself

[Ts0,Ps0,~] = MissionSegsPkg.StdAtm(h);
Pt0 = EngineModelPkg.IsenRelPkg.Pt_Ps(Ps0,M0,gl);
Tt0 = EngineModelPkg.IsenRelPkg.Tt_Ts(Ts0,M0,gl);





%% Stations 0, (upstream), 1 a and b (Up and downstream of Prop), 19 (Downstream) 

Tt2 = Tt0;
%% Station 3 (Compressor Exit)

m3 = m2; % no leakage before extraction

Pt3 = OPR*Pt0;

% Ideal
iTt3 = Tt2*(OPR)^((gl - 1)/gl);

% Actual
Tt3 = (iTt3 - Tt2)/eta3 + Tt2;
W_comp = m3*cpl*(Tt3 - Tt2);

%% Station 3.1 (Pre Combustor)

% Air extracted to be added at 4.95 for cooling
m_leak = 0.01*m3;
m_bleed = 0.03*m3;
m_cooling= 0.06*m3;
m31 = m3 - m_leak - m_bleed - m_cooling;
Tt31 = Tt3;
Pt31 = Pt3;

%% Station 4 (Post Combustor / Pre HPT)

Pt4 = Pt31*0.95;

% assume fuel is already vaporized and at the same temp as the air

mfuel = m31*EngineModelPkg.SpecHeatPkg.CpAir(Tt31,Tt4)/(eta4*LHV_fuel - EngineModelPkg.SpecHeatPkg.CpJetA(Tt31,Tt4));
m4 = m31+mfuel;

%% Station 4.9 (Post HPT / Pre Cooling)

% HPT drives compressor
m49 = m4;
Tt49i = Tt4 - W_comp/m49/cph;
Pt49 = Pt4*(1+(Tt49i-Tt4)/Tt4/eta49)^((gh)/(gh-1));
Tt49 = Tt4 - W_comp/m49/cph/eta49;

%% Station 4.95 (Post Cooling / Pre Power Turbine)

% cooling flow added
m495 = m49 + m_cooling;

Tt495 = (m49*cph*Tt49 + m_cooling*cpl*Tt31)...
    /cph/m495;
Pt495 = Pt49*(Tt495/Tt49)^((gh)/(gh-1));

%% Station 7 (Post Power Turbine / Pre Core Exhaust)

m7 = m495;
Pt7 = Ps0;
Tt7 = Tt495*(Pt7/Pt495)^((gh-1)/gh);

SpecP = m7*cph*eta7*(Tt495 - Tt7);


%% Rescale to Desired Power

m2 = ReqPower/SpecP;
mfuel = mfuel*m2;

%% Outputs

SizedEngine.MDot0 = m2;
SizedEngine.BSFC = mfuel/ReqPower; % kg/W/s
SizedEngine.BSFC_g_kW_hr = SizedEngine.BSFC*3.6e9;
SizedEngine.m2 = m2;
SizedEngine.mfuel = mfuel;
SizedEngine.Tt7 = Tt7;

end

