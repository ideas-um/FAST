function [] = README()
%
% Copyright 2024 The Regents of the University of Michigan,
% The Integrated Design of Environmentally-friendly Aircraft Systems
% Laboratory
% 
% Engine Modeling Package (+EngineModelPkg)
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
% README last updated: 3 apr 2024
% 
% -------------------------------------------------------------------------
%
% (I) Additional Documentation
%
% For additional documentation, see package-specific README files. These
% READMEs will include guides/tutorials or answer questions regarding
% specific aspects of the engine model. A full list of packages and a brief 
% description is included below, followed by a documentation command 
% example.
%
%     (1) Package List
%
%             (a) +AircraftModelingPkg
%                    This package contains information regarding completed
%                    aircraft studies. These studies may include large .dat
%                    or .mat files with information produced by designing
%                    hundreds or thousands of aircraft variants.
%
% 	          (a) +ComponentOnPkg
% 	          	    Contains on-design component models for the engine 
%                   cycle model such as the compressor, burner, etc.
%
% 	          (b) +CycleModelPkg
% 	          	    Contains turbofan and turboprop cycle wrappers. These 
%                   wrappers call the component models and parse inputs 
%                   from the specification file.
%
% 	          (c) +EngineSpecsPkg
% 	          	    Stores specification files, including an example for 
%                   users to reference when creating their own.
%
% 	          (d) +IsenRelPkg
% 	          	    Contains isentropic relations for temperature,
%                   pressure, etc. Also contains functions to compute mass 
%                   flow parameter and an iteration to find a new ratio of 
%                   specific heats at a known total temperature and Mach 
%                   number but unknown static temperature.
%
% 	          (e) +SpecHeatPkg
% 	          	    Contains functions that define Cp(T) and Cv(T) for air 
%                   and Cp(T) for Jet-A. Also contains a solver that
%                   numerically computes air temperature change as a 
%                   function of heat added.
%
%     (2) Examples
%
%             To inspect any package specific documentation, please run
%             either of the following two commands:
%
%             >> doc EngineModelPkg.PackageName.README
%             >> help EngineModelPkg.PackageName.README
%
%             where "PackageName" is replaced by a choice from the list
%             above. For example, if a user wishes to inspect the engine
%             specifications documentation, they can run either:
%
%             >> doc EngineModelPkg.EngineSpecsPkg.README
%             >> help EngineModelPkg.EngineSpecsPkg.README
%
% -------------------------------------------------------------------------
%
% (II) Engine Model Overview
%
%       The engine model package is a collection of code within FAST which
%       is called when flying a mission. Its main purpose is to output a
%       fuel burn estimate for a requested thrust or power. Current
%       functionality is limited to turbofans and turboprops/shafts,
%       however propfans (open rotor engines) are coming soon.
%       Additionally, an off-design engine model is in development
%       alongside a compressor map generator. Off-design mode and
%       compressor map generation are coming soon as well. In the aircraft
%       design code, the on-design engine model is used in off-design
%       conditions as the performance losses can be corrected with scaling
%       factors on the fuel burn output. 
% 
% -------------------------------------------------------------------------
%   
% (II) Helpful Tips
%
%           (a) The function documentation will refer to a "flow state"
%               many times. Flow states include the following information:
%               {'MDot'} = mass flow rate, kilogram_second
%               {'Pt'  } = stagnation/total pressure, Pascals
%               {'Ps'  } = static pressure, Pascals
%               {'Tt'  } = stagnation/total temperature, kelvin
%               {'Ts'  } = static temperature, kelvin
%               {'Mach'} = Mach Number
%               {'Cp'  } = specific heat at constant pressure,
%                          joule_kilogram_kelvin
%               {'Cv'  } = specific heat at constant volume,
%                          joule_kilogram_kelvin
%               {'Gam' } = Cp/Cv = ratio of specific heats
%               {'Area'} = flow area, meter^2
%               {'Ro'  } = outer radius of flow annulus, meter
%               {'Ri'  } = inner radius of flow annulus, meter
%
% end EngineModelPkg.README
%
end














