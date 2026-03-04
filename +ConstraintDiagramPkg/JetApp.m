function [FAR] = JetApp(W_S, T_W, Aircraft)
%
% [FAR] = JetApp(W_S, T_W, Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 16 sep 2025
%
% derive the constraints for approach speed.
%
% INPUTS:
%     W_S      - grid of wing loading values.
%                size/type/units: m-by-p / double / [kg/m^2]
%
%     T_W      - grid of thrust-weight ratios.
%                size/type/units: m-by-p / double / [N/N]
%
%     Aircraft - information about the configuration being analyzed
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     FAR      - inequality constraints pertaining to the performance
%                requirement.
%                size/type/units: m-by-p / double / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% get the requirement type
ReqType = Aircraft.Specs.TLAR.ReqType;

% retrieve parameters from the aircraft structure
CL    = Aircraft.Specs.Aero.CL.Lnd;
Wl_W0 = Aircraft.Specs.Performance.Wland_MTOW;
Vapp  = Aircraft.Specs.Performance.Vels.App;


%% EVALUATE THE CONSTRAINT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% convert wing loading to english units
W_S = W_S .* UnitConversionPkg.ConvMass(1, "kg", "lbm") ./ UnitConversionPkg.ConvLength(1, "m", "ft") ^ 2;

if (ReqType == 0)
            
    % none needed
    FAR = zeros(size(W_S));

else
    
    % convert to ft/s
    Vapp = UnitConversionPkg.ConvVel(Vapp, "m/s", "ft/s");
    
    % compute the stall speed
    Vstall = Vapp / 1.3;
    
    % compute the required wing loading at sea level
    W_Sreq = 0.5 * 0.002377 * Vstall ^ 2 * CL / Wl_W0;
    
    % apply as a constraint
    FAR = W_S - W_Sreq;
    
end
    
% ----------------------------------------------------------

end