function [] = README()
%
% Copyright 2024 The Regents of the University of Michigan,
% The Integrated Design of Efficient Aerospace Systems
% Laboratory
% 
% Test Cases Package (+TestCasesPkg) within the +SafetyPkg
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
% README last updated: 07 Nov 2025
% 
% -------------------------------------------------------------------------
%
% (I) Overview and Use
%
% Test TestCasesPkg in the SafetyPkg allows users to execute a fault tree
% analysis (FTA) on a simple system architecture to understand how the code
% works.
%
% To utilize any of these examples, load the data from the .mat file into
% your workspace. Then, call the FTA analysis:
%
%     [Pfail, FailModes] = SafetyPkg.FaultTreeAnalysis(Arch, Components);
%
% To understand how the architecture matrix was constructed and what the
% different values mean, refer to the README in the SafetyPkg.
%
% -------------------------------------------------------------------------
%
% end TestCasesPkg.README
%
end