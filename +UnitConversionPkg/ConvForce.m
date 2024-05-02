function [newval] = ConvForce(oldval,oldunit,newunit)
%
% [newval] = ConvForce(oldval,oldunit,newunit)  
% written by Maxfield Arnson, marnson@umich.edu
% updated 23 apr 2024
%
% Convert a force value from one unit to another. Supported units are
% listed below. Input variables oldunit and newunit should take a value
% from column 2 of the following list.
%
%        Supported units      |    symbol
%       ----------------------------------
%        pound force          |   'lbf'
%        Newtons              |   'N'
%
% INPUTS:
%     oldval  - numerical value, i.e. input force.
%               size/type/units: scalar, vector, or array / double / oldunit
%
%     oldunit - force unit that oldval is given in (see table).
%               size/type/units: 1-by-1 / string or char / []
%
%     newunit - force unit that user would like oldval returned in (see
%                   table).
%               size/type/units: 1-by-1 / string or char / []
%
% OUTPUTS:
%     newval  - numerical value converted from oldunit to newunit:
%               size/type/units: same size as oldval / double / newunit
%

% ----------------------------------------------------------


% {'lbf','N'}
%    1    2
Data = [1	4.44822161526050
0.224808943099711	1];

% error message definition
errormsg = "Unsupported unit in force conversion. Supported units are pound force and Newtons, denoted by 'lbf' and 'N' respectively.";


% Define old unit Index
switch oldunit
    case 'lbf'
        row = 1;
    case 'N'
        row = 2;
    otherwise
        error(errormsg)
end

% Define new unit index
switch newunit
    case 'lbf'
        col = 1;
    case 'N'
        col = 2;
    otherwise
        error(errormsg)
end

% Identify Scale from Data Matrix
ScaleFactor = Data(row,col);

newval = oldval.*ScaleFactor;
end

