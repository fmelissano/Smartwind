classdef Energy < handle

    properties
        wdata
        aep
        aep_nowake
        aep_opt
        power_matrix_w
        power_matrix_nw
        energy_matrix_w
        energy_matrix_nw
        efficiency_matrix
        optimal_yaw_angle_cell
        power_matrix_opt
        energy_matrix_opt
        gain_matrix
    end

    properties (Dependent)
       baseline_efficiency
       baseline_wake_loss
       energy_gain
       additional_revenue
    end

    methods
        function obj = Energy()
           obj.wdata=Winddatabase;
        end

        function obj = calculate_energy_wake(obj,swi)
            wind_directions=obj.wdata.dir_vector;
            wind_speeds=obj.wdata.vel_vector;
            frequencies=obj.wdata.frequency_matrix;
            obj.power_matrix_w=zeros(length(wind_directions),length(wind_speeds));
            cut_in=swi.windfield.turbinechart.turbines{1,1}.power_thrust_table(1,1);
            cut_off=swi.windfield.turbinechart.turbines{1,1}.power_thrust_table(end,1);
            for i=1:length(wind_directions)
                 for j=1:length(wind_speeds)
                     if frequencies(i,j)==0 || wind_speeds(j)<cut_in || wind_speeds(j)>cut_off
                        obj.power_matrix_w(i,j)=0; 
                     else 
                        swi.windfield.wind_speed=wind_speeds(j);
                        swi.windfield.wind_direction=wind_directions(i);
                        swi.calculate_wake();
                        obj.power_matrix_w(i,j)=swi.get_farm_power();
                     end
                 end
                 f=waitbar(i/length(wind_directions));
                 waitbar(i/length(wind_directions),f,'Calculating AEP baseline...');
            end
            close(f)
            obj.energy_matrix_w=obj.power_matrix_w.*frequencies*365*24;
            obj.aep=sum(obj.energy_matrix_w,'all')/10^9;
        end

        function obj = calculate_energy_nowake(obj,swi)
            wind_directions=obj.wdata.dir_vector;
            wind_speeds=obj.wdata.vel_vector;
            frequencies=obj.wdata.frequency_matrix;
            obj.power_matrix_nw=zeros(length(wind_directions),length(wind_speeds));
            cut_in=swi.windfield.turbinechart.turbines{1,1}.power_thrust_table(1,1);
            cut_off=swi.windfield.turbinechart.turbines{1,1}.power_thrust_table(end,1);           
            for i=1:length(wind_directions)
                 for j=1:length(wind_speeds)
                     if frequencies(i,j)==0 || wind_speeds(j)<cut_in || wind_speeds(j)>cut_off
                        obj.power_matrix_nw(i,j)=0; 
                     else 
                        swi.windfield.wind_speed=wind_speeds(j);
                        swi.windfield.wind_direction=wind_directions(i);
                        swi.calculate_nowake();
                        obj.power_matrix_nw(i,j)=swi.get_farm_power();
                     end
                 end
                 f=waitbar(i/length(wind_directions));
                 waitbar(i/length(wind_directions),f,'Calculating AEP no wake...');
            end
            close(f)
            obj.energy_matrix_nw=obj.power_matrix_nw.*frequencies*365*24;
            obj.aep_nowake=sum(obj.energy_matrix_nw,'all')/10^9;
        end 

        function baseline_efficiency=get.baseline_efficiency(obj)
           baseline_efficiency=obj.aep/obj.aep_nowake;
        end

        function baseline_wake_loss=get.baseline_wake_loss(obj)
           baseline_wake_loss=1-obj.aep/obj.aep_nowake;
        end

        function energy_gain=get.energy_gain(obj)
           energy_gain=(obj.aep_opt-obj.aep)/(obj.aep);
        end

        function additional_revenue=get.additional_revenue(obj)
           pun=123.75;%€/MWh
           additional_revenue=(obj.aep_opt-obj.aep)*pun*10^3;
        end

        function obj=calculate_efficiency(obj,swi,vel_input)
           switch nargin
               case 3
                if isempty(obj.efficiency_matrix)
                    obj.efficiency_matrix=obj.power_matrix_w./obj.power_matrix_nw;
                    obj.efficiency_matrix(obj.efficiency_matrix>1)=1;
                end
                wind_directions=obj.wdata.dir_vector;
                wind_speeds=obj.wdata.vel_vector;
                %frequencies=obj.wdata.frequency_matrix;
                cut_in=swi.windfield.turbinechart.turbines{1,1}.power_thrust_table(1,1);
                cut_off=swi.windfield.turbinechart.turbines{1,1}.power_thrust_table(end,1);
                [~,j]=min(abs(wind_speeds-vel_input));
                for i=1:length(wind_directions)              
                    if obj.power_matrix_w(i,j)==0 && wind_speeds(j)>=cut_in && wind_speeds(j)<=cut_off 
                        swi.windfield.wind_speed=wind_speeds(j);
                        swi.windfield.wind_direction=wind_directions(i);
                        swi.calculate_wake();
                        obj.power_matrix_w(i,j)=swi.get_farm_power();
                    end
                end
                for i=1:length(wind_directions)
                     if obj.power_matrix_nw(i,j)==0 && wind_speeds(j)>=cut_in && wind_speeds(j)<=cut_off 
                        swi.windfield.wind_speed=wind_speeds(j);
                        swi.windfield.wind_direction=wind_directions(i);
                        swi.calculate_nowake();
                        obj.power_matrix_nw(i,j)=swi.get_farm_power();
                     end
                end
                obj.efficiency_matrix(:,j)=obj.power_matrix_w(:,j)./obj.power_matrix_nw(:,j);
                for i=1:length(wind_directions)
                    if obj.efficiency_matrix(i,j)>1
                       obj.efficiency_matrix(i,j)=1;
                    end
                end
                polarhistogram('BinEdges',deg2rad([obj.wdata.dir_vector',360]),'BinCounts',obj.efficiency_matrix(:,j)*100);
                pax=gca;
                pax.ThetaDir = 'clockwise';
                pax.ThetaZeroLocation = 'top';
                rlim([0 100])
                rtickformat('percentage')
                title(sprintf('Power Efficiency At %.1f m/s By Wind Direction',wind_speeds(j)));          
           case 2
                wind_directions=obj.wdata.dir_vector;
                wind_speeds=obj.wdata.vel_vector;
                cut_in=swi.windfield.turbinechart.turbines{1,1}.power_thrust_table(1,1);
                cut_off=swi.windfield.turbinechart.turbines{1,1}.power_thrust_table(end,1);
                for i=1:length(wind_directions) 
                    for j=1:length(wind_speeds)
                        if obj.power_matrix_w(i,j)==0 && wind_speeds(j)>=cut_in && wind_speeds(j)<=cut_off 
                            swi.windfield.wind_speed=wind_speeds(j);
                            swi.windfield.wind_direction=wind_directions(i);
                            swi.calculate_wake();
                            obj.power_matrix_w(i,j)=swi.get_farm_power();
                        end
                    end
                end
                for i=1:length(wind_directions)
                    for j=1:length(wind_speeds)
                         if obj.power_matrix_nw(i,j)==0 && wind_speeds(j)>=cut_in && wind_speeds(j)<=cut_off 
                            swi.windfield.wind_speed=wind_speeds(j);
                            swi.windfield.wind_direction=wind_directions(i);
                            swi.calculate_nowake();
                            obj.power_matrix_nw(i,j)=swi.get_farm_power();
                         end
                    end
                end
                obj.efficiency_matrix=obj.power_matrix_w./obj.power_matrix_nw;
                obj.efficiency_matrix(obj.efficiency_matrix>1)=1;
           end
        end

        function obj=energy_opt(obj,swi)
           wind_directions=obj.wdata.dir_vector;
           wind_speeds=obj.wdata.vel_vector;
           frequencies=obj.wdata.frequency_matrix;
           n_turbines=length(swi.layout_x);
           cut_in=swi.windfield.turbinechart.turbines{1,1}.power_thrust_table(1,1);
           cut_off=swi.windfield.turbinechart.turbines{1,1}.power_thrust_table(end,1);
           obj.calculate_energy_nowake(swi);
           obj.calculate_energy_wake(swi);
           obj.calculate_efficiency(swi);
           obj.optimal_yaw_angle_cell=cell(length(wind_directions),length(wind_speeds));
           obj.power_matrix_opt=zeros(length(wind_directions),length(wind_speeds));
           for i=1:length(wind_directions) 
               for j=1:length(wind_speeds)
                   swi.windfield.wind_speed=wind_speeds(j);
                   swi.windfield.wind_direction=wind_directions(i);
                   if wind_speeds(j)<cut_in || wind_speeds(j)>cut_off
                      obj.optimal_yaw_angle_cell{i,j}=[];
                      obj.power_matrix_opt(i,j)=0;
                   elseif obj.efficiency_matrix (i,j)>=1
                      obj.optimal_yaw_angle_cell{i,j}=zeros(1,n_turbines);
                      obj.power_matrix_opt(i,j)=obj.power_matrix_w(i,j);
                   else
                      ya=swi.yaw_optimization_sq();
                      obj.optimal_yaw_angle_cell{i,j}=ya;
                      obj.power_matrix_opt(i,j)=swi.get_farm_power;
                   end
               end
               f=waitbar(i/length(wind_directions));
               waitbar(i/length(wind_directions),f,'Calculating AEP optimized...');
           end
           close(f)
           obj.gain_matrix=(obj.power_matrix_opt-obj.power_matrix_w)./obj.power_matrix_w;
           obj.energy_matrix_opt=obj.power_matrix_opt.*frequencies*365*24;
           obj.aep_opt=sum(obj.energy_matrix_opt,'all')/10^9;
        end

        function plot_energy_by_speed(obj)
           energy_matrix_speed=sum(obj.energy_matrix_w/10^9,1);
           histogram('BinEdges',[obj.wdata.vel_vector',obj.wdata.vel_vector(end)+obj.wdata.vel_step],'BinCounts',(energy_matrix_speed/obj.aep)*100);
           xlabel('Wind Speed (m/s)')
           ytickformat('percentage')
           title('AEP Percentage By Wind Speed')
        end

        function plot_energy_by_direction(obj)
           energy_matrix_direction=sum(obj.energy_matrix_w/10^9,2);
           polarhistogram('BinEdges',deg2rad([obj.wdata.dir_vector',360]),'BinCounts',(energy_matrix_direction/obj.aep)*100);
           pax=gca;
           pax.ThetaDir = 'clockwise';
           pax.ThetaZeroLocation = 'top';
           rtickformat('percentage')
           title('AEP Percentage By Wind Direction')
        end

        function calculate_relative_power_gain(obj,vel_input)
           wind_directions=obj.wdata.dir_vector;
           wind_speeds=obj.wdata.vel_vector;
           [~,j]=min(abs(wind_speeds-vel_input));
           polarhistogram('BinEdges',deg2rad([wind_directions',360]),'BinCounts',obj.gain_matrix(:,j)*100);
           pax=gca;
           pax.ThetaDir = 'clockwise';
           pax.ThetaZeroLocation = 'top';
           v=max(obj.gain_matrix,[],"all")*100;
           rlim([0 v])
           rtickformat('percentage')
           title(sprintf('Relative Power Gain At %.1f m/s By Wind Direction',wind_speeds(j)));   
        end
        
        function report_wakeloss(obj)
            features={'AEP' 'AEP no wake' 'Efficiency' 'Wake Loss';sprintf('%.2f GWh',obj.aep) sprintf('%.2f GWh',obj.aep_nowake) ...
                sprintf('%.2f %%',obj.baseline_efficiency*100) ...
                sprintf('%.2f %%',obj.baseline_wake_loss*100)};
            C=features(2,:);
            T=cell2table(C);
            headers=features(1,:);
            T.Properties.VariableNames = headers;
            disp(T)
        end

        function report_yaw_optimization(obj)
            features={'AEP' 'AEP optimized' 'Energy Gain' 'Additional Revenue';sprintf('%.2f GWh',obj.aep) sprintf('%.2f GWh',obj.aep_opt) ...
                sprintf('%.2f %%',obj.energy_gain*100) ...
                sprintf('%.2f €/year',obj.additional_revenue)};
            C=features(2,:);
            T=cell2table(C);
            headers=features(1,:);
            T.Properties.VariableNames = headers;
            disp(T)
        end

        function reset(obj)
             obj.aep=[];
             obj.aep_nowake=[];
             obj.power_matrix_w=[];
             obj.power_matrix_nw=[];
             obj.energy_matrix_w=[];
             obj.energy_matrix_nw=[];
             obj.efficiency_matrix=[];
             obj.optimal_yaw_angle_cell=[];
             obj.power_matrix_opt=[];
             obj.energy_matrix_opt=[];
             obj.gain_matrix=[];
        end

    end
end