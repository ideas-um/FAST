function [EngineObject] = PropfanOnDesignCycle(EngSpecFun,MDotInput)
%
% [EngineObject] = TurbofanOnDesignCycle(EngSpecFun,MDotInput)
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


%%  Input Processing
if EngSpecFun.NoSpools ~= length(EngSpecFun.RPMs)
    error("Number of spools must match number of input RPMs.")
end

Spools.Count = EngSpecFun.NoSpools;
Spools.RPM = EngSpecFun.RPMs;
EtaPoly = EngSpecFun.EtaPoly;

OPR = EngSpecFun.OPR;
Tt4Max = EngSpecFun.Tt4Max; %1777.77;
LHVFuel = 43.17e6;

%% Ambient
R = 287; % [J/kgK] gas constant for air
M0 = EngSpecFun.Mach;
[Ts0,Ps0,Rhos0] = MissionSegsPkg.StdAtm(EngSpecFun.Alt);
Cp0 = EngineModelPkg.SpecHeatPkg.CpAir(Ts0);
Cv0 = EngineModelPkg.SpecHeatPkg.CvAir(Ts0);
g0 = Cp0/Cv0;

Pt0 = EngineModelPkg.IsenRelPkg.Pt_Ps(Ps0,M0,g0);
Tt0 = EngineModelPkg.IsenRelPkg.Tt_Ts(Ts0,M0,g0);

MDot0 = MDotInput;
u0 = M0*sqrt(g0*Ts0*R);
A0 = MDot0/Rhos0/u0;
Ro0 = sqrt(A0/pi);
Ri0 = 0;

State0.MDot = MDot0;
State0.Pt = Pt0;
State0.Ps =Ps0;
State0.Tt = Tt0;
State0.Ts = Ts0;
State0.Mach = M0;
State0.Cp = Cp0;
State0.Cv = Cv0;
State0.Gam = g0;
State0.Area = A0;
State0.Ro = Ro0;
State0.Ri = Ri0;

% Ram Drag Calc

%RamDrag = u0*MDot0;


%% Fan Inlet

%FanInletMach = 0.5;
%State1 = EngineModelPkg.ComponentOnPkg.Diffuser(State0,FanInletMach,"Inner",EtaPoly);
State1 = State0;

%% Compressor Stages
% Initialize
% FanSysObject.Geared = false;
% FanSysObject.Boosted = false;
% FanSysObject.GearRatio = 1;
% FanSysObject.FanObject = struct();
% FanSysObject.BoosterObject = struct();
% FanSysObject.LPCObject = struct();
% 
% if isnan(EngSpecFun.FanGearRatio) || EngSpecFun.FanGearRatio == 1
% FanSysObject.Geared = false;
%     FanSysObject.GearRatio = 1;
%     FanSysObject.FanObject.RPM = Spools.RPM(1)/FanSysObject.GearRatio;
%     FanSysObject.LPCObject = "Nonexistent";
% else
%     FanSysObject.Geared = true;
%     FanSysObject.GearRatio = EngSpecFun.FanGearRatio;
%     FanSysObject.FanObject.RPM = Spools.RPM(1)/FanSysObject.GearRatio;
%     FanSysObject.LPCObject.RPM = Spools.RPM(1);
% end
% 
% 
% if EngSpecFun.FanBoosters
% FanSysObject.Boosted = true;
% FanSysObject.BoosterObject.RPM = Spools.RPM(1);
% else
%     FanSysObject.Boosted = false;
%     FanSysObject.BoosterObject = "Nonexistent";
% end
% 
% 
% % Fan and boosters
% FanSysObject.FanObject.Pi = EngSpecFun.FPR;
% [State2,State21,State13,~,FanSysObject] =...
%     EngineModelPkg.ComponentOnPkg.FanSystem(State1,FanSysObject,OPR,Spools,EngSpecFun.BPR,EtaPoly);
% PiFan = FanSysObject.Pi;

%% Bypass Air
% Fan
BPR = EngSpecFun.BPR;

