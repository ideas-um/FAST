function [NewState] = Diffuser(OldState,DesiredM,InnerOuter,EtaPoly)
%
% [NewState] = Diffuser(OldState,DesiredM,InnerOuter,EtaPoly)
% Written by Maxfield Arnson
% Updated 10/3/2023
%
% This function computes the change in the airflow properties across a
% single compressor stage. 
%
%
% INPUTS:
%
% OldState = Flow state before diffusion
%       size: 1x1 struct
%
% DesiredM = Mach Number desired post diffusion
%       size: scalar double
%
% InnerOuter = Flag to decide which annular radius should remain constant
%           and which should vary to accomodate the area change
%       size: 1x1 string
%       options:
%           {"Inner"}
%           {"Outer"}
%
% EtaPoly = structure containing various efficiencies for the engine.
%           The diffuser uses EtaPoly.Diffusers
%       size: 1x1 struct
%
%
% OUTPUTS:
%
% NewState = flow state post diffusion
%           state.
%       size: 1x1 struct

%% Computations

A1 = OldState.Area;
M1 = OldState.Mach;
g = OldState.Gam;

Astar = EngineModelPkg.IsenRelPkg.Astar_A(A1,M1,g);
A2 = EngineModelPkg.IsenRelPkg.A_Astar(Astar,DesiredM,g);

Ro1 = OldState.Ro;
Ri1 = OldState.Ri;

switch InnerOuter
    case "Inner"
        Ri2 = Ri1;
        Ro2 = sqrt(Ri2^2+A2/pi);
    case "Outer"
        Ro2 = Ro1;
        Ri2 = sqrt(Ro2^2-A2/pi);
        if real(Ri2^2) < 0
            error('New diffuser area impossible to fit within outer radius. \n')
        end
end



%% Update State
NewState = OldState;
% MDot constant
% Tt constant
[NewState.Ts,NewState.Cp,NewState.Cv,NewState.Gam] = EngineModelPkg.IsenRelPkg.NewGamma(NewState.Tt,DesiredM,OldState.Gam);
NewState.Pt = OldState.Pt*EtaPoly.Diffusers;  % Some Total Pressure loss. Nearly Isentropic
NewState.Ps = EngineModelPkg.IsenRelPkg.Ps_Pt(NewState.Pt,DesiredM,NewState.Gam);
NewState.Mach = DesiredM;
NewState.Area = A2;
NewState.Ro = Ro2;
NewState.Ri = Ri2;
NewState.Mach = DesiredM;


end

