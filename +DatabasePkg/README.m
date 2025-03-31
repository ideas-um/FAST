function [] = README()
%
% Copyright 2024 The Regents of the University of Michigan,
% The Integrated Design of Efficient Aerospace Systems
% Laboratory
% 
% Database Package (+DatabasePkg)
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
%       The database package contains the IDEAS Lab historical databases.
%       These are used to perform regressions during the aircraft sizing
%       process. Running the command:
%
%       >> load(join(["+DatabasePkg","IDEAS_DB.mat"],filesep)
%
%       Or simply double-clicking on IDEAS_DB.mat in the file explorer will
%       load the databases into the workspace. Browse through them at your
%       convenience. The FanUnitsReference and PropUnitsReference variables
%       are data structures identical to the aircraft found in the database
%       but instead of numerical values in their fields, they will have the
%       units that the data is stored as. They can be inspected to ensure
%       that a user is aware of the units stored in the other structures.
%       To see an engine's units, inspect
%       FanUnitsReference.Specs.Propulsion.Engine or
%       PropUnitsReference.Specs.Propulsion.Engine
% 
% -------------------------------------------------------------------------
% (II) Warning
%
%       This package contains information that is essential to FAST's
%       functionality, and should not be altered by end users. However,
%       feel free to download the excel files
%
%       JMPInputSheetFANS.xlsx
%       JMPInputSheetPROPS.xlsx
%
%       If you would like to perform any statistical analysis in software
%       such as JMP, or you would like to simply visualize the data.
%
% -------------------------------------------------------------------------
%
% end DatabasePkg.README
%
end