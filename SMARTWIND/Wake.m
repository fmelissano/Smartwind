classdef Wake < handle

    properties
        velocity_model=readcell('inputs.xlsx','Sheet','Models','Range','B3:B3');
        deflection_model=readcell('inputs.xlsx','Sheet','Models','Range','B4:B4');
        combination_model=readcell('inputs.xlsx','Sheet','Models','Range','B5:B5');
        wd=Wakedeflection
        wv=Wakevelocity
        wc=Wakecombination
        ti_initial=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B9:B9'));
        ti_constant=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B10:B10'));
        ti_ai=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B11:B11'));
        ti_downstream=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B12:B12'));
        turbulence_choice=readcell('inputs.xlsx','Sheet','Models','Range','F2:F2');
    end

    methods
        function [deflection]=deflection_function(obj,x_locations,y_locations,turbine,coord,wind_field,u_initial)
            if strcmp(obj.deflection_model,'Jimenez')
                [deflection]=obj.wd.Jimenez_function(x_locations,y_locations,turbine,coord,wind_field,u_initial);
            elseif strcmp(obj.deflection_model,'Gauss')
                [deflection]=obj.wd.Gauss_function(x_locations,y_locations,turbine,coord,wind_field,u_initial);
            else
                error('Input deflection model not valid');
            end
        end

        function [deficit1,deficit2,deficit3]=velocity_function(obj,x_locations,y_locations,z_locations,turbine,coord,deflection,wind_field,u_initial)
            if strcmp(obj.velocity_model,'Jensen')
                [deficit1,deficit2,deficit3]=obj.wv.Jensen_function(x_locations,y_locations,z_locations,turbine,coord,deflection,wind_field,u_initial);
            elseif strcmp(obj.velocity_model,'Multizone')
                [deficit1,deficit2,deficit3]=obj.wv.Multizone_function(x_locations,y_locations,z_locations,turbine,coord,deflection,wind_field,u_initial);
            elseif strcmp(obj.velocity_model,'Gauss')
                [deficit1,deficit2,deficit3]=obj.wv.Gauss_function(x_locations,y_locations,z_locations,turbine,coord,deflection,wind_field,u_initial);
            else
                error('Input velocity model not valid');
            end
        end

        function deficit_combination=combination_function(obj,field,wake)
            if strcmp(obj.combination_model,'Linear')
                deficit_combination=obj.wc.linear_function(field,wake);
            elseif strcmp(obj.combination_model,'Sos')
                deficit_combination=obj.wc.sumofsquares_function(field,wake);
            else
                error('Input combination model not valid');
            end
        end
    end
end