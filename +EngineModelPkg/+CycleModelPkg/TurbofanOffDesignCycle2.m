function [OffDesignEngine] = TurbofanOffDesignCycle2(OnDesignEngine,OffParams,EtaPoly)
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


%% Efficiency Stuff

if nargin < 3
EtaPoly = OnDesignEngine.Specs.EtaPoly;
end

%% Constants
LHVFuel = 43.17e6;
ghot = 1.33;
gcold = 1.4;
g0 = gcold;
R = 287;

%% Ambient Conditions
alt = OffParams.FlightCon.Alt;
M0 = OffParams.FlightCon.Mach;
g = 1.4;

[Ts0,Ps0,rhos0] = MissionSegsPkg.StdAtm(alt);

Tt0 = EngineModelPkg.IsenRelPkg.Tt_Ts(Ts0,M0,g);
Pt0 = EngineModelPkg.IsenRelPkg.Pt_Ps(Ps0,M0,g);

%% Ram Drag Calculations
% Assuming diffuses to the same mach number as design
M1 = OnDesignEngine.States.Station1.Mach;
A1 = OnDesignEngine.States.Station1.Area;

Astar = EngineModelPkg.IsenRelPkg.Astar_A(A1,M1,g0);
A0 = EngineModelPkg.IsenRelPkg.A_Astar(Astar,M0,g0);

m0 = A0*rhos0*M0*sqrt(g0*R*Ts0);

u0 = M0*sqrt(g0*R*Ts0);
RamDrag = m0*u0;



%% Increase OPR and BPR models
OPR_SLS = OnDesignEngine.Specs.OPR/(2e-5*OnDesignEngine.Specs.Alt + 1);
OPR_Cur = (2e-5*alt + 1)*OPR_SLS;

BPR_SLS = OnDesignEngine.Specs.BPR/(2e-5*OnDesignEngine.Specs.Alt + 1);
BPR_Cur = (1e-5*alt + 1).*BPR_SLS;



%% MFP in Turbines

CorrConst.a = 1.0889;
CorrConst.b = -1.2261;
CorrConst.c = 4.8277;
CorrConst.d = -6.9116;
CorrConst.e = 2.8067;

MFPTurb = @ (r) CorrConst.a + CorrConst.b/r + CorrConst.c/r^2 + CorrConst.d/r^3 + CorrConst.e/r^4;


%% Assume PiFT and  corresponding PiCT

rCTdes = 1/OnDesignEngine.HPTObject.CPR;
rFTdes = 1/OnDesignEngine.LPTObject.CPR;

rFT = rFTdes*OffParams.PC;

rCT = rFT*(rCTdes/rFTdes);




%% Calculate Compressor Pressure Ratio

rCompdes = OnDesignEngine.OPRActual;
rComp = rFT/rFTdes   *    rCT/rCTdes  * rCompdes;

%% Tt3 Calculation

g3 = 1.35;

Tt2 = Tt0*rComp^((g3-1)/g3);



Tt4o3 = 1 / rCT^((ghot-1)/ghot);
Tt4o3des = 1 / rCTdes^((OnDesignEngine.States.Station39.Gam-1)/OnDesignEngine.States.Station39.Gam);


phi = (rComp^((g3-1)/g3) -1)/(rCompdes^((OnDesignEngine.States.Station3.Gam-1)/OnDesignEngine.States.Station3.Gam)-1)*(1-Tt4o3des)/(1-Tt4o3);

Tt3 = phi*Tt0*(OnDesignEngine.States.Station39.Tt/OnDesignEngine.States.Station1.Tt);

MFP1des = OnDesignEngine.States.StreamTube.MDot * sqrt(OnDesignEngine.States.StreamTube.Tt)/OnDesignEngine.States.StreamTube.Pt;
mTotal = (rComp/rCompdes * MFP1des / (sqrt(phi) * sqrt(Tt0)/Pt0) );
mCore = mTotal*1/(BPR_Cur + 1);
mBypass = mTotal*BPR_Cur/(BPR_Cur + 1);

Tt4 = Tt3 / rCT^((ghot-1)/ghot);

Tt5 = Tt4 / rFT^((ghot-1)/ghot);

Pt5 = Pt0*rComp/rCT;

rFT2 = (Tt4/Tt5)^(ghot/(ghot-1));


% Calculate fuel burn yeah
EtaComb = EtaPoly.Combustor;
mfuel = mCore*EngineModelPkg.SpecHeatPkg.CpAir(Tt2,Tt3)/(EtaComb*LHVFuel - EngineModelPkg.SpecHeatPkg.CpJetA(Tt2,Tt3));

% mfuel
% mfuel - OnDesignEngine.Fuel.MDot

FanPower = mCore*EngineModelPkg.SpecHeatPkg.CpAir(Tt5,Tt4);

EtaTurb = EtaPoly.Turbines;
Tt21 = EngineModelPkg.SpecHeatPkg.NewtonRaphsonTt1(Tt0,FanPower/mTotal*EtaTurb);



%% Bypass Nozzle
g13 = 1.4;
A13 = OnDesignEngine.States.Station13.Area;
A19 = OnDesignEngine.States.Station19.Area;

Tt13 = Tt21;
Pt13 = Pt0*(Tt13/Tt0)^(g13/(g13-1))*EtaPoly.Fan;

[M13,~,~,~] = StateEstimation(Tt13,Pt13,g13,mBypass,A13);
M19 = EngineModelPkg.ComponentOffPkg.Nozzle(A13,A19,M13,g13);

