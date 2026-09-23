function [EngineObject] = TurbopropOnDesignCycle(EngSpecFun,MDotInput,ElecPower)
%
% [EngineObject] = TurbopropOnDesignCycle(EngSpecFun,MDotInput)
% Written by Maxfield Arnson
% Updated 10/5/2023
%
% This function computes the thermodynamic cycle inside of a turboprop
% engine. It can be considered a wrapper for the various component
% functions. It takes in a structure defined by a specification function
% similar to ExampleTP() located in EngineModelPkg/EngineSpecsPkg.
%
% INPUTS:
%
% EngSpecFun = Structure defined by a specification file created by a user
%       size: 1x1 struct
%
% MDotInput = total mass flow rate of air in the stream tube of the flow.
%           (Not passing through the propeller, just the engine)
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
% ---------------------------------
%
% 0..........Ambient
% 1..........Post Inlet
% 26.........Post IPC
% 3..........Post HPC
% 31.........Post Bleed
% 39.........Post Combustion
% 4..........Post Combustor Diffuser
% 41.........Post Cooling Air
% 5..........Post HPT
% 55.........Post IPT
% 7..........Post FT



%%  Input Processing
if EngSpecFun.NoSpools ~= length(EngSpecFun.RPMs)
    error("Number of spools must match number of input RPMs.")
end

Spools.Count = EngSpecFun.NoSpools;
Spools.RPM = EngSpecFun.RPMs;
EtaPoly = EngSpecFun.EtaPoly;

OPR = EngSpecFun.OPR;
Tt4Max = EngSpecFun.Tt4Max;
LHVFuel = 43.17e6;
Cooling = 0.0;

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
State0.Tt = Tt0;
State0.Mach = M0;
State0.Cp = Cp0;
State0.Cv = Cv0;
State0.Gam = g0;
State0.Area = A0;
State0.Ro = Ro0;
State0.Ri = Ri0;

% Ram Drag
RamDrag = u0*MDot0;



%% Compressor Inlet

CompInletMach = 0.5;
State1 = EngineModelPkg.ComponentOnPkg.Diffuser(State0,CompInletMach,"Inner",EtaPoly);


%% HPC
if length(Spools.RPM) > 1
    [State3,HPCObject] = ...
        EngineModelPkg.ComponentOnPkg.Compressor(State1,OPR,Spools.RPM(end-1),EtaPoly);
else % Single spool
    [State3,HPCObject] = ...
        EngineModelPkg.ComponentOnPkg.Compressor(State1,OPR,Spools.RPM,EtaPoly);
end

OPRActual = HPCObject.Pi;

%% Bleed

State31 = State3;
State31.MDot = State3.MDot*(1-Cooling - 0.04);
% 6% cooling, 3% customer, 1% leakage

StateCoolant = State3;
StateCoolant.MDot = Cooling*State3.MDot;

%% Burner

[State39,MDotFuel] = EngineModelPkg.ComponentOnPkg.Burner(State31,Tt4Max,LHVFuel,EtaPoly);

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
State41.Ps = EngineModelPkg.IsenRelPkg.Ps_Pt(State41.Pt,State41.Mach,State41.Gam);
State41.Ts = EngineModelPkg.IsenRelPkg.Ts_Tt(State41.Tt,State41.Mach,State41.Gam);



%% HPT
if length(Spools.RPM) > 1
    [State5,HPTObject] = EngineModelPkg.ComponentOnPkg.Turbine(State41,HPCObject,EtaPoly);
else
    switch nargin
        case 2
            HPCObject.CompWork = HPCObject.ReqWork;
            HPCObject.TotalWork = HPCObject.ReqWork + EngSpecFun.ReqPower;
            HPCObject.ReqWork = HPCObject.TotalWork;
            [State5,HPTObject] = EngineModelPkg.ComponentOnPkg.Turbine(State41,HPCObject,EtaPoly);
        case 3
            HPCObject.CompWork = HPCObject.ReqWork;
            HPCObject.TotalWork = HPCObject.ReqWork + EngSpecFun.ReqPower;
            HPCObject.ReqWork = HPCObject.ReqWork + EngSpecFun.ReqPower - ElecPower;
            [State5,HPTObject] = EngineModelPkg.ComponentOnPkg.Turbine(State41,HPCObject,EtaPoly);
    end
end


%% IPT

% 3 turbine functionality not added yet
State55 = State5;

%% Power Turbine

if length(Spools.RPM) > 1 % Dedicated free shaft

    FreeShaftObject.TotalWork = EngSpecFun.ReqPower;
    FreeShaftObject.ReqWork = EngSpecFun.ReqPower;
    FreeShaftObject.RPM = Spools.RPM(end);
    [State7,FTObject] = EngineModelPkg.ComponentOnPkg.Turbine(State55,FreeShaftObject,EtaPoly,State0);
else % No Free Shaft, HPT also outputs power
    FreeShaftObject = "Nonexistent";
    FTObject = "Nonexistent";
    State7 = State55;
end




%% Nozzle

[State9,CoreThrust] = EngineModelPkg.ComponentOnPkg.PerfExNozzle(State7,State0,EtaPoly,"Prop");

%% Jet "Power"

JetPower = 0;

%% Outputs


EngineObject.States.StreamTube = State0;
EngineObject.States.Station1 = State1;
EngineObject.States.Station3 = State3;
EngineObject.States.Station31 = State31;
EngineObject.States.Station39 = State39;
EngineObject.States.Station4 = State4;
EngineObject.States.Station41 = State41;
EngineObject.States.Station5 = State5;
EngineObject.States.Station55 = State55;
EngineObject.States.Station7 = State7;

EngineObject.States.Station9 = State9;


EngineObject.FreeShaftObject = FreeShaftObject;
% EngineObject.IPCObject = IPCObject;
EngineObject.HPCObject = HPCObject;
EngineObject.HPTObject = HPTObject;
% EngineObject.IPTObject = IPTObject;
EngineObject.FTObject = FTObject;

switch nargin
    case 2
        if length(Spools.RPM) >1
            EngineObject.Power = FTObject.DelivWork+JetPower; % Watts
        else
            EngineObject.Power = HPTObject.DelivWork - HPCObject.CompWork+JetPower;
        end
    case 3
        if length(Spools.RPM) > 1
            EngineObject.Power = FTObject.DelivWork + JetPower + ElecPower; % Watts
        else
            EngineObject.Power = HPTObject.DelivWork - HPCObject.CompWork+JetPower + ElecPower;
        end
end

EngineObject.MDotAir = State0.MDot;

EngineObject.BSFC = MDotFuel/EngineObject.Power;
EngineObject.BSFC_Imp = EngineObject.BSFC*3.6e3/0.00134102*2.20462;
% EngineObject.JetPower = JetPower;
EngineObject.JetThrust = CoreThrust - RamDrag;
EngineObject.OPR = OPRActual;
EngineObject.Fuel.MDot = MDotFuel;
EngineObject.Fuel.FAR = MDotFuel/State3.MDot;


end





