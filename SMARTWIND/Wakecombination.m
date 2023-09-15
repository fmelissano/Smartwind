classdef Wakecombination < handle

    properties

    end

    methods (Static)
        function combination=linear_function(field,wake)
            combination=field+wake;
        end

        function combination=sumofsquares_function(field,wake)
            combination=hypot(field,wake);
        end
    end
end