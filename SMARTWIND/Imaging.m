classdef Imaging < handle

    properties

    end

    methods (Static)
        
        function pseudocolor = z_view(windfield,value)
            search_vector=unique(windfield.z);
            [~,idx]=min(abs(search_vector-value));
            x_grid=squeeze(rot90(windfield.x(:,:,idx)));
            y_grid=squeeze(rot90(windfield.y(:,:,idx)));
            u_grid=squeeze(rot90(windfield.u(:,:,idx)));
            pseudocolor=pcolor(x_grid,y_grid,u_grid);
            title(sprintf('Horizontal Cut Plane At %d Meters',value));
            xlabel('x coordinate (m)');
            ylabel('y coordinate (m)');
            c=colorbar;
            c.Label.String = 'Local Wind Speed (m/s)';
            pseudocolor=set(pseudocolor,'EdgeColor','none');
        end

        function pseudocolor = x_view(windfield,value)
            search_vector=unique(windfield.x);
            [~,idx]=min(abs(search_vector-value));
            y_grid=squeeze(windfield.y(idx,:,:));
            z_grid=squeeze(windfield.z(idx,:,:));
            u_grid=squeeze(windfield.u(idx,:,:));
            pseudocolor=pcolor(y_grid,z_grid,u_grid);
            title(sprintf('Vertical Cut Plane At %d Meters',value));
            xlabel('y coordinate (m)');
            ylabel('z coordinate (m)');
            c=colorbar;
            c.Label.String = 'Local Wind Speed (m/s)';
            pseudocolor=set(pseudocolor,'EdgeColor','none');
        end
        function pseudocolor = y_view(windfield,value)
            search_vector=unique(windfield.y);
            [~,idx]=min(abs(search_vector-value));
            x_grid=squeeze(windfield.x(:,idx,:));
            z_grid=squeeze(windfield.z(:,idx,:));
            u_grid=squeeze(windfield.u(:,idx,:));
            pseudocolor=pcolor(x_grid,z_grid,u_grid);
            title(sprintf('Cross Cut Plane At %d Meters',value));
            xlabel('x coordinate (m)');
            ylabel('z coordinate (m)');
            c=colorbar;
            c.Label.String = 'Local Wind Speed (m/s)';
            pseudocolor=set(pseudocolor,'EdgeColor','none');
        end
        function plot_turbines(layout_x,layout_y,windfield,swi)
            wd=windfield.wind_direction;
            for i=1:length(layout_x)
                ya=-windfield.turbinechart.turbines{i,1}.yaw_angle;
                rr=windfield.turbinechart.turbines{i,1}.rotor_radius;
                x_coords=layout_x(i)+linspace(-rr*sind(ya+wd),rr*sind(ya+wd));
                y_coords=layout_y(i)+linspace(-rr*cosd(ya+wd),rr*cosd(ya+wd));
                if swi.turbine_status(i)
                   plot(x_coords,y_coords,'LineWidth',4,'Color','k');
                else
                   plot(x_coords,y_coords,'LineWidth',4,'Color','r');
                end
            end
        end
    end
end