function [] = README()
%
% Copyright 2024 The Regents of the University of Michigan,
% The Integrated Design of Environmentally-friendly Aircraft Systems
% Laboratory
% 
% Retrofit Package (+RetrofitPkg)
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
% README last updated: 3 may 2024
% 
% -------------------------------------------------------------------------
%
% (I)   Overview
%
%       The Retrofit package contains the main retrofit driver and an
%       example options initialization function. "Retrofitting" in this
%       context is defined as removing a portion of the design payload and
%       replacing the weight with batteries and electric motors.
% 
% -------------------------------------------------------------------------
%
% (II)  Usage
%
%       To retrofit an aircraft, a sized aircraft stucture (output from 
%       Main() and an options structure must be input into the driver. See
%       RetrofitPkg/ExampleOptions.m for required fields. Refer to the
%       RetrofitPkg/Retrofit.m function documentation for an IO guide.
%
% -------------------------------------------------------------------------
%
% (III) Warning
%
%       This package contains information that is essential to FAST's
%       functionality, and should not be altered by end users. Feel free to
%       create new options functions for any retrofits you wish to
%       investigate though!
%
% -------------------------------------------------------------------------
%
% end RetrofitPkg.README
%
end