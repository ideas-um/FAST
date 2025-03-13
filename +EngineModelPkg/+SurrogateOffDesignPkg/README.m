function [] = README()
%
% Copyright 2024 The Regents of the University of Michigan,
% The Integrated Design of Environmentally-friendly Aircraft Systems
% Laboratory
% 
% Surrogate Off Desing Package (+EngineModelPkg/+SurrogateOffDesignPkg)
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
% README last updated: 13 mar 2025
% 
% -------------------------------------------------------------------------
%
% (I) Overview
%
%       The surrogate off-design package holds several files which store,
%       modify, and test data from the ICAO emissions database. The package
%       takes .xlsx spreadsheets and turns them into FAST datastructures,
%       similar to the FAST Aerobase stored in the Database package.
%       Additionally it houses a testing script where multiple methods of
%       predicting off design coefficients for the SimpleOffDesign.m method
%       to use if a user does not prescribe them in their specification
%       file. This database is called during DatastructPkg.SpecProcessing
%       when running a sizing analysis.
% 
% -------------------------------------------------------------------------
% (II) Warning
%
%       This package contains information that is essential to FAST's
%       functionality, and should not be altered by end users.
%
% -------------------------------------------------------------------------
%
% end EngineModelPkg.SurrogateOffDesignpkg.README
%
end