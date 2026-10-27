function [] = README()
%
% Copyright 2024 The Regents of the University of Michigan,
% The Integrated Design of Efficient Aerospace Systems
% Laboratory
% 
% Data Structure Package (+DataStructPkg)
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
%     Yi-Chih (Arenas) Wang
%     Miranda Stockhausen
%     Emma Cassidy
%     Nawa Khailany
%     Janki Patel
%     Michael Tsai
%     Vaibhav Rau
% 
% README last updated: 27 oct 2026
% 
% -------------------------------------------------------------------------
%
% (I) Overview
%
%       The Data Structure Package is responsible for processing
%       information stored in the aircraft structure when running fast. It
%       contains functions which instantiate any variables not specified by
%       a user, in addition to functions which fill out unknown values
%       prior to aircraft sizing.
%
%       PreSpecProcessing initializes missing fields, including fields in
%       partially supplied nested structures, without replacing user values.
%       SpecProcessing replaces NaNs with defaults or regression results.
%       The default aerodynamic method is AerodynamicsPkg.ConstantLD;
%       aerodynamic calibration factors default to 1. Battery model inputs
%       remain NaN unless supplied; they are not inferred by this package.
% 
% -------------------------------------------------------------------------
% (II) Warning
%
%       This package contains information that is essential to FAST's
%       functionality, and should not be altered by end users.
%
% -------------------------------------------------------------------------
%
% end DataStructPkg.README
%
end

