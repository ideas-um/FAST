function [Eng] = EngineLapse(SLS, aclass, Rho)
%
% [Eng] = EngineLapse(SLS, aclass, Rho)
% written by Paul Mokotoff, prmoko@umich.edu
% updated 08 mar 2024
%
% Estimate the thrust available at a based on the SLS thrust and
% current flight conditions.
%
% INPUTS:
%     SLS    - sea-level static engine:
%                  a) thrust for a turbojet/turbofan
%                  b) power for a turboprop/piston
%              size/type/units: 1-by-1 / double / [N] (a) or [W] (b)
%
%     aclass - aircraft class, either a:
%                  a) "TurboJet"
%                  b) "TurboProp"
%                  c) "Piston"
%              size/type/units: 1-by-1 / string / []
%
%     Rho    - density at the given altitude.
%              size/type/units: m-by-n / double / [kg / m^3]
%
% OUTPUTS:
%     Eng    - lapsed engine, either:
%                  a) thrust for a turbojet/turbofan
%                  b) power for a turboprop/piston
%              size/type/units: m-by-n / double / [N] (a) or [W] (b)
%

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% define constants           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% standard sea-level pressure
[~, ~, RhoSL] = MissionSegsPkg.StdAtm(0);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% compute the thrust lapse   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the density ratio
RhoRatio = Rho ./ RhoSL;

% select an appropriate power to raise the density ratio to
if      (strcmpi(aclass, "Turbofan" ) == 1)
    m = 1.0;
    
elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
        (strcmpi(aclass, "Piston"   ) == 1) )
    m = 0.0;
    
end

% get lapsed thrust/power output
Eng = SLS .* RhoRatio .^ m;

% ----------------------------------------------------------

end