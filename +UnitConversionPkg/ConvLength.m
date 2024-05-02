function [newval] = ConvLength(oldval,oldunit,newunit)
%
% [newval] = ConvLength(oldval,oldunit,newunit)
% written by Maxfield Arnson, marnson@umich.edu
% updated 23 apr 2024
%
% Convert a length value from one unit to another. Supported units are
% listed below. Input variables oldunit and newunit should take a value
% from column 2 of the following list.
%
%        Supported units      |    symbol
%       ----------------------------------
%        feet                 |   'ft'
%        meters               |   'm'
%        kilometers           |   'km'
%        miles                |   'mi'
%        nautical miles       |   'naut mi'
%
% INPUTS:
%     oldval  - numerical value, i.e. input length.
%               size/type/units: scalar, vector, or array / double / oldunit
%
%     oldunit - length unit that oldval is given in (see table).
%               size/type/units: 1-by-1 / string or char / []
%
%     newunit - length unit that user would like oldval returned in (see
%                   table).
%               size/type/units: 1-by-1 / string or char / []
%
% OUTPUTS:
%     newval  - numerical value converted from oldunit to newunit:
%               size/type/units: same size as oldval / double / newunit
%

% ----------------------------------------------------------


% {'ft','m','km','mi','naut mi'}
%    1   2   3    4       5
Data = [1	0.304800000000000	0.000304800000000000	0.000189393939393939	0.000164578833693305
    3.28083989501312	1	0.00100000000000000	0.000621371192237334	0.000539956803455724
    3280.83989501312	1000	1	0.621371192237334	0.539956803455724
    5280	1609.34400000000	1.60934400000000	1	0.868976241900648
    6076.11548556430	1852	1.85200000000000	1.15077944802354	1];

% error message definition
errormsg = sprintf("Unsupported unit in length conversion. Supported units are: \n feet:           'ft' \n meters:         'm' \n kilometers:     'km' \n miles:          'mi' \n nautical miles: 'naut mi' ");


% Define old unit Index
switch oldunit
    case 'ft'
        row = 1;
    case 'm'
        row = 2;
    case 'km'
        row = 3;
    case 'mi'
        row = 4;
    case 'naut mi'
        row = 5;
    otherwise
        error(errormsg)
end

% Define new unit index
switch newunit
    case 'ft'
        col = 1;
    case 'm'
        col = 2;
    case 'km'
        col = 3;
    case 'mi'
        col = 4;
    case 'naut mi'
        col = 5;
    otherwise
        error(errormsg)
end

% Identify Scale from Data Matrix
ScaleFactor = Data(row,col);

newval = oldval.*ScaleFactor;

end
