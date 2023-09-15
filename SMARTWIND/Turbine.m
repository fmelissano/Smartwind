classdef Turbine < handle
    
    properties
        rotor_diameter
        hub_height=cell2mat(readcell('inputs.xlsx','Sheet','Turbine','Range','B4:B4'));
        blade_count=cell2mat(readcell('inputs.xlsx','Sheet','Turbine','Range','B5:B5'))
        pP=cell2mat(readcell('inputs.xlsx','Sheet','Turbine','Range','B6:B6'))
        pT=cell2mat(readcell('inputs.xlsx','Sheet','Turbine','Range','B7:B7'))
        generator_efficiency=cell2mat(readcell('inputs.xlsx','Sheet','Turbine','Range','B8:B8'))
        power_thrust_table
        yaw_angle=cell2mat(readcell('inputs.xlsx','Sheet','Turbine','Range','B10:B10'))
        tilt_angle=cell2mat(readcell('inputs.xlsx','Sheet','Turbine','Range','B11:B11'))
        tsr=cell2mat(readcell('inputs.xlsx','Sheet','Turbine','Range','B9:B9'))
        air_density=cell2mat(readcell('inputs.xlsx','Sheet','WindField','Range','B8:B8'))
        velocities_u=[]
        turbulence=[]
        rotor_radius
        grid
    end
    
    properties (SetAccess=immutable,Hidden)
        ending_table=cell2mat(readcell('inputs.xlsx','Sheet','Turbine','Range','G18:G18'));
    end  
    
    properties (Constant)
        points_turbine_grid=25;
    end

    properties (Dependent)       
        %grid
        %grid_with_yaw
        average_velocity
        Cp
        Ct
        aI
        power
    end

    methods
        function obj=Turbine()
            obj.rotor_diameter=cell2mat(readcell('inputs.xlsx','Sheet','Turbine','Range','B3:B3'));
            obj.power_thrust_table=cell2mat(readcell('inputs.xlsx','Sheet','Turbine','Range',sprintf('A16:C%d',obj.ending_table)));

        end
        

        function set.rotor_diameter(obj,d)
              obj.rotor_diameter=d;
              obj.update_radius;
        end

        function set.rotor_radius(obj,r)
              obj.rotor_radius=r;
              obj.update_grid;
        end

        function cp = fCp(obj,at_wind_speed)
            cp_column=obj.power_thrust_table(:,3);
            wind_speed_column=obj.power_thrust_table(:,1);
            if at_wind_speed < wind_speed_column(1) || at_wind_speed > wind_speed_column(end)
                cp=0;
            else 
                cp=interp1(wind_speed_column,cp_column,at_wind_speed,'linear');
            end
        end

        function ct = fCt(obj,at_wind_speed)
            ct_column=obj.power_thrust_table(:,2);
            wind_speed_column=obj.power_thrust_table(:,1);
            if at_wind_speed < wind_speed_column(1) 
                ct=0.99;
            elseif at_wind_speed > wind_speed_column(end)
                ct=0.0001;
            else
                ct=interp1(wind_speed_column,ct_column,at_wind_speed,'linear');
            end
        end
  
%         function grid = get.grid(obj)
%         num_points=sqrt(obj.points_turbine_grid);
%         horizontal=linspace(-obj.rotor_radius,obj.rotor_radius,num_points);
%         vertical=linspace(obj.rotor_radius,-obj.rotor_radius,num_points);
%         grid=zeros(obj.points_turbine_grid,3);
%         count_points=linspace(1,obj.points_turbine_grid,obj.points_turbine_grid);
%         grid(:,3)=count_points;
%             for v=1:length(vertical)
%                 for h=1:length(horizontal)
%                      grid(num_points*(v-1)+h,1)=[horizontal(h)];
%                      grid(num_points*(v-1)+h,2)=[vertical(v)];
%                 end
%             end
%             for n=obj.points_turbine_grid:-1:1
%                 if sqrt(grid(n,1)^2+grid(n,2)^2)>obj.rotor_radius
%                 grid(n,:)=[];
%                 end
%             end
%         end

%         function grid_with_yaw=get.grid_with_yaw(obj)
%             grid_with_yaw=zeros(length(obj.grid),3);
%             grid_with_yaw(:,1)=obj.grid(:,1)*sind(obj.yaw_angle);
%             grid_with_yaw(:,2)=obj.grid(:,1)*cosd(obj.yaw_angle);
%             grid_with_yaw(:,3)=obj.grid(:,2);
%         end


