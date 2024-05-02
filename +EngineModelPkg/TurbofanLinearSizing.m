function [SizedEngine] = TurbofanLinearSizing(EngSpecFunc)
%
% [SizedEngine] = TurbofanLinearSizing(EngSpecFunc)
% Written by Maxfield Arnson
% Updated 10/5/2023
%
% This function computes the thermodynamic cycle inside of a turbofan
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




%% Air Properties
gl = 7/5; % Gamma (ratio of specific heats) at low  temperatures
gh = 4/3; % Gamma (ratio of specific heats) at high temperatures
R = 287; % [J/kgK] gas constant for air
cpl = gl*R/(gl-1); % specific heat at constant pressure at low  temps
cph = gh*R/(gh-1); % specific heat at constant pressure at high temps


%% Fuel Properties
rho_fuel = 800; % [kg/m3] density of Jet-A at 15C
LHV_fuel = 43.17e6; % [J/kg] lower heating value of Jet-A

%% Pull Engine Specifications

% Design Specs
M0 = EngSpecFunc.Mach;
h = EngSpecFunc.Alt;
CPR = EngSpecFunc.OPR;
BPR = EngSpecFunc.BPR;
FPR = EngSpecFunc.FPR;
Tt4 = EngSpecFunc.Tt4Max;
DesignThrust = EngSpecFunc.DesignThrust;

% Efficiencies
eta1 = EngSpecFunc.EtaPoly.Inlet;
eta2 = EngSpecFunc.EtaPoly.Fan;
eta3 = EngSpecFunc.EtaPoly.Compressors;
eta19 = EngSpecFunc.EtaPoly.BypassNozzle;
eta4 = EngSpecFunc.EtaPoly.Combustor;
eta49 = EngSpecFunc.EtaPoly.Turbines;
eta5 = EngSpecFunc.EtaPoly.Turbines;
eta9 = EngSpecFunc.EtaPoly.CoreNozzle;

%% Station 0 (Ambient)
m2 = 1; % Normalized by itself

[Ts0,Ps0,Rhos0] = MissionSegsPkg.StdAtm(h);
Pt0 = EngineModelPkg.IsenRelPkg.Pt_Ps(Ps0,M0,gl);
Tt0 = EngineModelPkg.IsenRelPkg.Tt_Ts(Ts0,M0,gl);
m0 = (1+BPR)*m2;
u0 = M0*sqrt(gl*R*Ts0);
A0 = m0/Rhos0/u0;

%% Station 1 (Inlet/Pre-Fan)

m1 = m0; % no leakage in the inlet
Pt1 = Pt0*eta1;
Tt1 = Tt0; % No heat added or lost
M1 = 0.4; % RFP

Ps1 = EngineModelPkg.IsenRelPkg.Ps_Pt(Pt1,M1,gl);
Ts1 = EngineModelPkg.IsenRelPkg.Ts_Tt(Tt1,M1,gl);
Rhos1 = Ps1/R/Ts1;

u1 = M1*sqrt(gl*R*Ts1);

A1 = m1/Rhos1/u1;

%% Station 2 (Fan Exit)

m2 = 1; % Normalized by itself
Pt2 = FPR*Pt1;

% Ideal
iTt2 = Tt1*(FPR)^(1 - 1/gl);

% Actual
Tt2 = (iTt2 - Tt1)/eta2 + Tt1;
W_fan = m2*(1+BPR)*cpl*(Tt2 - Tt1);

%% Station 13 (Bypass Inlet)

m13 = BPR*m2;
Pt13 = Pt2;
Tt13 = Tt2;

%% Station 19 (Bypass Exhaust)
m19 = m13;
Ps19 = Ps0;
Tt19 = Tt13;

Ts19i = Tt19*(Ps19/Pt13)^((gl - 1)/gl);
u19i = sqrt((Tt19 - Ts19i)*2*cpl);
u19 = u19i*eta19;
Ts19 = Tt19 - u19^2/2/cpl;

Pt19 = Ps19*(Tt19/Ts19)^(gl/(gl - 1));

%% Station 3 (Compressor Exit)

m3 = m2; % no leakage before extraction
Pt3 = CPR*Pt2;

% Ideal
iTt3 = Tt2*(CPR)^((gl - 1)/gl);

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

f = (Tt4/Tt3-1)/((eta4*LHV_fuel)/(EngineModelPkg.SpecHeatPkg.CpAir(Tt31,Tt4))-Tt4/Tt3);
m4 = m31+mfuel;

%% Station 4.9 (Post HPT / Pre Cooling)

% HPT drives compressor
m49 = m4;
Tt49i = Tt4 - W_comp/m49/cph;
Pt49 = Pt4*(1+(Tt49i-Tt4)/Tt4/eta49)^((gh)/(gh-1));
Tt49 = Tt4 - W_comp/m49/cph/eta49;

%% Station 4.95 (Post Cooling / Pre LPT)

% cooling flow added
m495 = m49 + m_cooling;

Tt495 = (m49*cph*Tt49 + m_cooling*cpl*Tt31)...
    /cph/m495;
Pt495 = Pt49*(Tt495/Tt49)^((gh)/(gh-1));

%% Station 5 (Post LPT / Pre Core Exhaust)

% LPT drives fan
m5 = m495;
Tt5i = Tt495 - W_fan/m5/cph;
% Pt51 = Pt495*(Tt5/Tt495)^(gh/(gh-1))
Pt5 = Pt495*...
    (1+(Tt5i-Tt495)/Tt495/eta5)^((gh)/(gh-1));
Tt5 = Tt495 - W_fan/m495/cph/eta5;

%% Station 9 (Core Exhaust)

m9 = m5;
Ps9 = Ps0;
Tt9 = Tt5;

Ts9i = Tt9*(Ps9/Pt5)^((gh - 1)/gh);
u9i = sqrt((Tt9 - Ts9i)*2*cph);
u9 = u9i*eta9;
Ts9 = Tt9 - u9^2/2/cph;

Pt9 = Ps9*(Tt9/Ts9)^(gh/(gh - 1));

if real(u9i^2) < 0
    warning('Energy required to turn compressor exceeds available energy within airflow. TET [K] is too low for a functioning engine.')
end
%% Rescale to Desired Thrust

SpecT = m9*u9 + m19*u19 - m0*u0;

m2 = DesignThrust/SpecT;

% Areas
A1 = A1*m2;
D1 = 2*sqrt(A1/pi);

% Mass Flows
m0   = m0  *m2;
m1   = m1  *m2;
m3   = m3  *m2;
m31  = m31 *m2;
m4   = m4  *m2;
m49  = m49 *m2;
m495 = m495*m2;
m5   = m5  *m2;
m9   = m9  *m2;
m13  = m13 *m2;
m19  = m19 *m2;
mfuel = mfuel*m2;

%% Outputs


SizedEngine.TSFC = mfuel/DesignThrust;
SizedEngine.MDot0 = m0;
SizedEngine.MFuel = mfuel;
SizedEngine.compwork = W_comp;
SizedEngine.Tt49 = Tt5;
SizedEngine.DFan = D1;
SizedEngine.wdot = m2*(1+BPR);
SizedEngine.u9 = u9;
SizedEngine.f = f;
SizedEngine.TGT_Stagnation = Tt5;

end
