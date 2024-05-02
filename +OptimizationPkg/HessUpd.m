function [H] = HessUpd(H, s, y)
%
% [H] = HessUpd(H, s, y)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 mar 2024
%
% Update the hessian using a symmetric rank 2 update.
%
% INPUTS:
%     H - original hessian.
%         size/type/units: n-by-n / double / []
%
%     s - difference between design variable iterates.
%         size/type/units: n-by-1 / double / []
%
%     y - difference between gradients.
%         size/type/units: n-by-1 / double / []
%
% OUTPUTS:
%     H - updated  hessian.
%         size/type/units: n-by-n / double / []
%

% ----------------------------------------------------------

% compute the inner product of s and y
sy = s' * y;

% muliply the hessian and s
Hs = H * s;

% compute a quadratic scaling term
qterm = Hs' * s;

% compute the scale factor (and damp if needed)
if (sy >= 0.2 * qterm)
    theta = 1.0;
    
else
    theta = 0.8 * qterm / (qterm - sy);
    
end

% compute a residual-like vector
r = theta .* y + (1 - theta) .* Hs;

% update the hessian
H = H + r * r' ./ (r' * s) - Hs * Hs' ./ qterm;

% ----------------------------------------------------------
    
end