function [LamTS, LamTSPS, LamPSPS, LamPSES] = GetSplits(Aircraft, SegBeg, SegEnd, ...
          LamTS, LamTSPS, LamPSPS, LamPSES)
%
% [LamTS, LamTSPS, LamPSPS, LamPSES] = GetSplits(Aircraft, SegBeg, SegEnd,
%  LamTS, LamTSPS, LamPSPS, LamPSES)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 mar 2024
%
% When optimizing, get the thrust/power/energy splits from the vector of
% design variables. For the variable inputs/outputs below, m, n, p, and q
% are the number of thrust splits, thrust-power splits, power-power splits,
% and power-energy splits, respectively.
%
% INPUTS:
%     Aircraft - structure within information about the aircraft being
%                designed.
%                size/type/units: 1-by-1 / struct / []
%
%     SegBeg   - first point in the segment being flown.
%                size/type/units: 1-by-1 / int / []
%
%     SegBeg   - last  point in the segment being flown.
%                size/type/units: 1-by-1 / int / []
%
%     LamTS    - thrust splits to be allocated.
%                size/type/units: 1-by-m / double / [%]
%
%     LamTSPS  - splits between thrust-power  sources to be allocated.
%                size/type/units: 1-by-n / double / [%]
%
%     LamPSPS  - splits between power -power  sources to be allocated.
%                size/type/units: 1-by-p / double / [%]
%
%     LamPSES  - splits between power -energy sources to be allocated.
%                size/type/units: 1-by-q / double / [%]
%
% OUTPUTS:
%     LamTS    - allocated thrust splits.
%                size/type/units: 1-by-m / double / [%]
%
%     LamTSPS  - allocated thrust-power  source splits.
%                size/type/units: 1-by-n / double / [%]
%
%     LamPSPS  - allocated power -power  source splits.
%                size/type/units: 1-by-p / double / [%]
%
%     LamPSES  - allocated power -energy source splits.
%                size/type/units: 1-by-q / double / [%]
%

% ----------------------------------------------------------

% get the indices of mission points and their splits
SegIndex = Aircraft.PowerOpt.SegIndex;
LamIndex = Aircraft.PowerOpt.LamIndex;

% get the splits with the appropriate index (ignore last point)
SegPts = find(SegBeg <= SegIndex & SegIndex < SegEnd);

% keep track of the number of splits called
tsplit = 0;

% check if the array is empty or not
if (~isempty(SegPts))
    
    % get the number of points
    npnt = length(SegPts);
    
    % get the number of control points
    npoint = Aircraft.PowerOpt.npoint;
    
    % check for TS   splits
    if (Aircraft.PowerOpt.Settings.OperTS   == 1)
        
        % get the number of TS   splits
        nsplit = Aircraft.Settings.nargTS  ;
        
        % get the TS   splits for each point
        for isplit = 1:nsplit
            for ipnt = 1:npnt
                
                % get the split
                LamTS(  ipnt, isplit) = Aircraft.PowerOpt.Splits(tsplit * npoint + LamIndex(SegPts(ipnt)));
                
            end
            
            % account for the split
            tsplit = tsplit + 1;
            
        end
    end
    
    % check for TSPS splits
    if (Aircraft.PowerOpt.Settings.OperTSPS == 1)
        
        % get the number of TSPS splits
        nsplit = Aircraft.Settings.nargTSPS;
        
        % get the TSPS splits for each point
        for isplit = 1:nsplit
            for ipnt = 1:npnt
                
                % get the split
                LamTSPS(ipnt, isplit) = Aircraft.PowerOpt.Splits(tsplit * npoint + LamIndex(SegPts(ipnt)));
                
            end
            
            % account for the split
            tsplit = tsplit + 1;
            
        end
    end
    
    % check for PSPS splits
    if (Aircraft.PowerOpt.Settings.OperPSPS == 1)
        
        % get the number of PSPS splits
        nsplit = Aircraft.Settings.nargPSPS;
        
        % get the PSPS splits for each point
        for isplit = 1:nsplit
            for ipnt = 1:npnt
                
                % get the split
                LamPSPS(ipnt, isplit) = Aircraft.PowerOpt.Splits(tsplit * npoint + LamIndex(SegPts(ipnt)));
                
            end
            
            % account for the split
            tsplit = tsplit + 1;
            
        end
    end
    
    % check for PSES splits
    if (Aircraft.PowerOpt.Settings.OperPSES == 1)
        
        % get the number of PSES splits
        nsplit = Aircraft.Settings.nargPSES;
        
        % get the PSES splits for each point
        for isplit = 1:nsplit
            for ipnt = 1:npnt
                
                % get the split
                LamPSES(ipnt, isplit) = Aircraft.PowerOpt.Splits(tsplit * npoint + LamIndex(SegPts(ipnt)));
                
            end
            
            % account for the split
            tsplit = tsplit + 1;
            
        end
    end
end

% ----------------------------------------------------------

end