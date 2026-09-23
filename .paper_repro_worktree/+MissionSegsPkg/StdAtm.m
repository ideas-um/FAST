function [T, P, Rho] = StdAtm(Alt)
%
% [T, P, Rho] = StdAtm(Alt)
% atmosphere model written by Max Arnson
% code vectorizing written by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 mar 2024
%
% Use the US standard atmosphere model to return static air conditions at a
% given altitude. The output array dimensions will be the same as the input
% array dimensions.
%
% INPUTS:
%     Alt - altitude above sea-level.
%           size/type/units: n-by-1 or 1-by-n / double / [m]
%
% OUTPUTS:                                          |
%     T   - air temperature.
%           size/type/units: n-by-1 or 1-by-n / double / [K]
%
%     P   - air pressure.
%           size/type/units: n-by-1 or 1-by-n / double / [Pa]
%
%     Rho - air density.
%           size/type/units: n-by-1 or 1-by-n / double / [kg / m^3]
%

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% pre-processing             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check altitude between sea-level and 100,000 m
if ((any(Alt < 0)) || (any(Alt > 100000)))
    
    % throw an error
    error("ERROR - StdAtm: altitude must be between 0 and 100,000 m.");
    
end

% number of altitudes provided
nalt = length(Alt);

% allocate memory for the results (density computed later)
T   = zeros(nalt, 1);
P   = zeros(nalt, 1);

% define physical quantities
g =   9.81; % gravity      [m /   s^2 ]
R = 287   ; % gas constant [J / (kg K)]

% get the altitudes in each regime/section of the atmosphere
Sec01 = (Alt >=     0) & (Alt <   11000);
Sec02 = (Alt >= 11000) & (Alt <   20000);
Sec03 = (Alt >= 20000) & (Alt <   32000);
Sec04 = (Alt >= 32000) & (Alt <   47000);
Sec05 = (Alt >= 47000) & (Alt <   51000);
Sec06 = (Alt >= 51000) & (Alt <   71000);
Sec07 = (Alt >= 71000) & (Alt <   85000);
Sec08 = (Alt >= 85000) & (Alt <= 100000);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% compute the atmospheric    %
% quantities at the altitude %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% section 01:      0 m to  11,000 m
if (any(Sec01))
    
    % compute the temperature at altitude
    T(Sec01) = 288.15 - 0.0065 .* Alt(Sec01);
    
    % start with sea-level pressure
    P0 = 101300;
    
    % compute the pressure at altitude
    P(Sec01) = P0 .* (T(Sec01) ./ 288.15) .^(-g / (R * -0.0065));
    
end

% section 02: 11,000 m to  20,000 m
if (any(Sec02))
    
    % an isothermal layer exists
    T(Sec02) = 216.65;
    
    % start with pressure at 11,000 m
    P0 = 2.2609e+04;
    
    % compute the pressure at altitude
    P(Sec02) = P0 .* exp(-g .* (Alt(Sec02) - 11000) ./ (R * T(Sec02)));
    
end

% section 03: 20,000 m to  32,000 m
if (any(Sec03))
    
    % compute the temperature at altitude
    T(Sec03) = 216.65 + 0.0010 .* (Alt(Sec03) - 20000);
    
    % start with pressure at 20,000 m
    P0 = 5.4731e+03;
    
    % compute the pressure at altitude
    P(Sec03) = P0 .* (T(Sec03) ./ 216.65) .^(-g / (R * 0.0010));
    
end

% section 05: 32,000 m to  47,000 m
if (any(Sec04))
    
    % compute the temperature at altitude
    T(Sec04) = 228.65 + 0.0028 .* (Alt(Sec04) - 32000);
    
    % start with pressure at 32,000 m
    P0 = 866.8940;
    
    % compute the pressure at altitude
    P(Sec04) = P0 .* (T(Sec04) ./ 228.65) .^ ( -g / (R * 0.0028));
    
end

% section 05: 47,000 m to  51,000 m
if (any(Sec05))
    
    % an isothermal layer exists
    T(Sec05) = 270.65;
    
    % start with pressure at 47,000 m
    P0 = 110.6427;
    
    % compute the pressure at altitude
    P(Sec05) = P0 .* exp(-g .* (Alt(Sec05) - 47000) ./ (R .* T(Sec05)));
    
end

% section 06: 51,000 m to  71,000 m
if (any(Sec06))
    
    % compute the temperature at altitude
    T(Sec06) = 270.65 - 0.0028 .* (Alt(Sec06) - 51000);
    
    % start with pressure at 51,000 m
    P0 = 66.7260;
    
    % compute the pressure at altitude
    P(Sec06) = P0 .* (T(Sec06) ./ 270.65) .^ (-g / (R * -0.0028));
    
end

% section 07: 71,000 m to  85,000 m
if (any(Sec07))
    
    % compute the temperature at altitude
    T(Sec07) = 214.65 - 0.0020 .* (Alt(Sec07) - 71000);
    
    % start with pressure at 71,000 m
    P0 = 3.9401;
    
    % compute the pressure at altitude
    P(Sec07) = P0 .* (T(Sec07) ./ 214.65) .^ (-g / (R * -0.0020));
    
end

% section 08: 85,000 m to 100,000 m
if (any(Sec08))
    
    % an isothermal layer exists
    T(Sec08) = 186.65;
    
    % start with pressure at 85,000 m
    P0 = 0.3615;
    
    % compute the pressure at altitude
    P(Sec08) = P0 .* exp(-g .* (Alt(Sec08) - 85000) ./ (R .* T(Sec08)));
    
end

% compute the density
Rho = P ./ (R .* T);

% ----------------------------------------------------------

end