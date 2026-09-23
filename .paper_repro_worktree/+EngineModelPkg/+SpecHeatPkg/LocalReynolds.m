function [Re] = LocalReynolds(FlowState)

R = 287;

Ts = FlowState.Ts;
L = FlowState.Ro-FlowState.Ri;
rho = FlowState.Ps/R/Ts;

sigma = 350e-12;
kb = 1.380639e-23;
m = 0.02869/6.022e23;
mu = 1.106*5/16/sigma^2*sqrt(kb*m*Ts/pi);


u = FlowState.Mach*sqrt(FlowState.Gam*Ts*R);

Re = rho*u*L/mu;

end

