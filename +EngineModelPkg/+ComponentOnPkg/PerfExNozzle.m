function [NewState,Thrust] = PerfExNozzle(OldState,Ambient,EtaPoly,Type)
%
% [NewState,Thrust] = PerfExNozzle(OldState,Ambient,EtaPoly,Type)
% Written by Maxfield Arnson
% Updated 10/5/2023
%
% This function computes the change in the airflow properties through a
% nozzle and outputs the thrust produced. It is a misnomer as it does not
% perfectly expand the air as of the latest update
%
%
% INPUTS:
%
% OldState = flow state coming into nozzle
%       size: 1x1 struct
%
% Ambient = flow state of the air before entering the engine.
%       size: scalar double
%
% EtaPoly = structure containing various efficiencies for the engine.
%           The nozzle uses EtaPoly.Nozzles
%       size: 1x1 struct
%
% Type = flag that tells the function if this is a core or bypass nozzle.
%           This affects how much to underexpand the air and which annular
%           radius to change
%       size: 1x1 string
%       options:
%           {"Core"}
%           {"Bypass"}
%
% OUTPUTS:
%
% NewState = flow state at the nozzle throat
%       size: 1x1 struct
%
% Thrust = gross thrust produced by this nozzle
%       size: scalar double




%% Input Handling

% underexpand air at SLS design point per Noah Listgarten's (AMES)
% suggestion. If design point is TOC these lines will need to be changed
% and pass an input to decide whether to underexpand or not
switch Type
    case "Bypass"
        NPR = 1.1;
    case "Core"
        NPR = 1.3;
    case "Prop"
        NPR = 1;
end

%NPR = 1;

%% Calculate ideal and real temperature drops

R = 287;
Psa = EngineModelPkg.IsenRelPkg.Ps_Pt(Ambient.Pt,Ambient.Mach,Ambient.Gam);
Ps9 = Psa*NPR;
Tt9 = OldState.Tt;
Pt5 = OldState.Pt;
g = OldState.Gam;
Cp = OldState.Cp;


Ts9i = Tt9*(Ps9/Pt5)^((g - 1)/g);


u9i = sqrt((Tt9 - Ts9i)*2*Cp);

% Throw an error if there is not enough energy in the flow to properly
% expand the air. This error will result if the user specified Tt4 is too
% low

if real(u9i^2) < 0
    error('Cannot expand air to atmospheric pressure. Total temperature too low.')
end

u9 = u9i*EtaPoly.Nozzles;
Ts9 = Tt9 - u9^2/2/Cp;
Pt9 = Ps9*(Tt9/Ts9)^(g/(g - 1));
M9 = u9/sqrt(g*R*Ts9);
% 
% NPR = Pt5/Ps9;
% u9 = sqrt(2 * Cp*Tt9*EtaPoly.Nozzles*(1 - (1/NPR)^((g-1)/g)));
% 
% Ts9 = Tt9 - u9^2/2/Cp;
% M9 = u9/sqrt(g*R*Ts9);
% 
% Pt9 = Pt5;

if M9 > 1
    M9 = 1;
    u9 = M9*sqrt(g*R*Ts9);
    Ts9 = Tt9 - u9^2/2/Cp;
    Ps9 = Pt9/(Tt9/Ts9)^(g/(g - 1));
end

%% Assign Outputs
NewState = OldState;
NewState.Tt = Tt9;
NewState.Ts = Ts9;
NewState.Pt = Pt9;
NewState.Ps = Ps9;
NewState.Mach = M9;
NewState.Cp = EngineModelPkg.SpecHeatPkg.CpAir(Ts9);
NewState.Cv = EngineModelPkg.SpecHeatPkg.CvAir(Ts9);
NewState.Gam = NewState.Cp/NewState.Cv;

Rhos9 = Ps9/Ts9/R;
NewState.Area = NewState.MDot/u9/Rhos9;
Thrust = NewState.MDot*u9 + (Ps9 - Psa)*NewState.Area;


% if the nozzle is a bypass nozzle, reduce outer radius
% if it is a core nozzle, set inner radius to zero and find the resultant
% outer radius from the exhaust area
switch Type
    case "Bypass"
        NewState.Ro = sqrt(NewState.Area/pi-NewState.Ri^2);
    otherwise
        NewState.Ri = 0;
        NewState.Ro = sqrt(NewState.Area/pi);
end



end