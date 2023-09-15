classdef Windfield < handle
    
    properties
        wind_speed=cell2mat(readcell('inputs.xlsx','Sheet','WindField','Range','B3:B3'));
        wind_direction%=cell2mat(readcell('inputs.xlsx','Sheet','WindField','Range','B4:B4'))-270;
        turbulence_intensity=cell2mat(readcell('inputs.xlsx','Sheet','WindField','Range','B5:B5'));
        wind_shear=cell2mat(readcell('inputs.xlsx','Sheet','WindField','Range','B6:B6'));
        wind_veer=cell2mat(readcell('inputs.xlsx','Sheet','WindField','Range','B7:B7'));
        specified_wind_height=cell2mat(readcell('inputs.xlsx','Sheet','WindField','Range','B9:B9'));
        enable_wfr=readcell('inputs.xlsx','Sheet','WindField','Range','B12:B12');
        resolution=cell2mat(readcell('inputs.xlsx','Sheet','WindField','Range','B13:B15'));
        turbinechart
        wake
        u
%         wake_matrix
%         v
%         w
    end

    properties (Dependent)
        bounds
        x
        y
        z
        u_initial
%         v_initial
%         w_initial
    end
    
    methods

        function obj=Windfield(turbinechart,wake)
            obj.turbinechart=turbinechart;
            obj.wake=wake;
            obj.wind_direction=cell2mat(readcell('inputs.xlsx','Sheet','WindField','Range','B4:B4'));
        end
       
        function bounds=get.bounds(obj)
            coords_x=obj.turbinechart.coordinates(:,1);
            coords_y=obj.turbinechart.coordinates(:,2);
            h=obj.turbinechart.coordinates(1,3);
            d=obj.turbinechart.turbines{1}.rotor_diameter;
            x_min=min(coords_x)-2*d;
            x_max=max(coords_x)+10*d;
            y_min=min(coords_y)-2*d;
            y_max=max(coords_y)+2*d;
            z_min=0.1;
            z_max=4*h;
            bounds=[x_min,x_max,y_min,y_max,z_min,z_max];
        end

        function x=get.x(obj)
            if strcmp(obj.enable_wfr,'No')
               x=zeros(sqrt(obj.turbinechart.turbines{1,1}.points_turbine_grid),...
                   sqrt(obj.turbinechart.turbines{1,1}.points_turbine_grid),...
                   length(obj.turbinechart.layout_x));
               for i=1:length(obj.turbinechart.layout_x)
                   x(:,:,i)=obj.turbinechart.layout_x(i);
               end
            else
                 bd=obj.bounds;
                 res=obj.resolution;
                 x_direction=linspace(bd(1),bd(2),res(1));
                 y_direction=linspace(bd(3),bd(4),res(2));
                 z_direction=linspace(bd(5),bd(6),res(3));
                 [~,yy,~]=meshgrid(y_direction,x_direction,z_direction);
                 x=yy;
            end
        end

        function y=get.y(obj)
            if strcmp(obj.enable_wfr,'No')
               y=zeros(sqrt(obj.turbinechart.turbines{1,1}.points_turbine_grid),...
                   sqrt(obj.turbinechart.turbines{1,1}.points_turbine_grid),...
                   length(obj.turbinechart.layout_x));
               for i=1:length(obj.turbinechart.layout_x)
                   radius=obj.turbinechart.turbines{i,1}.rotor_radius;
                   vector=linspace(-radius,radius,sqrt(obj.turbinechart.turbines{i,1}.points_turbine_grid))+obj.turbinechart.layout_y(i);
                   for j=1:sqrt(obj.turbinechart.turbines{i,1}.points_turbine_grid)
                       y(j,:,i)=vector;
                   end
               end
            else
                 bd=obj.bounds;
                 res=obj.resolution;
                 x_direction=linspace(bd(1),bd(2),res(1));
                 y_direction=linspace(bd(3),bd(4),res(2));
                 z_direction=linspace(bd(5),bd(6),res(3));
                 [xx,~,~]=meshgrid(y_direction,x_direction,z_direction);
                 y=xx;
            end
        end

        function z=get.z(obj)            
            if strcmp(obj.enable_wfr,'No')
               z=zeros(sqrt(obj.turbinechart.turbines{1,1}.points_turbine_grid),...
                   sqrt(obj.turbinechart.turbines{1,1}.points_turbine_grid),...
                   length(obj.turbinechart.layout_x));
               for i=1:length(obj.turbinechart.layout_x)
                   radius=obj.turbinechart.turbines{i,1}.rotor_radius;
                   vector=linspace(-radius,radius,sqrt(obj.turbinechart.turbines{i,1}.points_turbine_grid))+obj.turbinechart.layout_z(i);
                   for k=1:sqrt(obj.turbinechart.turbines{i,1}.points_turbine_grid)
                       z(:,k,i)=flip(vector);
                   end
               end
            else
                 bd=obj.bounds;
                 res=obj.resolution;
                 x_direction=linspace(bd(1),bd(2),res(1));
                 y_direction=linspace(bd(3),bd(4),res(2));
                 z_direction=linspace(bd(5),bd(6),res(3));
                 [~,~,z]=meshgrid(y_direction,x_direction,z_direction);
            end
        end
        
        function u_initial=get.u_initial(obj)
            h=obj.specified_wind_height;
            u_initial=obj.wind_speed*(obj.z/h).^obj.wind_shear;
        end

