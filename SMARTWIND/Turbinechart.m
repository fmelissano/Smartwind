classdef Turbinechart < handle

    properties
        layout_x%=cell2mat(readcell('inputs.xlsx','Sheet','Layout','Range','B3:B6'));
        layout_y%=cell2mat(readcell('inputs.xlsx','Sheet','Layout','Range','C3:C6'));
        turbines
    end

    properties (Dependent)
        layout_z
        coordinates   
        indexes
        turbines_cell_array
    end

    methods

        function obj=Turbinechart(layout_x,layout_y,turbines)
            obj.layout_x=layout_x;
            obj.layout_y=layout_y;
            obj.turbines=turbines;
%             third_dimension_vector=zeros(length(obj.layout_x),1);
%             for i=1:length(obj.layout_x)
%                 third_dimension_vector(i,1)=obj.turbines{i,1}.hub_height;
%             end
%             obj.coordinates=[obj.layout_x,obj.layout_y,third_dimension_vector];
            %obj.turbines=cell(length(obj.layout_x),1);
            %for i=1:length(obj.layout_x)
                %obj.turbines{i,1}=obj.turbine;
            %end                
        end

        %function turbines=get.turbines(obj)
            %turbines=cell(length(obj.layout_x),1);
            %for i=1:length(obj.layout_x)
                %turbines{i,1}=obj.turbine;
            %end                     
        %end

        %function set.turbines(obj,val)
            %obj.turbines=val;
        %end

        function layout_z=get.layout_z(obj)
            layout_z=zeros(length(obj.layout_x),1);
            for i=1:length(obj.layout_x)
                layout_z(i,1)=obj.turbines{i,1}.hub_height;
            end
        end

        function coordinates=get.coordinates(obj)
            coordinates=[obj.layout_x,obj.layout_y,obj.layout_z];
        end
        
        function indexes=get.indexes(obj)
            indexes=(1:1:length(obj.layout_x))';
        end 

        function turbines_cell_array=get.turbines_cell_array(obj)
            turbines_cell_array=cell(length(obj.layout_x),3);
            for i=1:length(obj.layout_x)
            turbines_cell_array{i,1}=obj.coordinates(i,:);
            turbines_cell_array{i,2}=obj.turbines{i,1};
            turbines_cell_array{i,3}=obj.indexes(i,1);
            end
        end

        function rotated_turbines_cell_array=rotated(obj,center,angle)
            cell_array=obj.turbines_cell_array;
            rotated_turbines_cell_array=cell_array;
            for i=1:length(obj.layout_x)
                point=[cell_array{i,1}(1),cell_array{i,1}(2),cell_array{i,1}(3)];
                [r]=rotation(point,center,angle);
                rotated_turbines_cell_array{i,1}(1)=r(1);
                rotated_turbines_cell_array{i,1}(2)=r(2);
                rotated_turbines_cell_array{i,1}(3)=r(3);
            end
        end
    end

    methods(Static)

        function sorted_turbines_cell_array=sortinx(input_cell)
            [l,~]=size(input_cell);
            indexes=zeros(l,1);
            for i=1:l
                indexes(i)=input_cell{i,1}(1);
            end
            [~,indexes_sorted]=sort(indexes);
            sorted_turbines_cell_array=cell(size(input_cell));
            for i=1:l
                sorted_turbines_cell_array{i,1}=input_cell{indexes_sorted(i),1};
                sorted_turbines_cell_array{i,2}=input_cell{indexes_sorted(i),2};
                sorted_turbines_cell_array{i,3}=input_cell{indexes_sorted(i),3};                
            end
        end
    end
end