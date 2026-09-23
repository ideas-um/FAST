function [newval] = ConvMass(oldval,oldunit,newunit)
%
% [newval] = ConvMass(oldval,oldunit,newunit)  
% written by Maxfield Arnson, marnson@umich.edu
% updated 23 apr 2024
%
% Convert a mass value from one unit to another. Supported units are
% listed below. Input variables oldunit and newunit should take a value
% from column 2 of the following list.
%
%        Supported units      |    symbol
%       ----------------------------------
%        pound mass           |   'lbm'
%        kilogram             |   'kg'
%        slug                 |   'slug'
%
% INPUTS:
%     oldval  - numerical value, i.e. input mass.
%               size/type/units: scalar, vector, or array / double / oldunit
%
%     oldunit - mass unit that oldval is given in (see table).
%               size/type/units: 1-by-1 / string or char / []
%
%     newunit - mass unit that user would like oldval returned in (see
%                   table).
%               size/type/units: 1-by-1 / string or char / []
%
% OUTPUTS:
%     newval  - numerical value converted from oldunit to newunit:
%               size/type/units: same size as oldval / double / newunit
%

% ----------------------------------------------------------

% {'lbm','kg','slug'}
%    1    2      3
Data = [1	0.453592370000000	0.0310809501715673
2.20462262184878	1	0.0685217658567918
32.1740485564304	14.5939029372064	1];

% error message definition
errormsg = "Unsupported unit in mass conversion. Supported units are poundmass, kilograms, and slugs, denoted by 'lbm', 'kg', and 'slug' respectively.";

% Define old unit Index
switch oldunit
    case 'lbm'
        row = 1;
    case 'kg'
        row = 2;
    case 'slug'
        row = 3;
    otherwise
        error(errormsg)
end

% Define new unit index
switch newunit
    case 'lbm'
        col = 1;
    case 'kg'
        col = 2;
    case 'slug'
        col = 3;
    otherwise
        error(errormsg)
end

% Identify Scale from Data Matrix
ScaleFactor = Data(row,col);

newval = oldval.*ScaleFactor;

end

