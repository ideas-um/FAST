classdef OptimizationTraceRecorder < handle
    %OPTIMIZATIONTRACERECORDER Capture fmincon convergence diagnostics.

    properties (Access = private)
        ObjectiveScale (1,1) double = 1
        StartTime
        State string = strings(0, 1)
        Iteration double = zeros(0, 1)
        FunctionCount double = zeros(0, 1)
        ObjectiveScaled double = zeros(0, 1)
        ConstraintViolation double = zeros(0, 1)
        FirstOrderOptimality double = zeros(0, 1)
        StepSize double = zeros(0, 1)
        Elapsed_s double = zeros(0, 1)
        Procedure string = strings(0, 1)
    end

    methods
        function obj = OptimizationTraceRecorder(ObjectiveScale)
            if nargin > 0
                obj.ObjectiveScale = ObjectiveScale;
            end
            obj.StartTime = tic;
        end

        function Stop = Record(obj, ~, OptimValues, State)
            % Signature matches an Optimization Toolbox OutputFcn.
            Stop = false;
            obj.State(end + 1, 1) = string(State);
            obj.Iteration(end + 1, 1) = obj.NumericField( ...
                OptimValues, "iteration");
            obj.FunctionCount(end + 1, 1) = obj.NumericField( ...
                OptimValues, "funccount");
            obj.ObjectiveScaled(end + 1, 1) = obj.NumericField( ...
                OptimValues, "fval");
            obj.ConstraintViolation(end + 1, 1) = obj.NumericField( ...
                OptimValues, "constrviolation");
            obj.FirstOrderOptimality(end + 1, 1) = obj.NumericField( ...
                OptimValues, "firstorderopt");
            obj.StepSize(end + 1, 1) = obj.NumericField( ...
                OptimValues, "stepsize");
            obj.Elapsed_s(end + 1, 1) = toc(obj.StartTime);
            if isfield(OptimValues, "procedure")
                obj.Procedure(end + 1, 1) = string(OptimValues.procedure);
            else
                obj.Procedure(end + 1, 1) = "";
            end
        end

        function Trace = ToTable(obj)
            if isempty(obj.Iteration)
                Trace = OptimizationPkg.OptimizationTraceRecorder.EmptyTable();
                return
            end
            Objective_kg = obj.ObjectiveScaled .* obj.ObjectiveScale;
            InitialIndex = find(isfinite(Objective_kg), 1, "first");
            if isempty(InitialIndex)
                InitialObjective_kg = NaN;
            else
                InitialObjective_kg = Objective_kg(InitialIndex);
            end
            ObjectiveReduction_kg = InitialObjective_kg - Objective_kg;
            if isfinite(InitialObjective_kg) && abs(InitialObjective_kg) > eps
                ObjectiveReduction_pct = 100 .* ObjectiveReduction_kg ./ ...
                    abs(InitialObjective_kg);
            else
                ObjectiveReduction_pct = nan(size(Objective_kg));
            end
            Trace = table(obj.State, obj.Iteration, obj.FunctionCount, ...
                obj.ObjectiveScaled, Objective_kg, ObjectiveReduction_kg, ...
                ObjectiveReduction_pct, obj.ConstraintViolation, ...
                obj.FirstOrderOptimality, obj.StepSize, obj.Elapsed_s, ...
                obj.Procedure, 'VariableNames', { ...
                'State','Iteration','FunctionCount','ObjectiveScaled', ...
                'Objective_kg','ObjectiveReduction_kg', ...
                'ObjectiveReduction_pct','ConstraintViolation', ...
                'FirstOrderOptimality','StepSize','Elapsed_s','Procedure'});
        end
    end

    methods (Static)
        function Trace = EmptyTable()
            Trace = table('Size', [0, 12], ...
                'VariableTypes', ["string","double","double","double", ...
                "double","double","double","double","double", ...
                "double","double","string"], ...
                'VariableNames', {'State','Iteration','FunctionCount', ...
                'ObjectiveScaled','Objective_kg','ObjectiveReduction_kg', ...
                'ObjectiveReduction_pct','ConstraintViolation', ...
                'FirstOrderOptimality','StepSize','Elapsed_s','Procedure'});
        end
    end

    methods (Static, Access = private)
        function Value = NumericField(Struct, Name)
            if isfield(Struct, Name) && isnumeric(Struct.(Name)) && ...
                    isscalar(Struct.(Name))
                Value = double(Struct.(Name));
            else
                Value = NaN;
            end
        end
    end
end
