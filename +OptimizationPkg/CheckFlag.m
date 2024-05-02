function [Flag] = CheckFlag(MainStruct, Var)
%
% [Flag] = CheckFlag(MainStruct, Var)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 mar 2024
%
% Check if a flag within a structure exists and whether it is turned on (1)
% or not (0).
%
% INPUTS:
%     MainStruct - structure containing the variable of interest.
%                  size/type/units: 1-by-1 / struct / []
%
%     Var        - name of the variable.
%                  size/type/units: 1-by-1 / string / []
%
% OUTPUTS:
%     Flag       - whether the flag is on (1) or off (0).
%                  size/type/units: 1-by-1 / int / []
%

% ----------------------------------------------------------

% check if the field exists
if (isfield(MainStruct, Var))
    
    % check if the flag is set
    if (MainStruct.(Var) == 1)
        
        % turn flag on
        Flag = 1;
        
    else
        
        % turn flag off
        Flag = 0;
        
    end
    
else
    
    % turn flag off - field not specified
    Flag = 0;
    
end

% ----------------------------------------------------------

end