% Core part of streamtube
State21 = State1; 
State21.MDot = State21.MDot/(1+BPR);
State21.Area = State21.Area/(1+BPR);
State21.Ri = 0;
State21.Ro = sqrt(State21.Area/pi);


% Diffuser for compressor inlet

CompInletMach = 0.5;
State25 = EngineModelPkg.ComponentOnPkg.Diffuser(State21,CompInletMach,"Inner",EtaPoly);

% IPC
if Spools.Count == 3
    PiIPC = (OPR)^(1/(Spools.Count-1));
[State26,IPCObject] = EngineModelPkg.ComponentOnPkg.Compressor(State25,PiIPC,Spools.RPM(2),EtaPoly);
PiIPC = IPCObject.Pi;
else
    State26 = State25;
    IPCObject = "Nonexistent";
    PiIPC = 1;
end

% HPC
PiHPC = OPR/PiIPC;
[State3,HPCObject] = ...
    EngineModelPkg.ComponentOnPkg.Compressor(State26,PiHPC,Spools.RPM(end),EtaPoly);

EngineObject.OPRActual = PiIPC*HPCObject.Pi;


%% Bleed
PaxBleed = EngSpecFun.CoreFlow.PaxBleed;
Leakage = EngSpecFun.CoreFlow.Leakage;
Cooling = EngSpecFun.CoreFlow.Cooling;

State31 = State3;
State31.MDot = State3.MDot*(1-Cooling - PaxBleed - Leakage);
StateCoolant = State3;
StateCoolant.MDot = StateCoolant.MDot*Cooling;
% 6% cooling, 3% customer, 1% leakage

%% Burner Stage

[State39,MDotFuel,FAR] = EngineModelPkg.ComponentOnPkg.Burner(State31,Tt4Max,LHVFuel,EtaPoly);

State4 = EngineModelPkg.ComponentOnPkg.Diffuser(State39,0.4,"Outer",EtaPoly);



%% Reintroduce Cooling Air
State41 = State4;
State41.MDot = State41.MDot + StateCoolant.MDot;
Ht41 = State4.Cp*State4.Tt*State4.MDot+ StateCoolant.Cp*StateCoolant.Tt*StateCoolant.MDot;
State41.Tt = Ht41/State41.MDot/EngineModelPkg.SpecHeatPkg.CpAir(State4.Tt*State4.MDot/(State41.MDot)+StateCoolant.Tt*StateCoolant.MDot/State41.MDot);
State41.Pt = State41.Pt*0.95;
State41.Cp = EngineModelPkg.SpecHeatPkg.CpAir(State41.Tt);
State41.Cv = EngineModelPkg.SpecHeatPkg.CvAir(State41.Tt);
State41.Gam = State41.Cp/State41.Cv;

% add static values here

%% HPT

[State5,HPTObject] = EngineModelPkg.ComponentOnPkg.Turbine(State41,HPCObject,EtaPoly);



%% IPT
if Spools.Count == 3
[State55,IPTObject] = EngineModelPkg.ComponentOnPkg.Turbine(State5,HPCObject,EtaPoly);
else
    IPTObject = "Nonexistent";
    State55 = State5;
end

%% Bypass Air

% Bypass Part of streamtube
State13 = State1;
State13.MDot = State21.MDot*BPR;
State13.Area = State21.Area*BPR;
State13.Ri = State21.Ro;
State13.Ro = sqrt(State13.Area/pi + State13.Ri^2);

% Bypass Thrust

FPR = EngSpecFun.FPR;

% Exit Tube
State19 = State13;
State19.Pt = State13.Pt*FPR;
State19.Ps = State0.Ps;
u19 = sqrt(2*(State19.Pt - State19.Ps)/Rhos0)*EtaPoly.Fan;
State19.Tt = State19.Ts + u19^2/2/State19.Cp;
State19.Mach = u19/sqrt(State19.Gam*R*State19.Ts);
State19.Ri = State25.Ro;
State19.Area = State19.MDot/u19/Rhos0;
State19.Ro = sqrt(State19.Area/pi + State19.Ri^2);


% At Propeller
State15 = State19;

