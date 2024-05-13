


function [OffDesignEngine] = TurbofanOffDesignCycle(OnDesignEngine,OffParams)
%
% [OffDesignEngine] = TurbofanOffDesignCycle(OnDesignEngine,FlightCon,OffParams)
% Written by Maxfield Arnson
% Updated 10/5/2023
%
% This function computes the thermodynamic cycle inside of a turbofan
% engine. It can be considered a wrapper for the various component
% functions. It takes in a structure defined by a specification function
% similar to ExampleTF() located in EngineModelPkg/EngineSpecsPkg.
%
% INPUTS:
%
% EngSpecFun = Structure defined by a specification file created by a user
%       size: 1x1 struct
%
% MDotInput = total mass flow rate of air in the stream tube of the flow.
%       size: scalar double
%
% ElecPower = additional power supplied to the low pressure turbine
%       size: scalar double
%
%
% OUTPUTS:
%
% EngineObject = Structure describing all information about the engine.
%           Stores flow states, turbomachinery details, and on-design
%           performance metrics
%       size: 1x1 struct
%
%
% Station Map:
% ----------------------------------------
%
% 0..........Ambient
% 1..........Post Inlet
% 2..........Post Fan
% 21.........Pre Core (Compressors)
% 25.........Post Boosters/LPC
% 26.........Post IPC
% 3..........Post HPC
% 31.........Post Bleed
% 39.........Post Combustion
% 41.........Post Cooling Air Diffuser
% 5..........Post HPT
% 55.........Post IPT
% 6..........Post LPT
% 9..........Core Nozzle
% 13.........Pre Bypass Nozzle
% 19.........Bypass Nozzle





LHVFuel = 43.17e6;
ghot = 1.33;
gcold = 1.4;


%% Initialize and  Find Mass Flow Rate from known fan inlet

R = 287;
M0 = OffParams.FlightCon.Mach;
Alt = OffParams.FlightCon.Alt;

[Ts0,Ps0,rhos0] = MissionSegsPkg.StdAtm(Alt);
Cp0 = EngineModelPkg.SpecHeatPkg.CpAir(Ts0);
Cv0 = EngineModelPkg.SpecHeatPkg.CvAir(Ts0);
g0 = Cp0/Cv0;

Tt0 = EngineModelPkg.IsenRelPkg.Tt_Ts(Ts0,M0,g0);
Pt0 = EngineModelPkg.IsenRelPkg.Pt_Ps(Ps0,M0,g0);


%% Station 1
% Assuming diffuses to the same mach number as design
M1 = OnDesignEngine.States.Station1.Mach;
A1 = OnDesignEngine.States.Station1.Area;


Astar = EngineModelPkg.IsenRelPkg.Astar_A(A1,M1,g0);
A0 = EngineModelPkg.IsenRelPkg.A_Astar(Astar,M0,g0);

m0 = A0*rhos0*M0*sqrt(g0*R*Ts0);
m1 = m0;

Tt1 = Tt0;
Pt1 = Pt0*OnDesignEngine.Specs.EtaPoly.Diffusers;

Ts1 = EngineModelPkg.IsenRelPkg.Ts_Tt(Tt1,M0,g0);
Ps1 = EngineModelPkg.IsenRelPkg.Ps_Pt(Pt1,M0,g0);

% g1 = NEWGAMMA


u0 = M0*sqrt(gcold*R*Ts0);
RamDrag = m0*u0;


%% Increase OPR and BPR models
OPR_SLS = OnDesignEngine.Specs.OPR/(2e-5*OnDesignEngine.Specs.Alt + 1);
OPR_Cur = (2e-5*Alt + 1)*OPR_SLS;


BPR_SLS = OnDesignEngine.Specs.BPR/(2e-5*OnDesignEngine.Specs.Alt + 1);
BPR_Cur = (1e-5*Alt + 1).*BPR_SLS;


%% Fuel-Air-Ratio FAR based on Power Code

FAR = OffParams.PC*OnDesignEngine.Fuel.FAR;


%% Core Flow

m21 = m0/(1+BPR_Cur);
g21 = OnDesignEngine.States.Station21.Gam;

CoreOTR = OPR_Cur^((g21 - 1)/g21);

Tt3 = CoreOTR*Tt1;
Pt3 = OPR_Cur*Pt1;

CoreWork = EngineModelPkg.SpecHeatPkg.CpAir(Tt1,Tt3)*m21/OnDesignEngine.Specs.EtaPoly.Compressors;


%% Find Combustion Temperature

m3 = m21;

m31 = m3*(1 - OnDesignEngine.Specs.CoreFlow.PaxBleed - OnDesignEngine.Specs.CoreFlow.Leakage);

mfuel = FAR*m31;

fuelpower = LHVFuel*mfuel;



Tt39 = OnDesignEngine.States.Station39.Tt;

fuelguess = mfuel*1.1;

