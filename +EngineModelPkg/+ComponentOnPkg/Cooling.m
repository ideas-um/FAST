function [State41] = Cooling(State4,StateCoolant,EtaPoly)
%
% [State41] = Cooling(State4,StateCoolant,EtaPoly)
% Written by Maxfield Arnson
% Updated 10/3/2023
%
% This function mixes two incoming flow states. It is primarily used when
% hot air is mixed with cooler air to protect the materials in the
% turbomachinery or combustor/burner.
% As of the last update, this function is NOT implemented in the cycle code
% and needs updates.
%
%
% INPUTS:
%
% State4 = hot flow state coming into the cooling mixer
%       size: 1x1 struct
%
% StateCoolant = cool flow state coming into the mixer
%       size: 1x1 struct
%
% EtaPoly = structure containing various efficiencies for the engine.
%           The cooling function uses EtaPoly.Mixing
%       size: 1x1 struct
%
%
% OUTPUTS:
%
% State41 = flow state post mixing
%       size: 1x1 struct

%% Mix Air States
State41 = State4;
State41.MDot = State41.MDot + StateCoolant.MDot;
Ht41 = State4.Cp*State4.Tt*State4.MDot+ StateCoolant.Cp*StateCoolant.Tt*StateCoolant.MDot;


State41.Tt = Ht41/State41.MDot/EngineModelPkg.SpecHeatPkg.CpAir(State4.Tt*State4.MDot/(State41.MDot)+StateCoolant.Tt*StateCoolant.MDot/State41.MDot);
[State41.Ts,State41.Cp,State41.Cv,State41.Gam] = EngineModelPkg.IsenRelPkg.NewGamma(State41.Tt,State41.Mach,State4.Gam);
State41.Pt = State41.Pt*EtaPoly.Mixing;
State41.Ps = EngineModelPkg.IsenRelPkg.Ps_Pt(State41.Pt,State41.Mach);



area updates here:


%{
syms Mc Uc Pc Ac M1 U1 P1 A1 M2 U2 P2 R T2
eq1 = sqrt(2)/2*(Mc*Uc + Pc*Ac) + M1*U1 + P1*A1 == (M1+Mc)*U2+P2*A1;
eq2 = R*T2*A1*U2/P2 == M1+Mc;


answer = solve(eq1,eq2,[U2,P2])



%}

end

