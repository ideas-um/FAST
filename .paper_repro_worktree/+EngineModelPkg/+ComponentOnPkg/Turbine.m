function [NewState,TurbineObject] = Turbine(OldState,CompressorObject,EtaPoly,Ambient)
%
% [NewState,TurbineObject] = Turbine(OldState,CompressorObject,EtaPoly)
% Written by Maxfield Arnson
% Updated 10/5/2023
%
% This function computes the change in the airflow properties across a
% turbine. It outputs the new state and a turbine object describing
% the properties of the machinery extracting energy from the air.
%
%
% INPUTS:
%
% OldState = Flow state coming into the turbine
%       size: 1x1 struct
%
% CompressorObject = Compressor that this turbine drives. It is a
%           structure describing required work, compressor ratios,
%           RPM, number of stages, etc. The turbine uses the RPM and the
%           work required
%       size: 1x1 struct
%
% EtaPoly = structure containing various efficiencies for the engine.
%           The turbine and its child functions use EtaPoly.Turbines
%       size: 1x1 struct
%
% OldState = [OPTIONAL] Flow state outside of the engine. Also acts as a
%           flag to tell the code whether this turbine is a free turbine or not
%       size: 1x1 struct
%
%
% OUTPUTS:
%
% NewState = flow state post turbine
%       size: 1x1 struct
%
% TurbineObject = structure similar to CompressorObject that describes all
%           the properties of the turbine and stores flow states between turbine
%           stages
%       size: 1x1 struct


%% Read Inputs and Initialize

TurbRPM = CompressorObject.RPM;

Tt1 = OldState.Tt;

Rp = 0.5*(OldState.Ro+OldState.Ri);
w = TurbRPM*2*pi/60;


%% Define total temperature after the turbine

% perform the switch case that tells the turbine if we should extract a
% specific amount of work from the turbine or extract as much work as
% possible by using pressure energy until a desired pressure (usually
% atmospheric or slightly above it) is reached
switch nargin
    case 4
        PiTurb = Ambient.Pt/OldState.Pt;
        g = OldState.Gam;
        TauTurb = (PiTurb)^((g-1)/g);

        Tt3 = TauTurb*OldState.Tt;
        TurbWork = EngineModelPkg.SpecHeatPkg.CpAir(Tt3,Tt1)/EtaPoly.Turbines;
    case 3
        TurbWork = CompressorObject.ReqWork/OldState.MDot/EtaPoly.Turbines;
        Tt3 = EngineModelPkg.SpecHeatPkg.NewtonRaphsonTt3(Tt1,TurbWork);
end

%% Find Number of stages
% calculate total loading and limit stage loading to 2
Loading = TurbWork/(w*Rp)^2;

NStages = real(ceil(Loading/2));

if NStages > 7
   NStages = 7;
end

% use number of stages to define a delta temp drop per stage
dT = (Tt1 - Tt3)/NStages;

%% Design Stages

% first stage is always choked, resultant stages are not
CurState = OldState;
TurbineObject.States.Entry = CurState;
Choked = true;
[CurState,Pi(1),Tau(1)] = EngineModelPkg.ComponentOnPkg.TurbStg(CurState,Tt1-dT,TurbRPM,Choked,EtaPoly);
TurbineObject.States.Stage_1 = CurState;

Choked = false;
for ii = 2:NStages
    Tt3 = CurState.Tt - dT;
    [CurState,Pi(ii),Tau(ii)] = EngineModelPkg.ComponentOnPkg.TurbStg(CurState,Tt3,TurbRPM,Choked,EtaPoly);
    TurbineObject.States.("Stage_"+ii) = CurState;
end
TurbineObject.States.Exit = TurbineObject.States.("Stage_"+NStages);

CPR = cumprod(Pi); CPR = CPR(end);
CTR = cumprod(Tau); CTR = CTR(end);
%% Assign Outputs
NewState = CurState;

% Create Turbine Object information
TurbineObject.NoStages = NStages;
TurbineObject.CPR = CPR;
TurbineObject.CTR = CTR;
TurbineObject.DelivWork = TurbWork*NewState.MDot;
TurbineObject.RPM = TurbRPM;


end