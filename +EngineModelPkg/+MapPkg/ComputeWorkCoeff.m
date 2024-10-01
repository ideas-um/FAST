function [Psi] = ComputeWorkCoeff(Phi)
%
% Compute stage loading as a function of flow parameter
% Phi = normalized flow coefficient
PolyPsi = [-4.27483160909134	10.6209227666702	-12.0258466329846	7.82482168856455	-1.17299927309400];   
%PolyPsi = [-1.87500000000000	3.74999999999999	-0.874999999999997];
Psi = polyval(PolyPsi,Phi);
end

