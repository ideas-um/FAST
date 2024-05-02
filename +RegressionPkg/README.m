function [] = README()
%
% Copyright 2024 The Regents of the University of Michigan,
% The Integrated Design of Environmentally-friendly Aircraft Systems
% Laboratory
% 
% Regression Package (+RegressionPkg)
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
%       The regression package contains functions which perform the
%       non-parametric Gaussian Process Regression used to predict aircraft
%       characteristics during the aircraft sizing process. Users may
%       perform regressions on their own, or search the database for values
%       they would like. Tutorials are coming to FAST soon, as well as
%       updated functional documentation for the regression package. If a
%       user would like to use the regressions outside of the sizing code
%       before the tutorial is released, they may inspect the existing
%       function documentation in the following files
%
%       RegressionPkg.NLGPR
%       RegressionPkg.SearchDB
%
%       And look for example regression calls in
%       DataStructPkg.SpecProcessing. The developers recommend looking at
%       lines 413 and 414 in that code for a simple one-input one-output
%       example.
%       
% 
% -------------------------------------------------------------------------
% (II) Warning
%
%       This package contains information that is essential to FAST's
%       functionality, and should not be altered by end users.
%
% -------------------------------------------------------------------------
%
% end RegressionPkg.README
%
end