u15 = (u19+u0)/2;
State15.Ps = State15.Pt - 0.5*Rhos0*u15^2;
State15.Ts = State15.Tt - u15^2/2/State15.Cp;


State15.Area = State19.MDot/u15/Rhos0;
State15.Ri = State25.Ro;
State15.Ro = sqrt(State15.Area/pi + State15.Ri^2);


% Fan Object
FanObject.RPM = Spools.RPM(1);
FanObject.ReqWork = State13.MDot*EngineModelPkg.SpecHeatPkg.CpAir(State13.Tt,State15.Tt);


%% LPT
[State6,LPTObject] = EngineModelPkg.ComponentOnPkg.Turbine(State55,FanObject,EtaPoly);

%% Nozzle + Thrust

% Bypass
BypassThrust = State19.MDot*(u19 - u0);

% Core

[State9,CoreThrust] = EngineModelPkg.ComponentOnPkg.PerfExNozzle(State6,State0,EtaPoly,"Core");

%% Thrust Calculations
u21 = State21.Mach*sqrt(State21.Gam*State21.Ts*R);
RamDrag = State21.MDot*u21;

Thrust.Net = BypassThrust+CoreThrust-RamDrag;
Thrust.Bypass = BypassThrust;
Thrust.Core = CoreThrust;
Thrust.RamDrag = -RamDrag;

%% Overall efficiency
u9 = State9.Mach*sqrt(State9.Gam*R*State9.Ts);
u19 = State19.Mach*sqrt(State19.Gam*R*State19.Ts);

EngineObject.Efficiency.Thermal = (State9.MDot*u9^2 + State19.MDot*u19^2  - State0.MDot*u0^2)/2/LHVFuel/MDotFuel;
EngineObject.Efficiency.Propulsive = Thrust.Net*u0/((State9.MDot*u9^2 + State19.MDot*u19^2  - State0.MDot*u0^2)/2);
EngineObject.Efficiency.Overall = EngineObject.Efficiency.Thermal*EngineObject.Efficiency.Propulsive;


%% Outputs


% Assign States to Engine Object
EngineObject.States.StreamTube = State0  ;
EngineObject.States.Station1   = State1  ;
EngineObject.States.Station15   = State15  ;
EngineObject.States.Station21  = State21 ;
EngineObject.States.Station25  = State25 ; 
EngineObject.States.Station26  = State26 ;
EngineObject.States.Station3   = State3  ;
EngineObject.States.Station31  = State31 ;
EngineObject.States.Station39  = State39 ;
EngineObject.States.Station4   = State4  ;
EngineObject.States.Station41  = State41 ;
EngineObject.States.Station5   = State5  ;
EngineObject.States.Station55  = State55 ;
EngineObject.States.Station6   = State6  ;
EngineObject.States.Station13  = State13 ;
EngineObject.States.Station9   = State9  ;
EngineObject.States.Station19  = State19 ;

% Assign Turbomachinery Objects
EngineObject.FanObject    = FanObject    ;
EngineObject.IPCObject    = IPCObject    ;
EngineObject.HPCObject    = HPCObject    ;
EngineObject.HPTObject    = HPTObject    ;
EngineObject.IPTObject    = IPTObject    ;
EngineObject.LPTObject    = LPTObject    ;


% Assign Performance Metrics
EngineObject.Thrust = Thrust;
EngineObject.TotalAirflow = State0.MDot;
EngineObject.CoreAirflow = State21.MDot;
EngineObject.Fuel.MDot = MDotFuel;
EngineObject.Fuel.FAR = FAR;
EngineObject.TSFC = MDotFuel/Thrust.Net;
EngineObject.TSFC_Imperial = MDotFuel/Thrust.Net*3600/convforce(1,'N','lbf')*convmass(1,'kg','lbm');
EngineObject.EGT_Celsius = convtemp(State6.Ts,'K','C');
EngineObject.FanDiam = 2*State15.Ro;

EngineObject.FT_Inlet_Temp = State55.Ts;
EngineObject.Specs = EngSpecFun;

end

