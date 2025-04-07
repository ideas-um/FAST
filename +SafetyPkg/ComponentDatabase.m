function [Component] = ComponentDatabase(Name)
%
% [Component] = ComponentDatabase(Name)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 apr 2025
%
% return an electrical component and its nominal failure rate according to
% the following publication:
%
% Darmstadt, P. R., Catanese, R., Beiderman, A., Dones, F., Chen, E., 
% Mistry, M. P., ... & Preator, R. (2019). Hazards analysis and failure
% modes and effects criticality analysis (fmeca) of four concept vehicle
% propulsion systems (No. NASA/CR-2019-220217).
%
% INPUTS:
%     Name      - the name of the component.
%                 size/type/units: 1-by-1 / string / []
%
% OUTPUTS:
%     Component - data structure with the component name and base failure
%                 rate.
%

% select the component and obtain its failure rate
if (strcmpi(Name, "TurbineEngine") == 1)
    FRate = 2.67 * 1.0e-06;
    
elseif (strcmpi(Name, "ACGenerator") == 1)
    FRate = 130 * 1.0e-06;
    
elseif (strcmpi(Name, "Battery") == 1)
    FRate = 93.1 * 1.0e-06;
    
elseif (strcmpi(Name, "ElectricMotor") == 1)
    FRate = 92.4 * 1.0e-06;
    
else
    
    % throw an error
    error("ERROR - ComponentDatabase: component not included.");
    
end

% return a structure
Component.Name     = Name ;
Component.FailRate = FRate;

end