Ts19 = EngineModelPkg.IsenRelPkg.Ts_Tt(Tt13,M19,g13);
Ps19 = EngineModelPkg.IsenRelPkg.Ps_Pt(Pt13,M19,g13);
u19 = M19*sqrt(g13*R*Ts19)*EtaPoly.Nozzles;

BypassThrust = u19*mBypass + (Ps19 - Ps0)*A19;

%% Core Nozzle
g9 = 1.368;
A6 = OnDesignEngine.States.Station6.Area;
A9 = OnDesignEngine.States.Station9.Area;

Tt6 = Tt5;
Pt6 = Pt0*rComp/rCT/rFT;

[M6,~,~,~] = StateEstimation(Tt6,Pt6,g9,mCore,A6);
M9 = EngineModelPkg.ComponentOffPkg.Nozzle(A6,A9,M6,g9);

Ts9 = EngineModelPkg.IsenRelPkg.Ts_Tt(Tt6,M9,g9);
Ps9 = EngineModelPkg.IsenRelPkg.Ps_Pt(Pt6,M9,g9);
u9 = M9*sqrt(g9*R*Ts9)*EtaPoly.Nozzles;

CoreThrust = u9*mCore + (Ps9 - Ps0)*A9;

%% Thrust

% Outputs
OffDesignEngine.Thrust.Net = CoreThrust + BypassThrust - RamDrag;
OffDesignEngine.Thrust.Bypass = BypassThrust;
OffDesignEngine.Thrust.Core = CoreThrust;
OffDesignEngine.Thrust.RamDrag = -RamDrag; 

%% TSFC

OffDesignEngine.TSFC = mfuel/OffDesignEngine.Thrust.Net;

OffDesignEngine.TSFC_Imperial = UnitConversionPkg.ConvTSFC(OffDesignEngine.TSFC,'SI','Imp');

OffDesignEngine.Fuel.MDot = mfuel;

BSFC = mfuel/FanPower;
BSFCdes = OnDesignEngine.Fuel.MDot/OnDesignEngine.FanSysObject.TotalWork;
% BSFCdes = OnDesignEngine.Fuel.MDot/OnDesignEngine.FanSysObject.FanObject.ReqWork

OffDesignEngine.ODScale = 1/(1 + (BSFC - BSFCdes)/BSFCdes);
OffDesignEngine.BSFC = BSFC;

OffDesignEngine.States.Station2.Tt = Tt21;

OffDesignEngine.MDotAir = mTotal;

OffDesignEngine.FanPower = FanPower;

OffDesignEngine.PiComp = rComp;


%% Additional Function
function [M,Ts,Ps,Rhos] = StateEstimation(Tt,Pt,g,mtrue,A)

R = 287;
M = 0.5;

Rhot = Pt/Tt/R;


Ts = Tt*(1+(g-1)/2*M^2)^(-1);
Ps = Pt*(1+(g-1)/2*M^2)^(-g/(g-1));
Rhos = Ps/Ts/R;

u = M*sqrt(g*R*Ts);
mdot = Rhos*u*A;

prime = 1;

iter = 0;

while abs(prime) > 1e-7

    Ts = Tt*(1+(g-1)/2*M^2)^(-1);
    Ps = Pt*(1+(g-1)/2*M^2)^(-g/(g-1));
    Rhos = Ps/Ts/R;
    u = M*sqrt(g*R*Ts);
    mdot = Rhos*u*A;

    prime = -2*(mtrue - (A*M*Pt*g^(1/2)*((g/2 - 1/2)*M^2 + 1)*(1/((g/2 - 1/2)*M^2 + 1))^(1/2))/(R^(1/2)*Tt^(1/2)*((g/2 - 1/2)*M^2 + 1)^(g/(g - 1))))*((A*Pt*g^(1/2)*((g/2 - 1/2)*M^2 + 1)*(1/((g/2 - 1/2)*M^2 + 1))^(1/2))/(R^(1/2)*Tt^(1/2)*((g/2 - 1/2)*M^2 + 1)^(g/(g - 1))) + (2*A*M^2*Pt*g^(1/2)*(g/2 - 1/2)*(1/((g/2 - 1/2)*M^2 + 1))^(1/2))/(R^(1/2)*Tt^(1/2)*((g/2 - 1/2)*M^2 + 1)^(g/(g - 1))) - (A*M^2*Pt*g^(1/2)*(g/2 - 1/2))/(R^(1/2)*Tt^(1/2)*((g/2 - 1/2)*M^2 + 1)^(g/(g - 1))*((g/2 - 1/2)*M^2 + 1)*(1/((g/2 - 1/2)*M^2 + 1))^(1/2)) - (2*A*M^2*Pt*g^(3/2)*(g/2 - 1/2)*((g/2 - 1/2)*M^2 + 1)*(1/((g/2 - 1/2)*M^2 + 1))^(1/2))/(R^(1/2)*Tt^(1/2)*((g/2 - 1/2)*M^2 + 1)^(g/(g - 1) + 1)*(g - 1)));

    Mnew = M - (mdot - mtrue)^2/prime;

    M = Mnew;

    M(M>1) = 0.99;

    iter = iter+1;
%     scatter(iter,mdot)
%     hold on
    
    if iter > 150
        error('Engine Model Off Design; Failure to converge on mach number during state estimation')
    end

end


end % end State Estimation

end % end Off-Design









