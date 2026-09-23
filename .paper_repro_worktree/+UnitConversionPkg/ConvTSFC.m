function [newval] = ConvTSFC(oldval,oldunit,newunit)
%
% [newval] = ConvTSFC(oldval,oldunit,newunit)  
% written by Maxfield Arnson, marnson@umich.edu
% updated 23 apr 2024
%
% Convert a thrust specific fuel consumption (TSFC) value from one unit to 
% another. Supported units are listed below. Input variables oldunit and 
% newunit should take a value from column 2 of the following list.
%
%        Supported units                    |    symbol
%       ------------------------------------------------
%        kilogram / Newton / second         |   'SI'
%        pound mass / pound force / hour    |   'Imp'
%
% INPUTS:
%     oldval  - numerical value, i.e. input TSFC.
%               size/type/units: scalar, vector, or array / double / oldunit
%
%     oldunit - TSFC unit that oldval is given in (see table).
%               size/type/units: 1-by-1 / string or char / []
%
%     newunit - TSFC unit that user would like oldval returned in (see
%                   table).
%               size/type/units: 1-by-1 / string or char / []
%
% OUTPUTS:
%     newval  - numerical value converted from oldunit to newunit:
%               size/type/units: same size as oldval / double / newunit
%

% ----------------------------------------------------------


% {'SI','Imp'}
%    1    2 
Data = [1   3600/0.224808943099711*2.204622621848776
    1/(3600/0.224808943099711*2.204622621848776) 1];

% error message definition
errormsg = "Unsupported unit in TSFC conversion. Supported units are kilograms per Newton per second and poundmass per poundforce per hour, denoted by 'SI' and 'Imp' respectively.";



% Define old unit Index
switch oldunit
    case 'SI'
        row = 1;
    case 'Imp'
        row = 2;
    otherwise
        error(errormsg)
end

% Define new unit index
switch newunit
    case 'SI'
        col = 1;
    case 'Imp'
        col = 2;
    otherwise
        error(errormsg)
end

% Identify Scale from Data Matrix
ScaleFactor = Data(row,col);

newval = oldval.*ScaleFactor;

end

