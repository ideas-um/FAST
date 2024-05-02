function [NewState,Work,Taus] = CompStg(OldState,EtaPoly,StagePR,RPM,Fan)
%
% [NewState,Work,Taus] = CompStg(OldState,EtaPoly,StagePR)
% Written by Maxfield Arnson
% Updated 10/5/2023
%
% This function computes the change in the airflow properties across a
% single compressor stage. 
%
%
% INPUTS:
%
% State21 = Flow state coming into the compressor stage. 
%       size: 1x1 struct
%
% EtaPoly = structure containing various efficiencies for the engine.
%           The compressor stage uses EtaPoly.Compressors
%       size: 1x1 struct
%
% StagePR = Pressure ratio across this stage of a compressor
%       size: scalar double
%
%
% OUTPUTS:
%
% NewState = flow state post compression. Mimics the format of the inputted
%           state.
%       size: 1x1 struct
%
% Work = work required to drive this compression stage
%       size: scalar double
%
% Taus = stagnation temperature ratio across this compression stage
%       size: scalar double
%



%% Assumptions and initializations
if Fan
    ec = EtaPoly.Fan;
else
ec = EtaPoly.Compressors; % Stage Polytropic Efficiency
end
g1 = OldState.Gam;
R = 287;

M1 = OldState.Mach;
A1 = OldState.Area;
Tt1 = OldState.Tt;
Pt1 = OldState.Pt;
Ts1 = OldState.Ts;
Rhos1 = OldState.Ps/Ts1/R;

%% Prescribed Stage Pressure Ratio
pis = StagePR;

% calculate resultant temperature ratio and mach number
Taus = pis^((g1-1)/g1);
M3 = M1*sqrt(1/(Taus*(1+(g1-1)*M1^2/2)-(g1-1)*M1^2/2));

%% New Flowpath Area

Tt3 = Taus*Tt1;
[Ts3,Cp3,Cv3,g3] = EngineModelPkg.IsenRelPkg.NewGamma(Tt3,M3,g1);

Pt3 = pis*Pt1;
Ps3 = EngineModelPkg.IsenRelPkg.Ps_Pt(Pt3,M3,g3);
Rhos3 = Ps3/R/Ts3;

A3 = A1*Rhos1/Rhos3;

% New Radii
Ro3 = OldState.Ro;
Ri3 = sqrt(Ro3^2-A3/pi);

% throw an error if the resultant inner radius is smaller than zero
if real(Ri3^2) < 0
    error('Area impossible to fit within outer radius.')
end

%% Work

Work = EngineModelPkg.SpecHeatPkg.CpAir(Tt1,Tt3)*OldState.MDot/ec;


%% Update State
NewState = OldState;
NewState.MDot = OldState.MDot;
NewState.Pt = Pt3;
NewState.Tt = Tt3;
NewState.Ts = Ts3;
NewState.Mach = M3;
NewState.Cp = Cp3;
NewState.Cv = Cv3;
NewState.Gam = g3;
NewState.Ps = EngineModelPkg.IsenRelPkg.Ps_Pt(NewState.Pt,NewState.Mach,NewState.Gam);
NewState.Area = A3;
NewState.Ro = Ro3;
NewState.Ri = Ri3;

%% Add compressor map variables

% what should phi be
NewState.Rp     = (Ro3+Ri3)/2;
R = 287;
w               = RPM/60*2*pi;
U = w*NewState.Rp;

Rhos3 = NewState.Ps/R/Ts3;
Va = OldState.MDot/Rhos3/NewState.Area;




RU = 8314;

PStd = 101325.353;
TStd = 288.15;





NewState.Eta    = (Ts1*StagePR^((g3-1)/g3)*EngineModelPkg.SpecHeatPkg.CpAir(Ts1) - Ts1*EngineModelPkg.SpecHeatPkg.CpAir(Ts1))/Work*NewState.MDot;
%NewState.Psi    = EngineModelPkg.SpecHeatPkg.CpAir(Ts1,Ts3)/(w*NewState.Rp)^2;
NewState.Psi    = EngineModelPkg.SpecHeatPkg.CpAir(Tt1,Tt3)/U^2;
NewState.MNorm  = NewState.MDot*sqrt(Ts3/TStd)/(NewState.Ps/PStd);  
NewState.NNorm  = RPM/sqrt(Ts3/TStd);
NewState.Phi    = R*60/(2*pi*NewState.Area*NewState.Rp)*(NewState.MNorm/PStd*sqrt(TStd))/(NewState.NNorm/sqrt(TStd));
NewState.Zeta   = NewState.Psi/NewState.Eta;






end