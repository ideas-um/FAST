function [Options] = ExampleOptions()
%
% [Options] = ExampleOptions()
% written by Maxfield Arnson, marnson@umich.edu
% last updated: 3 May 2024
%
%
% Initialize an "Options" structure for aircraft retrofitting. Users should
% copy this file and rename it for any retrofits they would like to
% perform. 
%
% INPUTS:  none
%
%
% OUTPUTS: Options      - A structure containing fields which outline the
%                         logistics of the retrofit being performed.
%                            Fields:
%                            - NumMotors = 1x1 double outlining the numer of
%                            electric motors to replace engines on the existing
%                            aircraft. this number must be 0 or positive
%                            - ThrustSplit = PAUL, input a matrix?
%                            - PayDecrease = the percentage of the payload
%                            that is being allocated to batteries. e.g a
%                            value of 0.3 corresponds to a 30% decrease in
%                            payload leaving 70% original payload capacity
%                            size: 1x1 double
%                            - BattSpecEnergy = 1x1 value outlining the
%                            specific energy of the batteries that will be
%                            used for the retrofit. units should be in
%                            kWh/kg. values will typically range from 0.2
%                            (present day) to 1.5 (optimistic future)
%                            size: 1x1 double
%                            -PW_EM = 1x1 value describing the power to
%                            weight ratio of the electric motors. units are
%                            in kilowatts per kilogram.
%                            - SavingsType = variable describing where
%                            extra energy should be allocated.
%                            i.e. do you want to minimize fuel burn,
%                            maximize range, or reduce payload losses?
%                            size: 1x1 string
%                               Options are:
%                                   {"Fuel"        }
%                                   {"Range"       }
%                                   {"Payload"     }
%

% ----------------------------------------------------------


% Number of electric motors replacing fuel burnign engines
Options.NumMotors = 2;

% Thrust split, percentage electric thrust
% The retrofit function use this thrust split until batteries are depleted
Options.ThrustSplit = 0.20;

% Percentage payload decrease
Options.PayDecrease = 0.5;

% Battery specific energy in kilowatt hours per kilogram
Options.BattSpecEnergy = 0.5;

% Electric motor power to weight ratio in kilowatts per kilogram
Options.PW_EM = 10;

% Savings type
% "Fuel", "Range", or "Payload"
Options.SavingsType = "Fuel";


end

