function [State39,MDotFuel,f] = Burner(State31,Tt4Max,LHVFuel,EtaPoly)
%
% [State39,MDotFuel,f] = Burner(State31,Tt4Max,LHVFuel,EtaPoly)
% Written by Maxfield Arnson
% Updated 10/9/2023
%
% This function computes the change in the airflow properties across the
% combustion chamber. It models the primary flow with heat addition until a
% desired temperature is reached.
%
%
% INPUTS:
%
% State31 = Post bleed, post cooling extraction state of the air in the
%           engine. State includes parameters like mass flow rate, temperatures, 
%           pressures, specific heats, etc.
%       size: 1x1 struct
%
% Tt4Max = maximum total temperature the air in the primary combustion zone
%           is raised to
%       size: scalar double
%
% LHVFuel = ratio of specific heats
%       size: scalar double
%
% EtaPoly = structure containing various efficiencies for the engine.
%           The burner stage uses EtaPoly.Combustor
%       size: 1x1 struct
%
%
% OUTPUTS:
%
% State39 = flow state post combustion. Mimics the format of the inputted
%           state
%       size: 1x1 struct
%
% MDotFuel = mass flow rate of fuel required for combustion
%       size: scalar double
%
% f = fuel to air ratio in combustor
%       size: scalar double


%% Initialization
% State 3.1 is idential to State 3.0, with the exception off mass flow (bleeds) and exists at compressor exit
m31 = State31.MDot;
A31 = State31.Area;
Pt31 = State31.Pt;
Tt31 = State31.Tt;
M31 = State31.Mach;
Cp31 = State31.Cp;
Cv31 = State31.Cv;
g31 = State31.Gam;

R = 287; % Air property

Ts31 = EngineModelPkg.IsenRelPkg.Ts_Tt(Tt31,M31,g31);
%% Diffuser
% Station 3.2 exists at diffuser exit.

% slow down the flow
u32 = 40; % [m/s] This is a design choice.

for ii = 1:10 % iterate a few times to match Ts and M. Difference is nearly negligible. 3 iterations was sufficient upon testing. 10 should be overkill
    M32 = u32/sqrt(g31*R*Ts31);
    Ts32 = EngineModelPkg.IsenRelPkg.Ts_Tt(Tt31,M32,g31);
    Ts31 = Ts32;
    Cp32 = EngineModelPkg.SpecHeatPkg.CpAir(Ts32);
    Cv32 = EngineModelPkg.SpecHeatPkg.CvAir(Ts32);
    g32 = Cp32/Cv32;
    g31 = g32;
end

Astar = EngineModelPkg.IsenRelPkg.Astar_A(A31,M31,g31);
A32 = EngineModelPkg.IsenRelPkg.A_Astar(Astar,M32,g32);
AR = A32/A31;

Bt = 0.05; % CHANGE LATER FIND SOURCE 19 FROM p419 in Mattingly
EtaDm = 0.965-2.72*Bt;
EtaDopt = (1 - 2*EtaDm + (EtaDm*AR)^2)/(EtaDm*AR^2 - EtaDm);

PiD = 1 - (1-1/AR^2)*(1-EtaDopt)/(1+2/g31*M31^2);

Pt32 = Pt31*PiD;
Tt32 = Tt31;
m32 = m31;


%% Main Burner

mfuel = m32*EngineModelPkg.SpecHeatPkg.CpAir(Tt32,Tt4Max)/(EtaPoly.Combustor*LHVFuel - EngineModelPkg.SpecHeatPkg.CpJetA(Tt32,Tt4Max));

%f = (Tt4Max/Tt32-1)/((EtaPoly.Combustor*LHVFuel)/(EngineModelPkg.SpecHeatPkg.CpAir(Tt32,Tt4Max))-Tt4Max/Tt32);
m39 = m31+mfuel;

f = mfuel/m32;

Pt39 = Pt32*0.95; % Assumed pressure loss


%% Outputs

State39 = State31;
State39.MDot = m39;
State39.Pt = Pt39;
State39.Tt = Tt4Max;
State39.Mach = M32;
[State39.Ts,State39.Cp,State39.Cv,State39.Gam] = ...
    EngineModelPkg.IsenRelPkg.NewGamma(State39.Tt,State39.Mach,g32);
State39.Ps = EngineModelPkg.IsenRelPkg.Ps_Pt(State39.Pt,State39.Mach,State39.Gam);
State39.Area = A32;
State39.Ro = State31.Ro;
State39.Ri = sqrt(State39.Ro^2-State39.Area/pi);

MDotFuel = mfuel;


end















