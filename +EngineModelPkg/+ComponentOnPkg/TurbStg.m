function [NewState,Pis,Taus] = TurbStg(OldState,Tt3,RPM,Choked,EtaPoly)
%
% [NewState,Pis,Taus] = TurbStg(OldState,Tt3,RPM,Choked,EtaPoly)
% Written by Maxfield Arnson
% Updated 10/5/2023
%
% This function computes the change in the airflow properties across a
% single turbine stage. Similar to the CompStg() and FanStg() functions. 
%
%
% INPUTS:
%
% OldState = Flow state coming into turbine stage
%       size: 1x1 struct
%
% Tt3 = total temperature of the flow POST turbine stage. Computed outside
%           of this function to determine the required specific work of this stage
%       size: scalar double
%
% RPM = revolutions per minute that the turbine spins at. 
%       size: scalar double
%
% Choked = flag to determine if the stator chokes the flow. first turbine
%           stage of the first turbine always chokes the flow
%       size: boolean
%
% EtaPoly = structure containing various efficiencies for the engine.
%           The TurbStg function uses EtaPoly.Turbines
%       size: 1x1 struct
%
%
% OUTPUTS:
%
% NewState = flow state directly post fan (before splitting into core and 
%           bypass). Mimics the format of the inputted
%           state.
%       size: 1x1 struct
%
% Pis = stagnation pressure ratio across the turbine stage
%       size: scalar double
%
% Taus = stagnation temperature ratio across the turbine stage
%       size: scalar double

%% Initialization
R = 287;
M1 = OldState.Mach;
g1 = OldState.Gam;
Tt1 = OldState.Tt; 
et = EtaPoly.Turbines;

Ts1 = EngineModelPkg.IsenRelPkg.Ts_Tt(Tt1,M1,g1);

u1 = M1*sqrt(g1*R*Ts1);
A1 = OldState.Area;

%% Input Processing
switch Choked
    case true
        M2 = 1.1;
    case false
        M2 = 0.9;
end

Tt2 = Tt1;
g2 = g1;
w = RPM/60*2*pi;

Rp = 0.5*(OldState.Ro+OldState.Ri);

%% Design Vectors and Pressure Ratio

% Psis = EngineModelPkg.SpecHeatPkg.CpAir(Tt3,Tt2)/(w*Rp)^2;
% Taus = Tt3/Tt2;
% Pis = Taus^((g2)/(g2-1)*et);
% 
% V2 = sqrt((2*Tt2*EngineModelPkg.SpecHeatPkg.CpAir(Tt2))/(1+2/((g2-1)*M2^2)));
% 
% a2wrong = asin(Psis*w*g1/V2);
% a2 = asin(sqrt((1-Taus)*Psis/2*(1+2/((g2-1)*M2^2))));
% 
% M3 = M2*cos(a2)/sqrt(1-(1-Taus)*(1-Psis/2)*(1+(g2-1)/2*M2^2));
% 
% Pt2 = OldState.Pt; %% NOT A GREAT ASSUMPTION
% Pt3 = Pis*Pt2;


%% Mattingly vector design

Psis = EngineModelPkg.SpecHeatPkg.CpAir(Tt3,Tt2)/(w*Rp)^2;
Taus = Tt3/Tt2;
Pis = Taus^((g2)/(g2-1)*et);


Vprime = sqrt(EngineModelPkg.SpecHeatPkg.CpAir(Tt1)*Tt1);
Omega = w*Rp/Vprime;

V2 = Vprime*sqrt((g1-1)*M2^2/(1+(g1-1)/2*M2^2));

u2 = u1;

a2 = acos(u2/V2);

M3 = M2*cos(a2)/sqrt(1-(1-Taus)*(1-Psis/2)*(1+(g2-1)/2*M2^2));

Pt2 = OldState.Pt; %% NOT A GREAT ASSUMPTION
Pt3 = Pis*Pt2;

%% New Areas at Station 2 and 3;

A2 = OldState.MDot*sqrt(Tt2)/(Pt2*cos(a2)*EngineModelPkg.IsenRelPkg.MassFlowParam(M2,g2));



A3 = OldState.MDot*sqrt(Tt2)/(Pt3*EngineModelPkg.IsenRelPkg.MassFlowParam(M3,g2));




%% Output
NewState=OldState;
% MDot Constant
NewState.Tt = Tt3;
NewState.Pt = Pt3;
NewState.Mach = M3;
[NewState.Ts,NewState.Cp,NewState.Cv,NewState.Gam] = ...
    EngineModelPkg.IsenRelPkg.NewGamma(NewState.Tt,NewState.Mach,g2);
NewState.Ps = EngineModelPkg.IsenRelPkg.Ps_Pt(NewState.Pt,NewState.Mach,NewState.Gam);
NewState.Area = OldState.MDot*sqrt(Tt2)/(Pt3*EngineModelPkg.IsenRelPkg.MassFlowParam(NewState.Mach,NewState.Gam));
NewState.Ri = OldState.Ri;
NewState.Ro = sqrt(NewState.Ri^2+A3/pi);




end