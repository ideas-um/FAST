function [NewStruct,OutputCell] = SearchDB(MainStruct,SubstructList,DesVel)
%
% [NewStruct,OutputCell] = SearchDB(MainStruct,SubstructList,DesVel)
% Written by Maxfield Arnson
% Updated 10/3/2023
%
% This function takes a datastructure, a parameter search path, and (optionally) a
% desired parameter value. It then returns a substructure containing all
% aircraft that met the criteria and a list of the aircraft and the desired
% parameters's value.
%
%
% INPUTS:
%
% MainStruct = Structure tree containing the desired data.
%       size: 1x1 struct
%       options: default IDEAS databases such as TurbofanAC,
%           TurbofanEngines, TurbopropAC, or TurbopropEngines. These databases
%           can be created in the workspace by running the following command:
%           load('+DatabasePkg/IDEAS_DB.mat')
%           Alternatively, custom structures made from running this
%           function can be input. Suppose a user would like to look at
%           the MTOWs of only Airbus vehicles. They would first run the
%           command:
%           [Airbus_Vehicles,~] = RegressionPkg.SearchDB(TurbofanAC,["Overview","Manufacturer"],"Airbus")
%           and then run a second command passing the new structure back
%           into the function:
%           [~,Airbus_Ranges] = RegressionPkg.SearchDB(Airbus_Vehicles,["Specs","Performance","Range"])
%
% SubstructList = Map to desired data. This is a list of strings that guide
%           function.
%       size: 1xN vector of strings, where N is the number of substructures
%           within an aircraft or engine structure tree. See above example.
%       options: There are over 100 possible options for this input.
%           Explore one of the database structures in the default IDEAS
%           databases for more information.
%
% DesVel = Desired value of search parameter
%       size: 1x1 scalar value or string
%       options: this could be a specific manufacturer name or value for a
%           numerical value such as range or fuel consumption.
%
%
% OUTPUTS:
%
% NewStruct = structure mimicking the format of MainStruct where only data
%           with value equal to the desired value is included. If only two
%           inputs were given to SearchDB, NewStruct will be identical to
%           MainStruct.
%       size: 1x1 struct
%
% OutputCell = cell array containing the names of all the aircraft or
%           engines in the first column and the values of the requested parameter in
%           the second column.
%       size: 2xD cell array where D is equal to the number of aircraft or
%           engines meeting the input requirements



%% Initialization
StructFields = fieldnames(MainStruct);
NewIncluded = cell(1,2);
Included = cell(0,2);

%% Create the list of values
% first switch case parses inputs, decides if we need to match a value or
% not. Nested switch case assigns output values based on how many layers
% deep it needs to search the MainStuct tree in order to find the desired
% parameter.
try
    switch nargin %#ok<*AGROW>
        case 2 % nargin
            % in this case, all engines/aircraft in the MainStruct tree are
            % returned as outputs since no desired value was prescribed.
            switch length(SubstructList)
                case 1 % #substructs
                    for ii = 1:length(StructFields)
                        % names of included aircraft/engines
                        NewIncluded{1} = StructFields{ii}; 
                        % values of desired parameter
                        NewIncluded{2} = MainStruct.(StructFields{ii}).(SubstructList(1));
                        Included = [Included; NewIncluded];
                    end
                case 2 % #substructs
                    for ii = 1:length(StructFields)
                        NewIncluded{1} = StructFields{ii};
                        NewIncluded{2} = MainStruct.(StructFields{ii}).(SubstructList(1)).(SubstructList(2));
                        Included = [Included; NewIncluded];
                    end
                case 3 % #substructs
                    for ii = 1:length(StructFields)
                        NewIncluded{1} = StructFields{ii};
                        NewIncluded{2} = MainStruct.(StructFields{ii}).(SubstructList(1)).(SubstructList(2)).(SubstructList(3));
                        Included = [Included; NewIncluded];
                    end
                case 4 % #substructs
                    for ii = 1:length(StructFields)
                        NewIncluded{1} = StructFields{ii};
                        NewIncluded{2} = MainStruct.(StructFields{ii}).(SubstructList(1)).(SubstructList(2)).(SubstructList(3)).(SubstructList(4));
                        Included = [Included; NewIncluded];
                    end
            end
        case 3 % nargin
            % in this case, the code checks whether or not the value of the
            % parameter for each engine or aircraft is equal to the desired
            % parameter. If not, that engine/aircraft is excluded from the
            % output list.
            switch length(SubstructList)
                case 1 % #substructs
                    for ii = 1:length(fieldnames(MainStruct))
                        CurVal = MainStruct.(StructFields{ii}).(SubstructList(1));
                        if isequal(CurVal, DesVel)
                            NewIncluded{1} = StructFields{ii};
                            NewIncluded{2} = CurVal;
                            Included = [Included; NewIncluded];
                        end
                    end
                case 2 % #substructs
                    for ii = 1:length(fieldnames(MainStruct))
                        CurVal = MainStruct.(StructFields{ii}).(SubstructList(1)).(SubstructList(2));
                        if isequal(CurVal, DesVel)
                            NewIncluded{1} = StructFields{ii};
                            NewIncluded{2} = CurVal;
                            Included = [Included; NewIncluded];
                        end
                    end
                case 3 % #substructs
                    for ii = 1:length(fieldnames(MainStruct))
                        CurVal = MainStruct.(StructFields{ii}).(SubstructList(1)).(SubstructList(2)).(SubstructList(3));
                        if isequal(CurVal, DesVel)
                            NewIncluded{1} = StructFields{ii};
                            NewIncluded{2} = CurVal;
                            Included = [Included; NewIncluded];
                        end
                    end
                case 4 % #substructs
                    for ii = 1:length(fieldnames(MainStruct))
                        CurVal = MainStruct.(StructFields{ii}).(SubstructList(1)).(SubstructList(2)).(SubstructList(3)).(SubstructList(4));
                        if isequal(CurVal, DesVel)
                            NewIncluded{1} = StructFields{ii};
                            NewIncluded{2} = CurVal;
                            Included = [Included; NewIncluded];
                        end
                    end
            end
    end

    OutputCell = Included;

%% Error Handling
catch
    invalidlist = "";
    for ii = 1:length(SubstructList)
        if ii == length(SubstructList)
           invalidlist = invalidlist + SubstructList(ii); 
        else
        invalidlist = invalidlist + SubstructList(ii) + ", ";
        end
    end

    error("Invalid parameter search path. \n <%s> is not found in the structure you are trying to search in.",invalidlist)
end

%% Create new output structure
NewStruct = struct();

for ii = 1:size(OutputCell,1)
    NewStruct.(Included{ii}) = MainStruct.(Included{ii});
end


end
