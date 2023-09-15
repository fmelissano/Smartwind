classdef Wakevelocity < handle

    properties
        we_j=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B15:B15'));
        me=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B18:D18'));
        we_mz=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B19:B19'));
        aU=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B20:B20'));
        bU=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B21:B21'));
        mU=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B22:D22'));
        ka=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B25:B25'));
        kb=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B26:B26'));
        alpha=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B27:B27'));
        beta=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B28:B28'));
        ad_g=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B29:B29'));
        bd_g=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B30:B30'));
    end

    methods
%         function [turb_u_wake,turb_v_wake,turb_w_wake] = Jensen_function(obj,x_locations,y_locations,z_locations,turbine,...
%                 coord,deflection,wake,wind_field)
%             m=obj.we_j;
%             x_new=x_locations-coord(1);
%             b=turbine.rotor_radius;
%             boundary_line=m*x_new+b;
%             y_upper=boundary_line+coord(2)+deflection;
%             y_lower=-boundary_line+coord(2)+deflection;
%             z_upper=boundary_line+coord(3);
%             z_lower=-boundary_line+coord(3);
%             percent_deficit=2*turbine.aI*(turbine.rotor_diameter/((2*obj.we_j*x_new)+turbine.rotor_diameter)).^2;
%             for i=1:numel(percent_deficit)
%                 if x_locations(i)-coord(1)<0 || y_locations(i)>y_upper(i) || y_locations(i)<y_lower(i) || z_locations(i)>z_upper(i) || z_locations(i)<z_lower(i)
%                     percent_deficit(i)=0;
%                 else
%                     percent_deficit(i)=percent_deficit(i);
%                 end
%             end
%             deficit=percent_deficit.*wind_field.u_initial;
%             turb_u_wake=deficit;%wind_field.u_initial-(wind_field.u_initial-deficit).*cosd(angle);
%             turb_v_wake=zeros(size(wind_field.u_initial));%(wind_field.u_initial-deficit).*sind(angle);
%             turb_w_wake=zeros(size(wind_field.u_initial));            
%         end
        
            function [turb_u_wake,turb_v_wake,turb_w_wake] = Jensen_function(obj,x_locations,y_locations,z_locations,turbine,...
                coord,deflection,~,u_initial)
            rotor_radius=turbine.rotor_radius; 
            aI=turbine.aI;
            rotor_diameter=turbine.rotor_diameter;
            y_wakedistance=abs(y_locations-coord(2)-deflection);
            z_wakedistance=abs(z_locations-coord(3));
            x_new=x_locations-coord(1);
            percent_deficit=zeros(size(x_locations));
            wake=rotor_radius+obj.we_j*x_new;
            bool_wake=((z_wakedistance<=wake) & (y_wakedistance<=wake));
            for i=1:numel(bool_wake)
                if x_locations(i)-coord(1)<0
                    bool_wake(i)=0;
                end
            end
            for i=1:numel(bool_wake)
                if bool_wake(i)==1
                     percent_deficit(i)=2*aI*(rotor_diameter/((2*obj.we_j*x_new(i))+rotor_diameter)).^2;
                else
                     percent_deficit(i)=0;
                end
            end
            deficit=percent_deficit.*u_initial;
            turb_u_wake=deficit;
            turb_v_wake=zeros(size(u_initial));
            turb_w_wake=zeros(size(u_initial));            
        end

        function [turb_u_wake,turb_v_wake,turb_w_wake] = Multizone_function(obj,x_locations,y_locations,z_locations,turbine,...
                coord,deflection,~,u_initial)
            yaw_angle=-turbine.yaw_angle;
            rotor_radius=turbine.rotor_radius;
            aI=turbine.aI;
            rotor_diameter=turbine.rotor_diameter;
            mu=obj.mU/cosd(obj.aU+obj.bU*yaw_angle);
            y_wakedistance=abs(y_locations-coord(2)-deflection);
            z_wakedistance=abs(z_locations-coord(3));
            x_new=x_locations-coord(1);
            nearwake=rotor_radius+obj.we_mz*obj.me(1)*x_new;
            farwake=rotor_radius+obj.we_mz*obj.me(2)*x_new;
            mixing=rotor_radius+obj.we_mz*obj.me(3)*x_new;
            bool_matrix=zeros(size(x_locations));
            percent_deficit=zeros(size(x_locations));
            bool_nearwake=((z_wakedistance<=nearwake) & (y_wakedistance<=nearwake));
            bool_matrix=bool_matrix+bool_nearwake;
            bool_farwake=((z_wakedistance<=farwake) & (y_wakedistance<=farwake));
            bool_matrix=bool_matrix+bool_farwake;
            bool_mixing=((z_wakedistance<=mixing) & (y_wakedistance<=mixing));
            bool_matrix=bool_matrix+bool_mixing;
            for i=1:numel(bool_matrix)
                if x_locations(i)-coord(1)<0
                    bool_matrix(i)=0;
                end
            end
            for i=1:numel(bool_matrix)
                if bool_matrix(i)==1
                     percent_deficit(i)=2*aI*(rotor_diameter/((2*obj.we_mz*x_new(i)*mu(3))+rotor_diameter)).^2;
                elseif bool_matrix(i)==2
                     percent_deficit(i)=2*aI*(rotor_diameter/((2*obj.we_mz*x_new(i)*mu(2))+rotor_diameter)).^2;
                elseif bool_matrix(i)==3
                     percent_deficit(i)=2*aI*(rotor_diameter/((2*obj.we_mz*x_new(i)*mu(1))+rotor_diameter)).^2;
                else
                     percent_deficit(i)=0;
                end
            end
            deficit=percent_deficit.*u_initial;
            turb_u_wake=deficit;
            turb_v_wake=zeros(size(u_initial));
            turb_w_wake=zeros(size(u_initial));            
        end
        
        function [turb_u_wake,turb_v_wake,turb_w_wake] = Gauss_function(obj,x_locations,y_locations,z_locations,turbine,...
                coord,deflection,wind_field,u_initial)
            yaw_angle=-turbine.yaw_angle;
            Ct=turbine.Ct;
            rotor_diameter=turbine.rotor_diameter;
            turbulence=turbine.turbulence;
            wind_veer=wind_field.wind_veer;
            hub_height=turbine.hub_height;
            u_inf=u_initial;
            ur=u_inf*Ct*cosd(yaw_angle)/2/(1-sqrt(1-Ct*cosd(yaw_angle)));
            %ur_trap=ur(:,:,20);
            u0=u_inf*sqrt(1-Ct);
            %u0_trap=u0(:,:,20);
            sigma_z0=0.5*rotor_diameter*sqrt(ur./(u_inf+u0));
            %sigma_z0_trap=sigma_z0(:,:,20);
            sigma_y0=sigma_z0*cosd(yaw_angle)*cosd(wind_veer);
            %sigma_y0_trap=sigma_y0(:,:,20);
            x0=rotor_diameter*cosd(yaw_angle)*(1+sqrt(1-Ct))/sqrt(2)/(4*obj.alpha*turbulence+2*obj.beta*(1-sqrt(1-Ct)))+coord(1);
            ky=obj.ka*turbulence+obj.kb;
            kz=obj.ka*turbulence+obj.kb;
            yR=y_locations-coord(2);
            xR=yR*tand(yaw_angle)+coord(1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%START DEBUG%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            rt=turbine.rotor_radius;
            ya=-turbine.yaw_angle;
            xR(xR-coord(1)>4*rt*sind(abs(ya)))=4*rt*sind(ya) + coord(1);
            xR(xR-coord(1)<-4*rt*sind(abs(ya)))=-4*rt*sind(ya)+coord(1);

%             rt=turbine.rotor_radius;
%             ya=turbine.yaw_angle;
%             for i=1:numel(xR)
%               if xR(i)-coord(1)>4*rt*sind(abs(ya))
%                   xR(i)=4*rt*sind(ya) + coord(1);
%               elseif xR(i)-coord(1)<-4*rt*sind(abs(ya))
%                   xR(i)=-4*rt*sind(ya)+coord(1);
%               end
%             end

%             for i=1:numel(xR)
%               if xR(i)-coord(1)>4*turbine.rotor_radius*sind(abs(turbine.yaw_angle))
%                   xR(i)=4*turbine.rotor_radius*sind(turbine.yaw_angle) + coord(1);
%               elseif xR(i)-coord(1)<-4*turbine.rotor_radius*sind(abs(turbine.yaw_angle))
%                   xR(i)=-4*turbine.rotor_radius*sind(turbine.yaw_angle)+coord(1);
%               end
%             end

%             mask=zeros(size(xR));
%             for i=1:numel(xR)
%                 %if xR(i)>3*turbine.rotor_radius*sind(turbine.yaw_angle)
%                    %mask(i)=1;
%                 if xR(i)<=3*turbine.rotor_radius*sind(turbine.yaw_angle) && xR(i)>=-3*turbine.rotor_radius*sind(turbine.yaw_angle)
%                     mask(i)=1;
%                 %elseif xR(i)<-3*turbine.rotor_radius*sind(turbine.yaw_angle)
%                     %mask(i)=-1;
%                 else
%                     mask(i)=0;
%                 end
%             end            
%             interval_elements=mask.*xR;
%             for i=1:numel(xR)
%                 if xR(i)>3*turbine.rotor_radius*sind(turbine.yaw_angle)
%                    xR(i)=max(interval_elements(:));
%                 elseif xR(i)<-3*turbine.rotor_radius*sind(turbine.yaw_angle)
%                    xR(i)=min(interval_elements(:));
%                 else
%                     xR(i)=xR(i);
%                 end
%             end

%             [~,idj]=min(-xR(1,:,1)+8*turbine.rotor_radius*sind(turbine.yaw_angle));
%             [~,idk]=min(-xR(1,:,1)-8*turbine.rotor_radius*sind(turbine.yaw_angle));
%             for i=1:numel(xR)
%                 if xR(i)>8*turbine.rotor_radius*sind(turbine.yaw_angle)
%                     xR(i)=xR(1,idj,1);
%                 elseif xR(i)<-8*turbine.rotor_radius*sind(turbine.yaw_angle)
%                     xR(i)=xR(1,idk,1);
%                 else
%                     xR(i)=xR(i);
%                 end
%             end
%%%%%%%%%%%%%%%%%%%%%%%%%%%FINISH_DEBUG%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           
            %count=sum(xR>=x0);
            %xR_trap=xR(:,:,20);
            sigma_y_nw=(x0-x_locations)./(x0-xR)*0.501*rotor_diameter*sqrt(Ct/2)+(x_locations-xR)./(x0-xR).*sigma_y0;
            %sigma_y_nw_trap=sigma_y_nw(:,:,20);
            sigma_z_nw=(x0-x_locations)./(x0-xR)*0.501*rotor_diameter*sqrt(Ct/2)+(x_locations-xR)./(x0-xR).*sigma_z0;
            %sigma_z_nw_trap=sigma_z_nw(:,:,20);
            for i=1:numel(x_locations)
                if x_locations(i)<xR(i)
                  sigma_y_nw(i)=0.5*rotor_diameter;
                  sigma_z_nw(i)=0.5*rotor_diameter;
                end 
            end
            a=cosd(wind_veer)^2./(2*sigma_y_nw).^2+sind(wind_veer)^2./(2*sigma_z_nw).^2;
            b=-sind(2*wind_veer)/(4*sigma_y_nw).^2+sind(2*wind_veer)/(4*sigma_z_nw).^2;
            c=sind(wind_veer)^2./(2*sigma_y_nw).^2+cosd(wind_veer)^2./(2*sigma_z_nw).^2;
            exp_term=exp(-a.*(y_locations-coord(2)-deflection).^2).*exp(2*b.*(y_locations-coord(2)-deflection).*(z_locations-hub_height)).*exp(-c.*(z_locations-hub_height).^2);
            %exp_term_trap=exp_term(:,:,20);
            percent_deficit_nw=(1-sqrt(1-Ct*cosd(yaw_angle)*(rotor_diameter)^2/8./sigma_y_nw./sigma_z_nw)).*exp_term;
            %percent_deficit_trap=percent_deficit_nw(:,:,20);
            deficit_nw=percent_deficit_nw.*u_inf;
            for i=1:numel(deficit_nw)
                 if x_locations(i)<xR(i) || x_locations(i)>x0
                 deficit_nw(i)=0;
                 end
            end
            sigma_y_fw=ky*(x_locations-x0)+sigma_y0;
            sigma_z_fw=kz*(x_locations-x0)+sigma_z0;
            for i=1:numel(x_locations)
                if x_locations(i)<x0
                sigma_y_fw(i)=sigma_y0(i);
                sigma_z_fw(i)=sigma_z0(i);
                end
            end
            a=cosd(wind_veer)^2./(2*sigma_y_fw).^2+sind(wind_veer)^2./(2*sigma_z_fw).^2;
            b=-sind(2*wind_veer)/(4*sigma_y_fw).^2+sind(2*wind_veer)/(4*sigma_z_fw).^2;
            c=sind(wind_veer)^2./(2*sigma_y_fw).^2+cosd(wind_veer)^2./(2*sigma_z_fw).^2;
            exp_term=exp(-a.*(y_locations-coord(2)-deflection).^2).*exp(2*b.*(y_locations-coord(2)-deflection).*(z_locations-hub_height)).*exp(-c.*(z_locations-hub_height).^2);
            percent_deficit_fw=(1-sqrt(1-Ct*cosd(yaw_angle)*(rotor_diameter)^2/8./sigma_y_fw./sigma_z_fw)).*exp_term;
            deficit_fw=percent_deficit_fw.*u_inf;
            for i=1:numel(deficit_fw)
                if x_locations(i)<x0
                deficit_fw(i)=0;
                end
            end
            deficit=deficit_nw+deficit_fw;
            turb_u_wake=deficit;
            turb_v_wake=zeros(size(u_initial));
            turb_w_wake=zeros(size(u_initial));             
        end
    end
end