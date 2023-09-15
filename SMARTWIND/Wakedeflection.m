classdef Wakedeflection < handle

    properties
        kd=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B33:B33'));
        ad_j=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B34:B34'));
        bd_j=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B35:B35'));
        ka=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B25:B25'));
        kb=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B26:B26'));
        alpha=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B27:B27'));
        beta=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B28:B28'));
        ad_g=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B29:B29'));
        bd_g=cell2mat(readcell('inputs.xlsx','Sheet','Models','Range','B30:B30'));
    end

    methods
        function [deflection_jimenez]=Jimenez_function(obj,x_locations,~,turbine,coord,~,~)
            rotor_diameter=turbine.rotor_diameter;
            yaw_angle=-turbine.yaw_angle;
            Ct=turbine.Ct;
            alpha_0=(cosd(yaw_angle))^2*sind(yaw_angle)*Ct/2;
            x_new=x_locations-coord(1);
            %alpha=rad2deg(alpha_0*(1/(1+(obj.kd*x_new/turbine.rotor_radius))).^2);
            dx=alpha_0*(15*(2*obj.kd*x_new/rotor_diameter+1).^4+alpha_0^2)...
            ./(30*obj.kd/rotor_diameter*(2*obj.kd*x_new/rotor_diameter+1).^5)-...
            alpha_0*rotor_diameter*(15+alpha_0^2)/30/obj.kd;
            deflection_jimenez=-(dx+obj.ad_j+obj.bd_j*x_new);
        end
        function [deflection_gauss]=Gauss_function(obj,x_locations,y_locations,turbine,coord,wind_field,u_initial)
            yaw_angle=-turbine.yaw_angle;
            Ct=turbine.Ct;
            rotor_diameter=turbine.rotor_diameter;
            turbulence=turbine.turbulence;
            wind_veer=wind_field.wind_veer;
            u_inf=u_initial;
            ur=u_inf*Ct*cosd(yaw_angle)/2/(1-sqrt(1-Ct*cosd(yaw_angle)));
            u0=u_inf*sqrt(1-Ct);
            C0=1-u0/wind_field.wind_speed;
            M0=C0.*(2-C0);
            E0=C0.^2-3*exp(1/12)*C0+3*exp(1/3);
            x0=rotor_diameter*cosd(yaw_angle)*(1+sqrt(1-Ct))/sqrt(2)/(4*obj.alpha*turbulence+2*obj.beta*(1-sqrt(1-Ct)))+coord(1);
            ky=obj.ka*turbulence+obj.kb;
            kz=obj.ka*turbulence+obj.kb;
            sigma_z0=0.5*rotor_diameter*sqrt(ur./(u_inf+u0));
            sigma_y0=sigma_z0*cosd(yaw_angle)*cosd(wind_veer);
            theta_c0=rad2deg(0.3*deg2rad(yaw_angle)*(1-sqrt(1-Ct*cosd(yaw_angle)))/cosd(yaw_angle));
            delta0=(x0-coord(1))*tand(theta_c0);
            yR=y_locations-coord(2);
            xR=yR*tand(yaw_angle)+coord(1);
            delta_nearwake=((x_locations-xR)./(x0-xR)*delta0)+obj.ad_g+obj.bd_g*(x_locations-coord(1));
            for i=1:numel(delta_nearwake)
                if x_locations(i)<xR(i) || x_locations(i)>x0
                delta_nearwake(i)=0;
                end
            end
            sigma_y=ky*(x_locations-x0)+sigma_y0;
            sigma_z=kz*(x_locations-x0)+sigma_z0;
            for i=1:numel(x_locations)
                if x_locations(i)<x0
                   sigma_y(i)=sigma_y0(i);
                   sigma_z(i)=sigma_z0(i);
                end
            end
            ln_numerator=(1.6+sqrt(M0)).*(1.6*sqrt(sigma_y.*sigma_z./sigma_y0./sigma_z0)-sqrt(M0));
            ln_denominator=(1.6-sqrt(M0)).*(1.6*sqrt(sigma_y.*sigma_z./sigma_y0./sigma_z0)+sqrt(M0));
            delta_farwake=delta0+deg2rad(theta_c0)*E0/5.2.*sqrt(sigma_y0.*sigma_z0/ky/kz./M0).*log(ln_numerator./ln_denominator)+obj.ad_g+obj.bd_g*(x_locations-coord(1));
            for i=1:numel(delta_farwake)
                if x_locations(i)<=x0
                delta_farwake(i)=0;
                end
            end
            deflection_gauss=delta_nearwake+delta_farwake;
        end
    end
end