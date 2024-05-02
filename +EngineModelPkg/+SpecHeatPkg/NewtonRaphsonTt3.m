function [Tt3] = NewtonRaphsonTt3(Tt1,heat)
%
% [Tt3] = NewtonRaphsonTt3(Tt1,heat)
% Written by Maxfield Arnson
% Updated 10/5/2023
%
% This function is essentially a numerical inverse of CpAir(). Given an
% amount of specific heat added and an initial temperature it will find the
% temperature the air is raised to. Data used for the curve fits is
% referenced in both CpAir() and CvAir().
%
%
% INPUTS:
%
% Tt1 = initial temperature of the air
%       size: scalar double
%
% heat = amount of specific heat added to the air
%       size: scalar double
%
%
% OUTPUTS:
%
% Tt3 = temperature air is raised to after adding 
%       size: scalar double

%% Newton Raphson iteration
Tt3 = Tt1*0.95;

while abs(f(Tt3,Tt1) - heat)/heat > 1e-3
    Tt3new = Tt3 - (f(Tt3,Tt1)-heat)/fprime(Tt3);
    Tt3 = Tt3new;
end

%% Curve fitted function 
    function eval = f(T1,T3)
        L = 233.0000;
        k = 1/210;
        y = 875;
        C = 993;
        eval = (T3*(C+L) + L*log(exp(k*(y-T3))+1)/k) - (T1*(C+L) + L*log(exp(k*(y-T1))+1)/k);
    end

    function eval = fprime(T3)
        L = 233.0000;
        k = 1/210;
        y = 875;
        C = 993;
        eval = -(C + L/(exp(k*(y-T3))+1)-2*L); 
    end

end

