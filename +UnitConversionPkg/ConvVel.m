function [newval] = ConvVel(oldval,oldunit,newunit)
%
% [newval] = ConvVel(oldval,oldunit,newunit)  
% written by Maxfield Arnson, marnson@umich.edu
% updated 23 apr 2024
%
% Convert a velocity value from one unit to another. Supported units are
% listed below. Input variables oldunit and newunit should take a value
% from column 2 of the following list.
%
%        Supported units      |    symbol
%       ----------------------------------
%        feet/second          |   'ft/s'
%        meters/second        |   'm/s'
%        kilometers/second    |   'km/s'
%        kilometers/hour      |   'km/h'
%        miles/hour           |   'mph'
%        knots (naut mi/hour) |   'kts'
%        feet/minute          |   'ft/min'
%
% INPUTS:
%     oldval  - numerical value, i.e. input velocity.
%               size/type/units: scalar, vector, or array / double / oldunit
%
%     oldunit - velocity unit that oldval is given in (see table).
%               size/type/units: 1-by-1 / string or char / []
%
%     newunit - velocity unit that user would like oldval returned in (see
%                   table).
%               size/type/units: 1-by-1 / string or char / []
%
% OUTPUTS:
%     newval  - numerical value converted from oldunit to newunit:
%               size/type/units: same size as oldval / double / newunit
%

% ----------------------------------------------------------


% {'ft/s','m/s','km/s','km/h','mph','kts','ft/min'}
%    1      2     3       4     5     6       7
Data = [1	0.304800000000000	0.000304800000000000	1.09728000000000	0.681818181818182	0.592483801295896	60
3.28083989501312	1	0.00100000000000000	3.60000000000000	2.23693629205440	1.94384449244060	196.850393700787
3280.83989501312	1000	1	3600	2236.93629205440	1943.84449244060	196850.393700787
0.911344415281423	0.277777777777778	0.000277777777777778	1	0.621371192237334	0.539956803455724	54.6806649168854
1.46666666666667	0.447040000000000	0.000447040000000000	1.60934400000000	1	0.868976241900648	88
1.68780985710120	0.514444444444445	0.000514444444444444	1.85200000000000	1.15077944802354	1	101.268591426072
0.0166666666666667	0.00508000000000000	5.08000000000000e-06	0.0182880000000000	0.0113636363636364	0.00987473002159827	1];


% error message definition
errormsg = sprintf("Unsupported unit in velocity conversion. Supported units are: \n feet per second:       'ft/s' \n meters per second:     'm/s' \n kilometers per second: 'km/s' \n kilometers per hour:   'km/h' \n miles per hour:        'mph' \n knots:                 'kts' \n feet per minute:       'ft/min'");


% Define old unit Index
switch oldunit
    case 'ft/s'
        row = 1;
    case 'm/s'
        row = 2;
    case 'km/s'
        row = 3;
    case 'km/h'
        row = 4;
    case 'mph'
        row = 5;
    case 'kts'
        row = 6;
    case 'ft/min'
        row = 7;
    otherwise
        error(errormsg)
end

% Define new unit index
switch newunit
    case 'ft/s'
        col = 1;
    case 'm/s'
        col = 2;
    case 'km/s'
        col = 3;
    case 'km/h'
        col = 4;
    case 'mph'
        col = 5;
    case 'kts'
        col = 6;
    case 'ft/min'
        col = 7;
    otherwise
        error(errormsg)
end

% Identify Scale from Data Matrix
ScaleFactor = Data(row,col);

newval = oldval.*ScaleFactor;


end

