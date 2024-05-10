


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






%% Increase OPR and BPR models
OPR_SLS = OnDesignEngine.Specs.OPR/(2e-5*OnDesignEngine.Specs.Alt + 1);
OPR_Cur = (2e-5*Alt + 1)*OPR_SLS;


BPR_SLS = OnDesignEngine.Specs.BPR/(2e-5*OnDesignEngine.Specs.Alt + 1);
BPR_Cur = (1e-5*Alt + 1).*BPR_SLS;


%% Fuel-Air-Ratio FAR based on Power Code

FAR = OffParams.PC*OnDesignEngine.Fuel.FAR;


%% Core Flow

m21 = m0/BPR_Cur;
g21 = OnDesignEngine.States.Station21.Gam;

CoreOTR = OPR_Cur^((g21 - 1)/g21);

Tt3 = CoreOTR*Tt1;
Pt3 = OPR_Cur*Pt1;

CoreWork = EngineModelPkg.SpecHeatPkg.CpAir(Tt1,Tt3)*m21;


%% Find Combustion Temperature

m3 = m21;

m31 = m3*(1 - OnDesignEngine.Specs.CoreFlow.PaxBleed - OnDesignEngine.Specs.CoreFlow.Leakage);

mfuel = FAR*m31;

fuelenergy = LHVFuel*mfuel;


m39 = m31+mfuel;

Tt39 = EngineModelPkg.SpecHeatPkg.NewtonRaphsonTt1(Tt3,fuelenergy/m39)
OnDesignEngine.States.Station39.Tt

aaaaaa = 1;
end