%         function v_initial=get.v_initial(obj)
%             v_initial=zeros(size(obj.u_initial));
%         end
% 
%         function w_initial=get.w_initial(obj)
%             w_initial=zeros(size(obj.u_initial));
%         end

        function [rotated_x,rotated_y,rotated_z]=rotate_grid(obj,center)
            x_offset=obj.x-center(1);
            y_offset=obj.y-center(2);
            rotated_x=x_offset*cosd(obj.wind_direction)-y_offset*sind(obj.wind_direction)+center(1);
            rotated_y=x_offset*sind(obj.wind_direction)+y_offset*cosd(obj.wind_direction)+center(2);
            rotated_z=obj.z;
        end

        function set.wind_direction(obj,value)
            obj.wind_direction=encase180(value-270);
        end

        function obj=calculatewake(obj)
            u_init=obj.u_initial;
            obj.u=u_init;
%             obj.v=obj.v_initial;
%             obj.w=obj.w_initial;
            bd=obj.bounds;
            center=[mean([bd(1),bd(2)])...
                   ,mean([bd(3),bd(4)]),0];
            rotated_chart=obj.turbinechart.rotated(center,obj.wind_direction);
            [rotated_x,rotated_y,rotated_z]=obj.rotate_grid(center);
            sorted_chart=obj.turbinechart.sortinx(rotated_chart);
            [sorted_coords,~,sorted_indexes]=extract_features_tc(sorted_chart);
            if strcmp(obj.wake.turbulence_choice,'Yes') || strcmp(obj.wake.velocity_model,'Gauss') || strcmp(obj.wake.deflection_model,'Gauss')
               for i=1:length(obj.turbinechart.layout_x)
                   obj.turbinechart.turbines{sorted_indexes(i),1}.turbulence=obj.turbulence_intensity;
               end
            end
            u_wake=zeros(size(obj.u));
%             v_wake=zeros(size(obj.u));       
%             w_wake=zeros(size(obj.u));

            for i=1:length(obj.turbinechart.layout_x)
                obj.turbinechart.turbines{sorted_indexes(i),1}.update_velocities(u_wake,obj,...
                sorted_coords(i,:),rotated_x,rotated_y,rotated_z,u_init,sorted_indexes(i));
                [deflection]=obj.wake.deflection_function(rotated_x,...
                    rotated_y,obj.turbinechart.turbines{sorted_indexes(i),1},...
                    sorted_coords(i,:),obj,u_init);
                [turb_u_wake,~,~]=obj.wake.velocity_function...
                    (rotated_x,rotated_y,rotated_z,obj.turbinechart.turbines{sorted_indexes(i),1},...
                    sorted_coords(i,:),deflection,obj,u_init);
                if strcmp(obj.wake.turbulence_choice,'Yes') || strcmp(obj.wake.velocity_model,'Gauss') || strcmp(obj.wake.deflection_model,'Gauss')
                    for j=1:length(obj.turbinechart.layout_x)
                        if sorted_coords(j,1)>sorted_coords(i,1) && abs(sorted_coords(j,2)-sorted_coords(i,2))<2*obj.turbinechart.turbines{sorted_indexes(i),1}.rotor_diameter
                           undisturbed_velocities=obj.turbinechart.turbines{sorted_indexes(j),1}.calculate_turbine_velocities(u_init,sorted_coords(j,:),rotated_x,rotated_y,rotated_z,obj,sorted_indexes(j));
                           disturbed_velocities=obj.turbinechart.turbines{sorted_indexes(j),1}.calculate_turbine_velocities(u_init-turb_u_wake,sorted_coords(j,:),rotated_x,rotated_y,rotated_z,obj,sorted_indexes(j));
                           area_overlap=obj.calculate_overlap(undisturbed_velocities,disturbed_velocities,obj.turbinechart.turbines{sorted_indexes(j),1});
                           if area_overlap>0
                               obj.turbinechart.turbines{sorted_indexes(j),1}.update_turbulence_intensity(obj,obj.wake,sorted_coords(j,:),sorted_coords(i,:),obj.turbinechart.turbines{sorted_indexes(i),1},area_overlap);
                           end
                        end
                     end
                end
                u_wake=obj.wake.combination_function(u_wake,turb_u_wake);
%                 v_wake=v_wake+turb_v_wake;
%                 w_wake=w_wake+turb_w_wake;
            end

            obj.u=u_init-u_wake;
