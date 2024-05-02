function [State2,State21,State13,State25,FanSysObject] = FanSystem(State1,FanSysObject,OPR,Spools,BPR,EtaPoly)
%
% [State2,State21,State13,State25,FanSysObject] = FanSystem(State1,FanSysObject,OPR,Spools,BPR,EtaPoly)
% Written by Maxfield Arnson
% Updated 10/4/2023
%
% This function designs a fan system comprised of the fan and the low pressure
% compressor. It parses architectures such that the proper LPC is designed,
% whether that be a geared system, a boosted system, or just a fan without
% an LPC attached to the shaft.
%
%
% INPUTS:
%
% State1 = Flow state coming into the fan just after the inlet.
%       size: 1x1 struct
%
% FanSysObject = Fan object created in the Turbofan wrapper. This structure
%           is primitive at this point and only contains architecture
%           information
%       size: 1x1 struct
%
% OPR = Pressure ratio desired between post inlet and post LPC
%       size: scalar double
%
% Spools = structure containing the number of spools in the engine and the
%           RPMs they spin at
%       size: 1x1 struct
%
% BPR = Engine bypass ratio
%       size: scalar double
%
% EtaPoly = structure containing various efficiencies for the engine.
%           The fan system uses EtaPoly.Fan and EtaPoly.Compressors
%       size: 1x1 struct
%
%
% OUTPUTS:
%
% State2 = flow state immediately post fan
%       size: 1x1 struct
%
% State21 = flow state identical to State2 with the exception of area,
%           radii, and MDot. State21 is core airflow
%       size: 1x1 struct
%
% State13 = flow state identical to State2 with the exception of area,
%           radii, and MDot. State13 is bypass airflow
%       size: 1x1 struct
%
% State25 = flow state post booster or LPC depending on architecture. If
%           there are no compressors besides the fan on this spool, State25 = State21
%       size: 1x1 struct
%
% FanSysObject = structure describing the breakdown in work, compression,
%           RPM, etc within the Fan, LPC, boosters, gearing if applicable
%       size: 1x1 struct
%

%% Compute
% Run the fan first
FPR = FanSysObject.FanObject.Pi;
Fan = true;
[CurState,FanWork,TauFan] = EngineModelPkg.ComponentOnPkg.CompStg(State1,EtaPoly,FPR,FanSysObject.FanObject.RPM,Fan);

% Divide between Bypass and core air based on BPR
State2 = CurState;
State21 = CurState;
State21.MDot = CurState.MDot/(1+BPR);
State21.Area = CurState.Area/(1+BPR);
State13 = State21;
State13.MDot = State21.MDot*BPR;
State13.Area = State21.Area*BPR;

State21.Ro = sqrt(State21.Area/pi);
State21.Ri = 0;

State13.Ri = State21.Ro;
State13.Ro = sqrt(State13.Area/pi+State13.Ri^2);

FanSysObject.FanObject.NoStages = 1;
FanSysObject.FanObject.ReqWork = FanWork;
FanSysObject.FanObject.Tau = TauFan;


% create an additional compressor connected to the N1 shaft based on user
% inputs. this could be a booster (ungeared N1 comppressor), an LPC (geared N1 compressor), or
% neither (only fan on N1 shaft)

PiN1 = 0.5*(OPR/FPR)^(1/(Spools.Count)); % without this factor of 0.5, the model predicts too many LP stages and will require a massive LPT.
if FanSysObject.Boosted && FanSysObject.Geared
    error("A turbofan cannot have both a booster and a geared fan. Please double check inputs")

elseif FanSysObject.Boosted % Booster
    BoosterRPM = FanSysObject.BoosterObject.RPM;
    [State25,FanSysObject.BoosterObject] = EngineModelPkg.ComponentOnPkg.Compressor(State21,PiN1,BoosterRPM,EtaPoly);
    FanSysObject.ReqWork = FanSysObject.FanObject.ReqWork+FanSysObject.BoosterObject.ReqWork;
    FanSysObject.Tau = FanSysObject.FanObject.Tau*FanSysObject.BoosterObject.Tau;
    FanSysObject.Pi = FanSysObject.FanObject.Pi*FanSysObject.BoosterObject.Pi;
    FanSysObject.RPM = BoosterRPM;
elseif FanSysObject.Geared % LPC
    LPCRPM = FanSysObject.LPCObject.RPM;
    [State25,FanSysObject.LPCObject] = EngineModelPkg.ComponentOnPkg.Compressor(State21,PiN1,LPCRPM,EtaPoly);
    FanSysObject.ReqWork = FanSysObject.FanObject.ReqWork+FanSysObject.LPCObject.ReqWork;
    FanSysObject.Tau = FanSysObject.FanObject.Tau*FanSysObject.LPCObject.Tau;
    FanSysObject.Pi = FanSysObject.FanObject.Pi*FanSysObject.LPCObject.Pi;
    FanSysObject.RPM = LPCRPM;
else % no booster or LPC
    State25 = State21;
    FanSysObject.ReqWork = FanSysObject.FanObject.ReqWork;
    FanSysObject.Tau = FanSysObject.FanObject.Tau;
    FanSysObject.Pi = FanSysObject.FanObject.Pi;
    FanSysObject.RPM = FanSysObject.FanObject.RPM;
end


end











