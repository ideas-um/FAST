function [Proj_kpp] = KPPProjection(A_class, K_year, kpp)
%
% [Proj_kpp] = KPPProjection(A_class, K_year, kpp)
% Written by Michael Tsai
% Updated by Max Arnson || marnson@umich.edu
% Last updated 11/20/23
%
%
% This function calculates a theoretical value for a key [aircraft] performance
% parameter in the future (the present is 2021)
%
%
% INPUTS:
%
% A_class = Aircraft class
%       size: 1x1 string
%       options:
%             {'Turbofan'  }
%             {'Turboprop' }
%
% k_year = year in which the desired kpp value would like to be estimated
%       size: scalar double
%
% kpp = key performance parameter that would like to be projected into the
%           future
%       size: 1x1 string
%       options: 
%             {'Cruise SFC'                    }
%             {'Total Takeoff T/ MTOW'         }
%             {'OEW/MTOW'                      }
%             {'M(L/D)'                        }
%             {'Battery Specific Energy'       }
%             {'Electric Motor Specific Power' }
%
%
% OUTPUTS:
%
% Proj_kpp = projected value of the desired kpp in the year given by k_year
%       size: scalar double
%

% Define S-Curve Functions for each KPP
sig0 = @(yr, low, high, gr, inf ) low + ((high - low)/(1+exp((-gr)*(yr- inf))));
sigB = @(yr) 0+ ((801.8)/(1+exp(0.0607*(2030.8-yr))));                           %Battery Specific Energy (Wh/kg)
sigM = @(yr) (37.8)/(1+exp(-0.1213*(yr-2030)));                                  %Electric Motor Specific Power (kW/kg)

switch A_class
    case "Turbofan"
        switch kpp
            case 'Cruise SFC'
                Inf_pt = 1992;
                Low_asym = 0.3335;
                Up_asym = 0.851;
                growthrate = -0.0727;
                low = Low_asym; high = Up_asym; gr = growthrate; inf = Inf_pt;
                sig = @(yr) sig0(yr,low, high, gr, inf );
                Proj_kpp = feval(sig,K_year);
            case 'Total Takeoff T/ MTOW'
                Inf_pt = 1980;
                Low_asym = 0.15;
                Up_asym = 0.3465;
                growthrate = 0.1132;
                low = Low_asym; high = Up_asym; gr = growthrate; inf = Inf_pt;
                sig = @(yr) sig0(yr,low, high, gr, inf );
                Proj_kpp = feval(sig,K_year);
            case 'OEW/MTOW'
                Proj_kpp = 0.5123;
            case 'M(L/D)'
                Proj_kpp = 14.44051;
            case 'Battery Specific Energy'
                %Battery Specific Energy (Wh/kg)
                Proj_kpp = feval(sigB,K_year);
            case 'Electric Motor Specific Power'
                %Electric Motor Specific Power (kW/kg)
                Proj_kpp = feval(sigM,K_year);
            otherwise
                fprintf('Current KPP is not Supported. Please Enter: Cruise SFC, Total Takeoff T/ MTOW, OEW/MTOW, M(L/D), Battery Specific Energy, Electric Motor Specific Power')
        end

    case "Turboprop"
        switch kpp
            case 'Cruise SFC'
                Inf_pt = 1993;
                Low_asym = 0.3335;
                Up_asym = 0.6;
                growthrate = -0.1012;
                low = Low_asym; high = Up_asym; gr = growthrate; inf = Inf_pt;
                sig = @(yr) sig0(yr,low, high, gr, inf );
                Proj_kpp = feval(sig,K_year);
            case 'Total Takeoff T/ MTOW'
                Inf_pt = 2011;
                Low_asym = 0.3;
                Up_asym = 0.9;
                growthrate = 0.5334;
                low = Low_asym; high = Up_asym; gr = growthrate; inf = Inf_pt;
                sig = @(yr) sig0(yr,low, high, gr, inf );
                %Total Takeoff T/ MTOW
                Proj_kpp = feval(sig,K_year);

            case 'OEW/MTOW'
                %Operating Empty Weight/ Max Takeoff Weight
                Proj_kpp = 0.6284;
            case 'M(L/D)'
                Inf_pt = 2010;
                Low_asym = 1;
                Up_asym = 10;
                growthrate = 0.1683;
                low = Low_asym; high = Up_asym; gr = growthrate; inf = Inf_pt;
                sig = @(yr) sig0(yr,low, high, gr, inf );
                %Mach number * (Lift/ Drag)
                Proj_kpp = feval(sig,K_year);
            case 'Battery Specific Energy'
                %Battery Specific Energy (Wh/kg)
                Proj_kpp = feval(sigB,K_year);
            case 'Electric Motor Specific Power'
                %Electric Motor Specific Power (kW/kg)
                Proj_kpp = feval(sigM,K_year);
            otherwise
                fprintf('Current KPP is not Supported. Please Enter: Cruise SFC, Total Takeoff T/ MTOW, OEW/MTOW, M(L/D), Battery Specific Energy, Electric Motor Specific Power')
        end

    otherwise
        fprintf('Current Class is not Supported. Please Enter: Piston, Turbofan, Turboprop ')
end
end
