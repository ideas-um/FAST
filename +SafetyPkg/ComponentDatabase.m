function [Component] = ComponentDatabase(Name)
%
% [Component] = ComponentDatabase(Name)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 16 oct 2025
%
% return an electrical component and its nominal failure rate according to
% the following publication:
%
% Darmstadt, P. R., Catanese, R., Beiderman, A., Dones, F., Chen, E.,
% Mistry, M. P., ... & Preator, R. (2019). Hazards analysis and failure
% modes and effects criticality analysis (FMECA) of four concept vehicle
% propulsion systems (No. NASA/CR-2019-220217).
%
% INPUTS:
%     Name      - the name of the component as a cell array of characters.
%                 size/type/units: 1-by-1 / cell / []
%
% OUTPUTS:
%     Component - data structure with the component name and failure rate.
%

% select the component and obtain its failure rate
if (strcmpi(Name, 'TurbineEngine'))
    FRate = 2.67 * 1.0e-06;

elseif (strcmpi(Name, 'ACGenerator'))
    FRate = 130 * 1.0e-06;

elseif (strcmpi(Name, 'Battery'))
    FRate = 93.1 * 1.0e-06;

elseif (strcmpi(Name, 'ElectricMotor'))
    FRate = 92.4 * 1.0e-06;

else

    % throw an error
    error('ERROR - ComponentDatabase: component not included.');

end

% return a structure
Component.Name     = Name ;
Component.FailRate = FRate;

% ----------------------------------------------------------

end