while abs(fuelguess - mfuel)/mfuel > 1e-5

    Tt39 = Tt39*(1-(fuelguess-mfuel)/mfuel);
    fuelguess = m31*EngineModelPkg.SpecHeatPkg.CpAir(Tt3,Tt39)/(OnDesignEngine.Specs.EtaPoly.Combustor*LHVFuel - EngineModelPkg.SpecHeatPkg.CpJetA(Tt3,Tt39));
end

Pt31 = Pt3;


Tt39
OnDesignEngine.States.Station39.Tt

m39 = m31+mfuel;
Pt39 = Pt31*0.95;

%% Extract work for compressor turbine

m5 = m39;
Tt5 = EngineModelPkg.SpecHeatPkg.NewtonRaphsonTt3(Tt39,CoreWork/m5/OnDesignEngine.Specs.EtaPoly.Turbines);

Pt5 = Pt39*(Tt5/Tt39)^(ghot/(ghot - 1));



%% Calculate work that goes to the fan, extract from flow

fanpower = fuelpower*(OnDesignEngine.FanSysObject.FanObject.ReqWork/(OnDesignEngine.Fuel.MDot*LHVFuel));

Tt13 = EngineModelPkg.SpecHeatPkg.NewtonRaphsonTt1(Tt1,fanpower/m1);

TauFan = Tt13/Tt1;
PiFan = TauFan^(ghot/(ghot - 1));

Pt13 = Pt1*PiFan;

m6 = m5;
Tt6 = EngineModelPkg.SpecHeatPkg.NewtonRaphsonTt3(Tt5,fanpower/m6/OnDesignEngine.Specs.EtaPoly.Turbines);

Pt6 = Pt5*(Tt6/Tt5)^(ghot/(ghot - 1));


%% Calculate pre-nozzle core state and get core thrust
m9 = m6;

A6 = OnDesignEngine.States.Station6.Area;
[M6,Ts6,Ps6,Rhos6] = StateEstimation(Tt6,Pt6,ghot,m6,A6);

% thrust
A9 = OnDesignEngine.States.Station9.Area;
M9 = EngineModelPkg.ComponentOffPkg.Nozzle(A6,A9,M6,ghot);

Ps9 = EngineModelPkg.IsenRelPkg.Ps_Pt(Pt6,M9,ghot);
Ts9 = EngineModelPkg.IsenRelPkg.Ts_Tt(Tt6,M9,ghot);

u9 = M9*sqrt(ghot*R*Ts9)*OnDesignEngine.Specs.EtaPoly.Nozzles;

CoreThrust = u9*m9 + (Ps9 - Ps0)*A9;

%% calculate pre-nozzle bypass State and get bypass thrust


m13 = m0*BPR_Cur/(1+BPR_Cur);
m19 = m13;

A13 = OnDesignEngine.States.Station13.Area;
[M13,Ts13,Ps13,Rhos13] = StateEstimation(Tt13,Pt13,gcold,m13,A13);

A19 = OnDesignEngine.States.Station19.Area;
M19 = EngineModelPkg.ComponentOffPkg.Nozzle(A13,A19,M13,gcold);

Ps19 = EngineModelPkg.IsenRelPkg.Ps_Pt(Pt13,M19,gcold);
Ts19 = EngineModelPkg.IsenRelPkg.Ts_Tt(Tt13,M19,gcold);

u19 = M19*sqrt(gcold*R*Ts19)*OnDesignEngine.Specs.EtaPoly.Nozzles;

BypassThrust = u19*m19 + (Ps19 - Ps0)*A19;

%% Nozzles


% Outputs

OffDesignEngine.Thrust.Core = CoreThrust;
OffDesignEngine.Thrust.Bypass = BypassThrust;
OffDesignEngine.Thrust.RamDrag = -RamDrag;
OffDesignEngine.Thrust.Net = CoreThrust + BypassThrust - RamDrag;


OffDesignEngine.TSFC = mfuel/OffDesignEngine.Thrust.Net;

OffDesignEngine.TSFC_Imperial = UnitConversionPkg.ConvTSFC(OffDesignEngine.TSFC,'SI','Imp');

OffDesignEngine.Fuel.MDot = mfuel;
OffDesignEngine.Fuel.FAR = FAR;




end


%% Additional Function
function [M,Ts,Ps,Rhos] = StateEstimation(Tt,Pt,g,mdot,A)

R = 287;
M = 0.5;

Rhot = Pt/Tt/R;


Ts = Tt*(1+(g-1)/2*M^2)^(-1);
Ps = Pt*(1+(g-1)/2*M^2)^(-g/(g-1));
Rhos = Ps/Ts/R;

u = M*sqrt(g*R*Ts);
mdot_2 = Rhos*u*A;



while abs(mdot_2 - mdot)/mdot > 1e-3

    M = M*(1 - (mdot_2 - mdot)/mdot);

    Ts = Tt*(1+(g-1)/2*M^2)^(-1);
    Ps = Pt*(1+(g-1)/2*M^2)^(-g/(g-1));
    Rhos = Ps/Ts/R;
    u = M*sqrt(g*R*Ts);
    mdot_2 = Rhos*u*A;

end



end