%             obj.v=obj.v_initial+v_wake;
%             obj.w=obj.w_initial+w_wake;
        end

        function obj=calculatenowake(obj)
            u_init=obj.u_initial;
            obj.u=obj.u_initial;            
%             obj.v=obj.v_initial;
%             obj.w=obj.w_initial;
            bd=obj.bounds;
            center=[mean([bd(1),bd(2)])...
                   ,mean([bd(3),bd(4)]),0];
            rotated_chart=obj.turbinechart.rotated(center,obj.wind_direction);
            [rotated_x,rotated_y,rotated_z]=obj.rotate_grid(center);
            [rotated_coords,~,rotated_indexes]=extract_features_tc(rotated_chart);
            u_wake=zeros(size(obj.u));
            for i=1:length(obj.turbinechart.layout_x)
                obj.turbinechart.turbines{rotated_indexes(i),1}.update_velocities(u_wake,obj,...
                rotated_coords(i,:),rotated_x,rotated_y,rotated_z,u_init,i);
            end            
        end
      
        function not_affecting_turbines=calculate_affturbines(obj)
            u_init=obj.u_initial;
            obj.u=u_init;
            wake_matrix=zeros(length(obj.turbinechart.layout_x));
            bd=obj.bounds;
            center=[mean([bd(1),bd(2)])...
                   ,mean([bd(3),bd(4)]),0];
            rotated_chart=obj.turbinechart.rotated(center,obj.wind_direction);
            [rotated_x,rotated_y,rotated_z]=obj.rotate_grid(center);
            sorted_chart=obj.turbinechart.sortinx(rotated_chart);
            [sorted_coords,~,sorted_indexes]=extract_features_tc(sorted_chart);
            for i=1:length(obj.turbinechart.layout_x)
                obj.turbinechart.turbines{sorted_indexes(i),1}.turbulence=obj.turbulence_intensity;
            end
            u_wake=zeros(size(obj.u));
            for i=1:length(obj.turbinechart.layout_x)
                obj.turbinechart.turbines{sorted_indexes(i),1}.update_velocities(u_wake,obj,...
                sorted_coords(i,:),rotated_x,rotated_y,rotated_z,u_init,sorted_indexes(i));
                [deflection]=obj.wake.deflection_function(rotated_x,...
                    rotated_y,obj.turbinechart.turbines{sorted_indexes(i),1},...
                    sorted_coords(i,:),obj,u_init);
                [turb_u_wake,~,~]=obj.wake.velocity_function...
                    (rotated_x,rotated_y,rotated_z,obj.turbinechart.turbines{sorted_indexes(i),1},...
                    sorted_coords(i,:),deflection,obj,u_init);
                for j=1:length(obj.turbinechart.layout_x)
                    if sorted_coords(j,1)>sorted_coords(i,1) %&& abs(sorted_coords(j,2)-sorted_coords(i,2))<2*obj.turbinechart.turbines{sorted_indexes(i),1}.rotor_diameter
                       undisturbed_velocities=obj.turbinechart.turbines{sorted_indexes(j),1}.calculate_turbine_velocities(u_init,sorted_coords(j,:),rotated_x,rotated_y,rotated_z,obj,sorted_indexes(j));
                       disturbed_velocities=obj.turbinechart.turbines{sorted_indexes(j),1}.calculate_turbine_velocities(u_init-turb_u_wake,sorted_coords(j,:),rotated_x,rotated_y,rotated_z,obj,sorted_indexes(j));
                       area_overlap=obj.calculate_overlap(undisturbed_velocities,disturbed_velocities,obj.turbinechart.turbines{sorted_indexes(j),1});
                       if area_overlap>0
                           wake_matrix(sorted_indexes(i),sorted_indexes(j))=1;
                           obj.turbinechart.turbines{sorted_indexes(j),1}.update_turbulence_intensity(obj,obj.wake,sorted_coords(j,:),sorted_coords(i,:),obj.turbinechart.turbines{sorted_indexes(i),1},area_overlap);
                       end
                    end
                end
                u_wake=obj.wake.combination_function(u_wake,turb_u_wake);
            end
            not_affecting_turbines=find(all(wake_matrix==0,2));
        end

        function sorted_indexes=get_ordered_turbines(obj)
            bd=obj.bounds;
            center=[mean([bd(1),bd(2)])...
                   ,mean([bd(3),bd(4)]),0];
            rotated_chart=obj.turbinechart.rotated(center,obj.wind_direction);
            sorted_chart=obj.turbinechart.sortinx(rotated_chart);
            [~,~,sorted_indexes]=extract_features_tc(sorted_chart);
        end
    end

    methods (Static)
        function disturbance=calculate_overlap(undisturbed_velocity,disturbed_velocity,turbine)
            affected_points=sum(undisturbed_velocity-disturbed_velocity>0.05);
            disturbance=affected_points/length(turbine.grid);
        end
    end

end

