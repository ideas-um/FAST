    function [] = README()
%
% Copyright 2024 The Regents of the University of Michigan,
% The Integrated Design of Environmentally-friendly Aircraft Systems
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
% 
% README last updated: 29 mar 2024
% 
% -------------------------------------------------------------------------
%
% (I) Overview
%
%       The Battery Package is used to model battery (dis)charging in
%       FAST's mission analysis and is also responsible for re-sizing the
%       battery in an aircraft. This package is only run when a number of
%       cells in series and in parallel are provided via 
%       "Aircraft.Specs.Power.Battery.SerCells" and
%       "Aircraft.Specs.Power.Battery.ParCells". An initial battery
%       state-of-charge (SOC) is also required by including a double
%       between 0 and 100 in "Aircraft.Specs.Power.Battery.BegSOC".
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