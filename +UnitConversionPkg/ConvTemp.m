function [newval] = ConvTemp(oldval,oldunit,newunit)
%
% [newval] = ConvTemp(oldval,oldunit,newunit)  
% written by Maxfield Arnson, marnson@umich.edu
% updated 23 apr 2024
%
% Convert a temperature value from one unit to another. Supported units are
% listed below. Input variables oldunit and newunit should take a value
% from column 2 of the following list.
%
%        Supported units      |    symbol
%       ----------------------------------
%        Kelvin               |   'K'
%        Celsius              |   'C'
%        Rankine              |   'R'
%        Fahrenheit           |   'F'
%
% INPUTS:
%     oldval  - numerical value, i.e. input temperature.
%               size/type/units: scalar, vector, or array / double / oldunit
%
%     oldunit - temperature unit that oldval is given in (see table).
%               size/type/units: 1-by-1 / string or char / []
%
%     newunit - temperature unit that user would like oldval returned in (see
%                   table).
%               size/type/units: 1-by-1 / string or char / []
%
% OUTPUTS:
%     newval  - numerical value converted from oldunit to newunit:
%               size/type/units: same size as oldval / double / newunit
%

% ----------------------------------------------------------


% error message definition
errormsg = "Unsupported unit in temperature conversion. Supported units are Kelvin, Celsius, Rankine, and Fahrenheit, denoted by 'K','C','R', and 'F' respectively.";


% Kelvin, Celsius, Rankine, Fahrenheit

switch oldunit
    case 'K'
        switch newunit
            case 'K'
                newval = oldval;
            case 'C'
                newval = oldval - 273.15;
            case 'R'
                newval = oldval.*1.8;
            case 'F'
                newval = oldval.*1.8 - 459.67;
            otherwise
                error(errormsg)
        end
    case 'C'
        switch newunit
            case 'K'
                newval = oldval + 273.15;
            case 'C'
                newval = oldval;
            case 'R'
                newval = (oldval + 273.15).*1.8;
            case 'F'
                newval = (oldval + 273.15).*1.8 - 459.67;
            otherwise
                error(errormsg)
        end
    case 'R'
        switch newunit
            case 'K'
                newval = oldval./1.8;                
            case 'C'
                newval = oldval./1.8 - 273.15;
            case 'R'
                newval = oldval;
            case 'F'
                newval = oldval - 459.67;
            otherwise
                error(errormsg)
        end
    case 'F'
        switch newunit
            case 'K'
                newval = (oldval - 459.67)./1.8;
            case 'C'
                newval = (oldval - 459.67)./1.8 + 273.15;
            case 'R'
                newval = oldval + 459.67;
            case 'F'
                newval = oldval;
            otherwise
                error(errormsg)
        end
    otherwise
        error(errormsg)
end



end