%         function data=calculate_swept_area_velocities(obj,local_wind_speed,coord,x,y,z)
%             x_rel=obj.grid_with_yaw(:,1);
%             y_rel=obj.grid_with_yaw(:,2);
%             z_rel=obj.grid_with_yaw(:,3);
%             distance=zeros(numel(x),length(x_rel));
%             idx=zeros(length(x_rel),1);
%             data=zeros(length(x_rel),1);
%             for i=1:length(x_rel)
%                 for j=1:numel(x)
%                 distance(j,i)=sqrt((coord(1)-x(j))^2+(coord(2)+y_rel(i)-y(j))^2+(coord(3)+z_rel(i)-z(j))^2);
%                 end
%                 [~,idx(i)]=min(distance(:,i));
%                 data(i)=local_wind_speed(idx(i));
%             end
%         end

          function data=calculate_turbine_velocities(obj,local_wind_speed,coord,x,y,z,windfield,nt)
            y_rel=obj.grid(:,1);
            z_rel=obj.grid(:,2);            
            if strcmp(windfield.enable_wfr,'No')
                data=zeros(length(y_rel),1);
                selected_layer=local_wind_speed(:,:,nt);
                for i=1:length(y_rel)
                   data(i)=selected_layer(obj.grid(i,3));
                end
            else
            distance=zeros(numel(x),length(y_rel));
            idx=zeros(length(y_rel),1);
            data=zeros(length(y_rel),1);
                for i=1:length(y_rel)
                    for j=1:numel(x)
                        distance(j,i)=sqrt((coord(1)-x(j))^2+(coord(2)+y_rel(i)-y(j))^2+(coord(3)+z_rel(i)-z(j))^2);
                    end
                    [~,idx(i)]=min(distance(:,i));
                    data(i)=local_wind_speed(idx(i));
                end
            end
        end

        function obj=update_velocities(obj,u_wake,windfield,coord,rotated_x,rotated_y,rotated_z,u_initial,nt)
            local_wind_speed_u=u_initial-u_wake;
            obj.velocities_u=calculate_turbine_velocities(obj,local_wind_speed_u,coord,rotated_x,rotated_y,rotated_z,windfield,nt);
        end
        
        function average_velocity=get.average_velocity(obj)
            average_velocity=(mean((obj.velocities_u).^3))^(1/3);
        end

        function Cp=get.Cp(obj)
            pW=obj.pP/3;
            yaw_effective_velocity=(obj.average_velocity)*(cosd(obj.yaw_angle))^pW;
            Cp=fCp(obj,yaw_effective_velocity);
        end

        function Ct=get.Ct(obj)
            Ct=fCt(obj,obj.average_velocity)*cosd(obj.yaw_angle);
        end

        function aI=get.aI(obj)
            aI=0.5/cosd(obj.yaw_angle)*(1-sqrt(1-obj.Ct*cosd(obj.yaw_angle)));
        end

        function power=get.power(obj)
            pW=obj.pP/3;
            yaw_effective_velocity=obj.average_velocity*(cosd(obj.yaw_angle))^pW;
            cptmp=obj.Cp;
            power=0.5*obj.air_density*pi*obj.rotor_radius^2*obj.generator_efficiency*yaw_effective_velocity^3*cptmp;
        end
            
        function obj=update_turbulence_intensity(obj,windfield,wake,turbine_coord,wake_coord,turbine_wake,area)
            i=wake.ti_initial;
            constant=wake.ti_constant;
            ai=wake.ti_ai;
            downstream=wake.ti_downstream;
            added_ti=area*constant*(turbine_wake.aI^ai)*(windfield.turbulence_intensity^i)*((turbine_coord(1)-wake_coord(1))/obj.rotor_diameter)^(downstream);
            obj.turbulence=sqrt(obj.turbulence^2+added_ti^2);
        end
        
        function obj=update_radius(obj)
            obj.rotor_radius=obj.rotor_diameter/2;
        end

        function obj=update_grid(obj)
            num_points=sqrt(obj.points_turbine_grid);
            horizontal=linspace(-obj.rotor_radius,obj.rotor_radius,num_points);
            vertical=linspace(obj.rotor_radius,-obj.rotor_radius,num_points);
            obj.grid=zeros(obj.points_turbine_grid,3);
            count_points=linspace(1,obj.points_turbine_grid,obj.points_turbine_grid);
            obj.grid(:,3)=count_points;
            for v=1:length(vertical)
                for h=1:length(horizontal)
                     obj.grid(num_points*(v-1)+h,1)=[horizontal(h)];
                     obj.grid(num_points*(v-1)+h,2)=[vertical(v)];
                end
            end
            for n=obj.points_turbine_grid:-1:1
                if sqrt(obj.grid(n,1)^2+obj.grid(n,2)^2)>obj.rotor_radius
                obj.grid(n,:)=[];
                end
            end
        end 
    end
end


