function [] = README()
%
% Copyright 2024 The Regents of the University of Michigan,
% The Integrated Design of Efficient Aerospace Systems
% Laboratory
% 
% Battery Package (+BatteryPkg)
%
% Written by the IDEAS Lab at the University of Michigan.
% https://ideas.engin.umich.edu
%
% Principal Authors:
%     Paul Mokotoff, prmoko@umich.edu
%     Max Arnson, marnson@umich.edu
%
% Principal Investigator:
%     Dr. Gokcin Cinar, cinar@umich.edu
%
% Additional Contributors:
%     Huseyin Acar
%     Nawa Khailany
%     Janki Patel
%     Michael Tsai
%     Yipeng Liu
% 
% README last updated: 21 Oct 2025
% 
% -------------------------------------------------------------------------
%
% (I) Overview
%
%       The Battery Package is used to model battery (Dis)Charging(.m) in
%       FAST's mission analysis and is also responsible for re-sizing the
%       battery in an aircraft. This package is only run when a number of
%       cells in series and in parallel are provided via 
%       "Aircraft.Specs.Power.Battery.SerCells" and
%       "Aircraft.Specs.Power.Battery.ParCells". An initial battery
%       state-of-charge (SOC) is also required by including a double
%       between 0 and 100 in "Aircraft.Specs.Power.Battery.BegSOC".
%       The battery lifespan (SOH) prediction is valid by using the
%       "CyclAging.m" which is an empirical model for calendar aging
%       only. The "GroundCharge.m" function is used to analysis varied
%       aircraft charging strategy by input time and desire charge power.
% 
% -------------------------------------------------------------------------
% (II) Warning
%
%       This package contains information that is essential to FAST's
%       functionality, and should not be altered by end users.
%
% -------------------------------------------------------------------------
%
% end BatteryPkg.README
%
end