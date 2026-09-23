function [] = README()
%
% Copyright 2024 The Regents of the University of Michigan,
% The Integrated Design of Environmentally-friendly Aircraft Systems
% Laboratory
% 
% Unit Conversion Package (+UnitConversionPkg)
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
% README last updated: 23 apr 2024
% 
% -------------------------------------------------------------------------
%
% (I)   Overview
%
%       The Unit Conversion Package contains six functions which convert
%       various units from one to another. These functions can convert
%       units for the following:
%
%           (a) Length
%           (b) Velocity
%           (c) Mass
%           (d) Force
%           (e) Temperature
%           (f) Thrust Specific Fuel Consumption
% 
% -------------------------------------------------------------------------
%
% (II)  Units
%
%       Units supported for each conversion function are specified in the
%       particular function's documentation. The strings used to identify
%       each unit are identical to those used in Matlab's Aerospace
%       Toolbox.
% 
% -------------------------------------------------------------------------
%
% (III) Usage
%
%       To use a unit conversion function, it must be called using the unit
%       conversion package, and include the number to be converted, the old
%       units, and the desired units. For example, to convert 5 kilograms
%       to pound mass, the following code would be run:
%
%           >> UnitConversionPkg.ConvMass(5,'kg','lbm')
%
%       To convert 300 Fahrenheit to Celsius, the following code would be
%       run:
%
%           >> UnitConversionPkg.ConvTemp(300,'F','C')
%
%       The functions can handle scalars, vectors, and arrays. They return
%       a matrix with size equal to the input matrix.
%
% -------------------------------------------------------------------------
%
% (IV)  Warning
%
%       This package contains information that is essential to FAST's
%       functionality, and should not be altered by end users.
%
% -------------------------------------------------------------------------
%
% end UnitConversion.README
%
end