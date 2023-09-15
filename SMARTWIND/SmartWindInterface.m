classdef SmartWindInterface <handle

    properties
        layout_x
        layout_y
        turbine_status
        windfield
        imaging
        energy
        ya_lower=0
        ya_upper=25
        ya_options=26
    end

    properties (SetAccess=immutable,Hidden)
        ending_row=cell2mat(readcell('inputs.xlsx','Sheet','Layout',...
            'Range','G5:G5'));
    end


    methods

        function obj=SmartWindInterface()
            obj.layout_x=cell2mat(readcell('inputs.xlsx','Sheet',...
                'Layout','Range',sprintf('B3:B%d',obj.ending_row)));
            obj.layout_y=cell2mat(readcell('inputs.xlsx','Sheet'...
                ,'Layout','Range',sprintf('C3:C%d',obj.ending_row)));
            wake=Wake;
            n_turbines=length(obj.layout_x);
            turbines=cell(n_turbines,1);
            for i=1:n_turbines
                turbines{i,1}=Turbine;
            end
            turbinechart=Turbinechart(obj.layout_x,obj.layout_y,turbines);
            obj.turbine_status=ones(n_turbines,1);
            obj.windfield=Windfield(turbinechart,wake);
            obj.imaging=Imaging;
            obj.energy=Energy;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%SIMULATION_PART%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %SET_LAYOUT is a function to set a layout different from the one 
        %initialized in the excel file. The input must be a matrix nx2 with
        %n the number of turbines; for each turbine coordinate x and y must
        %be expressed. Alternatively, use the layout generators to set an 
        %array of turbines (eventually rotated) or a random layout.
        %Remember to set the layout before setting any other attribute of
        %other classes (velocity,direction,...), otherwise any other
        %property will be reset.
        function obj=set_layout(obj,matrix)
            obj.layout_x=matrix(:,1);
            obj.layout_y=matrix(:,2);
            wake=Wake;
            n_turbines=length(obj.layout_x);
            turbines=cell(n_turbines,1);
            for i=1:n_turbines
                turbines{i,1}=Turbine;
            end
            turbinechart=Turbinechart(obj.layout_x,obj.layout_y,turbines);
            obj.turbine_status=ones(n_turbines,1);
            obj.windfield=Windfield(turbinechart,wake);
        end
        
        %EXCLUDE_TURBINES is a function to exclude some turbines temporary
        %from a layout and make them "transparent". This could be useful in
        %reality due to faulted turbines that cannot be involved in the 
        %calculation process and in the yaw optimization. The input must be
        %a vector of integers that correspond to the numbers of the
        %excluded turbines (in the same order as presented in layout).
        %Remember to call this function before setting any other attribute
        %of other classes. This function has the priority with respect to
        %other commands except for the function "set_layout".
        function obj=exclude_turbines(obj,exc)
            obj.reset_farm_keep_layout();
            obj.turbine_status=ones(length(obj.layout_x),1);
            for i=1:length(exc)
                turb=exc(i);
                sz=length(obj.windfield.turbinechart.turbines...
                    {turb,1}.power_thrust_table);
                obj.windfield.turbinechart.turbines...
                    {turb,1}.power_thrust_table(:,2)=repelem(0.0001,sz);
                obj.windfield.turbinechart.turbines...
                    {turb,1}.power_thrust_table(:,3)=zeros(sz,1);
                obj.turbine_status(exc(i))=0;
            end
        end
        
        %CALCULATE_WAKE is the core function of the program. It enables to 
        %calculate the wind flow speed at the turbine points thanks to 
        %several wake models listed in the Excel file. As a result, also
        %the characteristic wind speeds of each turbine are calculated and
        %stored in the windfield object, together with the power of the
        %turbines, the turbulence of the turbines and the farm power. To
        %speed up the calculations (for example in case of plant online
        %optimization) it is recommended NOT to enable the resolution so
        %that the wind flow field is calculated only at the turbine
        %points. Instead, to have a graphical representation of the whole
        %field the resolution option must be enabled. Clearly this will
        %affect significantly the computational time, if the resolution is
        %low (e.g [50 30 10]) also the accuracy of the calculated 
        % parameters. On the other hand, [250 150 50] will be a medium 
        %resolution, while [500 300 100] will be a high resolution       
        function obj=calculate_wake(obj)
            obj=obj.windfield.calculatewake();
        end
        
        %CALCULATE_NOWAKE is a function mainly used to compute the flow
        % conditions in the irrealistic condition of absence of wake. This
        % is useful to compute the wake losses and the efficiency of the
        % wind farm. Clearly, at a given velocity the power produced by 
        % each turbine will be the same regardless the direction
        function obj=calculate_nowake(obj)
            obj=obj.windfield.calculatenowake();
        end
        
        %RESET_FARM is a function to restart the interface object so that
        %every modification done in the Matlab working file to the 
        % properties of the object are cancelled and the inputs are again
        % the same of the input file. 
        function obj=reset_farm(obj)
            obj.layout_x=cell2mat(readcell('inputs.xlsx','Sheet',...
                'Layout','Range',sprintf('B3:B%d',obj.ending_row)));
            obj.layout_y=cell2mat(readcell('inputs.xlsx','Sheet',...
                'Layout','Range',sprintf('C3:C%d',obj.ending_row)));
            wake=Wake;
            n_turbines=length(obj.layout_x);
            turbines=cell(n_turbines,1);
            for i=1:n_turbines
                turbines{i,1}=Turbine;
            end
            turbinechart=Turbinechart(obj.layout_x,obj.layout_y,turbines);
            obj.turbine_status=ones(n_turbines,1);
            obj.windfield=Windfield(turbinechart,wake);
        end
        
        %RESET_FARM_KEEP_LAYOUT is a function to restart the interface
        %properties with the exception of the layout modified in the Matlab
        %working file. As a result, with the exception of the layout, all
        %other input properties will be the same of the input Excel file.
        function obj=reset_farm_keep_layout(obj)
            wake=Wake;
            n_turbines=length(obj.layout_x);
            turbines=cell(n_turbines,1);
            for i=1:n_turbines
                turbines{i,1}=Turbine;
            end
            turbinechart=Turbinechart(obj.layout_x,obj.layout_y,turbines);
            obj.turbine_status=ones(n_turbines,1);
            obj.windfield=Windfield(turbinechart,wake);
        end
        
        %GET_YAW_ANGLES is a useful function that outputs a vector with the
        %yaw angles of all the turbines, with the same order the turbines
        %are listed in the layout properties. This is a shortcut, since the
        %yaw angles are stored in different turbine objects and recalling
        %them would require a for loop in the code each time.
        function yaw_vector=get_yaw_angles(obj)
            yaw_vector=zeros(1,length(obj.layout_x));
            for i=1:length(yaw_vector)
                yaw_vector(i)=obj.windfield.turbinechart.turbines...
                    {i,1}.yaw_angle;
            end
        end
        
        %GET_TILT_ANGLES is a function that has the same goal of the
        %'get_yaw_angles()' function. However, no tilt angle steering is
        %employed at the moment in this program, but this could be an
        %interesting option for the future of wind turbines.
        function tilt_vector=get_tilt_angles(obj)
            tilt_vector=zeros(1,length(obj.layout_x));
            for i=1:length(tilt_vector)
                tilt_vector(i)=obj.windfield.turbinechart.turbines...
                    {i,1}.tilt_angle;
            end
        end

        %SET_YAW_ANGLES is a useful function that, given an input vector of
        %yaw angles (one for each turbine), modifies the property of the
        %yaw angle for each turbine object.This is a necessary shortcut,
        %since otherwise a for loop would have been necessary to store the
        %values in each object. The yaw angles refer to each turbine with 
        %the same order turbines are listed in the layout properties
        function obj=set_yaw_angles(obj,input_vector)
            if length(input_vector)~=length(obj.layout_x)
                error(['Turbines number and yaw angles number do' ...
                    ' not correspond'])
            else
                for i=1:length(input_vector)
                    obj.windfield.turbinechart.turbines...
                        {i,1}.yaw_angle=input_vector(i);
                end
            end
        end

        %SET_TILT_ANGLES is a function that has the same goal of the
        %'set_yaw_angles()' function. However, no tilt angle steering is
        %employed at the moment in this program, but this could be an
        %interesting option for the future of wind turbines.
        function obj=set_tilt_angles(obj,input_vector)
            if length(input_vector)~=length(obj.layout_x)
                error(['Turbines number and tilt angles number do' ...
                    ' not correspond'])
            else
                for i=1:length(input_vector)
                    obj.windfield.turbinechart.turbines...
                        {i,1}.tilt_angle=input_vector(i);
                end
            end
        end
        
        %GET_TURBINES_POWER is a function that outputs a vector with the
        %power of each turbine. This function has to be called after
        %the wake calculation or yaw optimization to output the turbine
        %powers in a specific situation.The powers refer to each 
        %turbine with the same order turbines are listed in the layout
        %properties
        function power_cell=get_turbines_power(obj)
            power_cell=zeros(length(obj.layout_x),1);
            for i=1:length(obj.layout_x)
                power_cell(i)=obj.windfield.turbinechart.turbines...
                    {i,1}.power;
            end
        end
        
        %GET_FARM_POWER is a function that outputs the total power produced
        %by the wind farm, obtained by summing all the individual powers
        %produced by each turbine. It has to be called after the wake
        %calculation or yaw optimization.
        function total_power=get_farm_power(obj)
            power_cell=zeros(length(obj.layout_x),1);
            for i=1:length(obj.layout_x)
                power_cell(i)=obj.windfield.turbinechart.turbines...
                    {i,1}.power;
            end
            total_power=sum(power_cell);
        end
        
        %GET_TURBINES_VELOCITY is a function that outputs a vector
        %containing as element the velocities at each turbine. Since in
        %this software the turbine are represented by several grid points
        %placed on the rotor surface, the cubic mean is calculated for each
        %turbine to get a representative speed for each turbine. It has 
        % to be called after the wake calculation or yaw optimization. 
        % The velocities refer to each turbine with the same order turbines
        % are listed in the layout properties
        function velocities_cell=get_turbines_velocity(obj)
            velocities_cell=zeros(length(obj.layout_x),1);
            for i=1:length(obj.layout_x)
                velocities_cell(i)=obj.windfield.turbinechart.turbines...
                    {i,1}.average_velocity;
            end
        end

        %GET_TURBINES_TURBULENCE is a function that outputs a vector
        %containing the turbulence value of each turbine calculated with 
        %Crespo-Hernandez model. Since some models (Jensen, Jimenez,
        %Multizone) do not require turbulence calculation, the command to
        %calculate turbulence has to be enabled manually. On the other hand
        %Gaussian models require the turbulence for calculations so the
        %turbulence values are automatically calculated. Clearly, this 
        %function has to be called after wake calculation or yaw
        %optimization. The velocities refer to each turbine with the same 
        %order turbinesare listed in the layout properties
        function turbulence_cell=get_turbines_turbulence(obj)
            turbulence_cell=zeros(length(obj.layout_x),1);
            for i=1:length(obj.layout_x)
                turbulence_cell(i)=obj.windfield.turbinechart.turbines...
                    {i,1}.turbulence;
            end
        end
        
        %SHOW_HORPLANE is a function that outputs a rendering of the wind
        %farm from above, cutting a plane at some z-axis value, that has to
        %be specified in the input. The most representative cutpoint is
        %obviously the hub height of the turbines. If the cutpoint is the
        %hub height and all the turbines have the same height also the
        %turbine sections are shown in the picture. If the turbines are red
        %, it means that they have been excluded. This function has to be
        %called after 'calculate_wake()' and resolution must be enabled.
        function pseudocolor=show_horplane(obj,cutpoint)
             hub_height_cell=zeros(length(obj.layout_x),1);
             for i=1:length(obj.layout_x)
                hub_height_cell(i)=obj.windfield.turbinechart.turbines...
                    {i,1}.hub_height;
             end
             pseudocolor=obj.imaging.z_view(obj.windfield,cutpoint);
             if all(hub_height_cell==cutpoint)
                hold on
                obj.imaging.plot_turbines(obj.layout_x,obj.layout_y,...
                    obj.windfield,obj);
             end
        end
        
        %SHOW_VERPLANE is a function that renders the points of the flow
        %field in the y-z plane, cutting it at some x-axis value, that has
        %to be specified in the input. This function has to be
        %called after 'calculate_wake()' and resolution must be enabled.
        function pseudocolor=show_verplane(obj,cutpoint)
             pseudocolor=obj.imaging.x_view(obj.windfield,cutpoint);
        end

        %SHOW_CROSSPLANE is a function that renders the points of the flow
        %field in the x-z plane, cutting it at some y-axis value, that has
        %to be specified in the input. This function has to be
        %called after 'calculate_wake()' and resolution must be enabled.
        function pseudocolor=show_crossplane(obj,cutpoint)
             pseudocolor=obj.imaging.y_view(obj.windfield,cutpoint);
        end

        %%%%%%%%%%%%%%%%%%%ENERGY_CALCULATION_PART%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %LOAD_WINDDATA_O1 is the first option to input the wind speed and
        %wind direction frequencies from the Winddatabase to calculate AEP.
        % In this case wind direction frequencies are listed directly by 
        % the user, while wind speed frequencies are calculated by a 
        % 2-parameters Weibull distribution.
        function obj=load_winddata_o1(obj)
            obj.energy.wdata.build_fmatrix_o1();
        end

        %LOAD_WINDDATA_O2 is the second option to input the wind speed and
        %wind direction frequencies from the Winddatabase to calculate AEP.
        % In this case wind direction frequencies and wind speed 
        % frequencies are listed directly but separately by the user and
        % then combined by the software
        function obj=load_winddata_o2(obj)
            obj.energy.wdata.build_fmatrix_o2();
        end

        %LOAD_WINDDATA_O3 is the third option to input the wind speed and
        %wind direction frequencies from the Winddatabase to calculate AEP. 
        %This is the most preferred option due to the precision of the 
        %frequencies. In fact, in this option the frequency of each 
        %combination of wind speed and wind direction is directly reported
        %by the user. The amount of bins for velocity and direction can be 
        %chosen by the user, but we recommend 1 m/s for velocity and 5° for
        %direction
        function obj=load_winddata_o3(obj)
            obj.energy.wdata.build_fmatrix_o3();
        end
        
        %PLOT_WSPEEDS is a function that, given the frequency
        %distributions of the wind speeds, plots an histogram with the
        %relative frequency for each wind speed bin. Wind data have to be
        %loaded before calling this function.
        function obj=plot_wspeeds(obj)
            if isempty(obj.energy.wdata.frequency_matrix)
                error('Please load wind data before plotting')
            else
                obj.energy.wdata.plot_ws_distribution();
            end
        end

        %PLOT_WDIRECTIONS is a function that, given the frequency
        %distributions of the wind directions, plots a polar histogram
        %with the relative frequency for each wind direction bin. Wind 
        %data have to be loaded before calling this function.
        function obj=plot_wdirections(obj)
            if isempty(obj.energy.wdata.frequency_matrix)
                error('Please load wind data before plotting')
            else
                obj.energy.wdata.plot_wd_distribution();
            end            
        end

        %PLOT_WINDROSE is a function that, given the frequency
        %distributions of wind speeds and wind directions, plots a wind
        %rose polar histogram. Differently from the wind directions plot,
        %for each wind direction in this plot there is a subdivision in
        %wind speed frequency classes. Wind data have to be loaded before
        %calling this function.
        function obj=plot_windrose(obj)
            if isempty(obj.energy.wdata.frequency_matrix)
                error('Please load wind data before plotting')
            else
            obj.energy.wdata.plot_windrose_distribution();
            end
        end
        
        %RESET_WINDDATA is a function to empty all the data previously
        %loaded as wind speed and wind direction frequencies. Use this
        %function if it is necessary to change the input wind speed or wind
        %direction distributions or if it is necessary to change loading
        %option. 
        function obj=reset_winddata(obj)
            obj.energy=Energy();
        end
        
        %CALCULATE_AEP_NOWAKE is a function that outputs the Annual Energy
        %Production in the irrealistic hypothesis of the absence of wake.
        %This calculation is useful to compute the energy efficiency of the
        %wind plant for the whole year. Basically, the "calculate_nowake"
        %function is repeated for each combination of wind speed and wind
        %direction bin (except for combinations whose frequency is equal to
        %zero) and multiplied by its respective absolute frequency during a
        %year. The results are summed together. Wind data have to be loaded 
        % before calling this function.
        function obj=calculate_aep_nowake(obj)
            if isempty(obj.energy.wdata.frequency_matrix)
                error('Please load wind data before calculating AEP')
            else    
            obj.energy.calculate_energy_nowake(obj);
            end
        end
        
        %CALCULATE_AEP_WAKE is an important function that outputs the
        %Annual Energy Production considering the losses due to the wake
        %presence. Basically, the "calculate_wake" function is repeated for
        %each combination of wind speed and wind direction bin (except for
        %combinations whose frequency is equal to zero) and multiplied by
        %its respective absolute frequancy during a year. The results are
        %summed together. Wind data have to be loaded before calling this
        %function.
        function obj=calculate_aep_baseline(obj)
            if isempty(obj.energy.wdata.frequency_matrix)
                error('Please load wind data before calculating AEP')
            else
           obj.energy.calculate_energy_wake(obj);
            end
        end

        %RESET_ENERGIES is a function that enables the user to delete all
        %the properties stored in the object "Energies", so that only the
        %wind data loaded are kept saved. Use this function if it is
        %necessary to delete the results of the previous energies
        %calculations without affecting the loaded wind data
        function obj=reset_energies(obj)
            obj.energy.reset()
        end
        
        %PLOT_AEP_WSPEEDS is a function that plots a histogram with the
        %velocity bins on x-axis and with the relative contribution of each
        %velocity bin to the AEP on the y-axis. Wind data have to be
        %loaded and AEP has to be calculated before calling this function.
        function obj=plot_aep_wspeeds(obj)
            if isempty(obj.energy.aep)
                error('Please calculate AEP before plotting')
            else    
               obj.energy.plot_energy_by_speed()
            end
        end 
        
        %PLOT_AEP_WDIRECTIONS is a function that plots a histogram with the
        %direction bins on x-axis and with the relative contribution of 
        %each direction bin to the AEP on the y-axis. Wind data have to be
        %loaded and AEP has to be calculated before calling this function.
        function obj=plot_aep_wdirections(obj)
            if isempty(obj.energy.aep)
                error('Please calculate AEP before plotting')
            else    
               obj.energy.plot_energy_by_direction()
            end
        end

        %PLOT_EFF_WDIRECTIONS is a function that, given as an input a
        %velocity value, plots a polar histogram with the efficiency of
        %that wind farm for each direction. It is useful to evaluate for
        %which directions the wind farm is mostly penalized. Wind data have
        %to be loaded before calling this function.
        function obj=plot_eff_wdirections(obj,ws)
           if isempty(obj.energy.aep) || isempty(obj.energy.aep_nowake)
                error('Please calculate AEP before calculating efficiency')
           else    
              obj.energy.calculate_efficiency(obj,ws);
           end
        end

        %REPORT_ENERGIES is a function that prints in the Matlab Command
        %Window the values of the AEP considering the wake effect, AEP in
        %the hypothetical condition of no wake, the resulting efficiency
        %and the wake losses. Wind data have to be loaded and AEP have to
        %be calculated before calling this function.
        function obj=report_energies(obj)
            if isempty(obj.energy.aep) || isempty(obj.energy.aep_nowake)
                error('Please calculate AEP before printing report')
            else    
               obj.energy.report_wakeloss()
            end
        end
  
%%%%%%%%%%%%%%%%%%%%%%%%OPTIMIZATION_PART%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

        %YAW_OPTIMIZATION_GB is a function that uses the SQP algorithm
        %(gradient-based) to find the best configuration of yaw_angles to 
        %maximize power. The drawbacks of this optimization method are the
        %longer computational time if the number of turbine rises and the
        %risk to encounter local minima for some configurationsthat could 
        %not output the maximum power.
        function opt_yaw_angles = yaw_optimization_gb(obj)
            minimum_yaw_angle=obj.ya_lower;
            maximum_yaw_angle=obj.ya_upper;
            indexes=1:1:length(obj.layout_x);
            not_affecting_turbines=obj.windfield.calculate_affturbines();
            n_turbs=length(indexes)-length(not_affecting_turbines);
            if n_turbs == 0
               opt_yaw_angles=zeros(1,length(indexes));
               return
            end
            for i=1:length(not_affecting_turbines)
                pos=indexes==not_affecting_turbines(i);
                indexes(pos)=[];
            end
            opts = optimoptions('fmincon','Algorithm','sqp',...
                'StepTolerance',10^(-3));
            %x0=25*rand(1,n_turbs);
            x0=repelem(12,n_turbs);
            %x0=obj.get_yaw_angles;
            fun=@(x)obj.cost_function(x,indexes);
            A=[];
            b=[];
            Aeq=[];
            beq=[];
            lb=repelem(minimum_yaw_angle,n_turbs);
            ub=repelem(maximum_yaw_angle,n_turbs);            
            nonlcon=[];
            opt_yaw_angles_partial=fmincon(fun,x0,A,b,Aeq,beq,lb,ub,...
            nonlcon,opts);
            opt_yaw_angles=zeros(length(obj.layout_x),1);
            for i=1:length(indexes)
                opt_yaw_angles(indexes(i))=opt_yaw_angles_partial(i);
            end
            obj.set_yaw_angles(opt_yaw_angles);
            %opt_yaw_angles=round(opt_yaw_angles);
            %obj.set_yaw_angles(opt_yaw_angles);
            obj.calculate_wake();
        end

        %YAW_OPTIMIZATION_GA is a function that uses the genetic algorithm
        %to find the best configuration of yaw angles to maximize power.
        %The integer constraint is done mainly to reduce the computational
        %time and due to the fact that decimal yaw angles are not of
        %practical interest. Max generation number is set to 200, while
        %Population size to 10; this leads to acceptable computational time
        %and satisfactory results. However, since GA is a stochastic
        %algorithm, it may happen that at the end of a simulation some
        %yaw angles have some errors and power is not completely optimized.
        %A higher number of populations would reduce even further this
        %possibility but would lead to unacceptable computational time.
        function opt_yaw_angles = yaw_optimization_ga(obj)
            minimum_yaw_angle=obj.ya_lower;
            maximum_yaw_angle=obj.ya_upper;
            indexes=1:1:length(obj.layout_x);
            not_affecting_turbines=obj.windfield.calculate_affturbines();
            n_turbs=length(indexes)-length(not_affecting_turbines);
            if n_turbs == 0
               opt_yaw_angles=zeros(1,length(indexes));
               return
            end
            for i=1:length(not_affecting_turbines)
                pos=indexes==not_affecting_turbines(i);
                indexes(pos)=[];
            end
            rng default
            fun=@(x)obj.cost_function(x,indexes);
            nvars=n_turbs;
            Aineq=[];
            Bineq=[];
            Aeq=[];
            beq=[];
            lb=repelem(minimum_yaw_angle,n_turbs);
            ub=repelem(maximum_yaw_angle,n_turbs);            
            nonlcon=[];
            intcon=linspace(1,nvars,nvars);
            genmax=200+length(obj.layout_x);
            opts = optimoptions('ga','MaxGenerations',genmax,...
            'PopulationSize',12,'PlotFcn', @gaplotbestf);
            opt_yaw_angles_partial=ga(fun,nvars,Aineq,Bineq,Aeq,beq,lb,ub,...
            nonlcon,intcon,opts);
            opt_yaw_angles=zeros(length(obj.layout_x),1);
            for i=1:length(indexes)
                opt_yaw_angles(indexes(i))=opt_yaw_angles_partial(i);
            end
            obj.set_yaw_angles(opt_yaw_angles);
            obj.calculate_wake();
        end

        %YAW_OPTIMIZATION_MIGA is a function that uses Mixed Integer GA
        %Optimization to determine the optimal configuration of yaw angles.
        %Here, the values that yaw angles could assume to optimize total
        %farm power are restricted to some equally spaced values between
        %the admitted boundaries. This is an interesting option since in
        %reality is not required a precision of 1° of yaw angles due to
        %measurement uncertainties and the negligible effect of finely
        %adjusting the yaw angles on total power. This option lets to
        %decrease the parameter Max Generation and as a result reduce the
        %compuational time. However, since GA is a stochastic algorithm, it
        %may happen that at the end of a simulation some yaw angles have
        %some errors and power is not completely optimized.
        function opt_yaw_angles = yaw_optimization_miga(obj)
            n_turbs=length(obj.layout_x);  
            low=obj.ya_lower;
            upp=obj.ya_upper;
            fun=@(x)obj.fast_cost_function(x,low,upp);
            nvars=n_turbs;
            Aineq=[];
            Bineq=[];
            Aeq=[];
            beq=[];
            lb=repelem(1,n_turbs);
            ub=repelem(obj.ya_options,n_turbs);            
            nonlcon=[];
            intcon=linspace(1,nvars,nvars);
            opts = optimoptions('ga','MaxGenerations',130,...
                'PopulationSize',10,'PlotFcn', @gaplotbestf);
            opt_yaw_angles=ga(fun,nvars,Aineq,Bineq,Aeq,beq,lb,ub,...
                nonlcon,intcon,opts);
            opt_yaw_angles=low+(upp-low)*(opt_yaw_angles-1)...
                /(obj.ya_options-1);
            obj.set_yaw_angles(opt_yaw_angles);
        end

        %YAW_OPTIMIZATION_SQ is a function that optimizes the yaw 
        %angles to maximize total farm power. This algorithm is
        %gradient-free and assumes that the optimal angle of a turbine is
        %not correlated with the yaw angles of the downstream turbines.
        %For each turbine i sequentially, all turbine
        %options are simulated and the farm power for each option is stored
        %in a matrix. The yaw angle that maximizes the farm power is chosen
        %and fixed for that turbine. The process is repeated for all other
        %turbines. The number ofoptions that each turbine can assume can be
        %chosen by the user. This algorithm gives a speed computational
        %advantage with respect to other algorithms since it is basically a
        %sequence of calculate_wake(). Furthermore, from the tests made
        %with several layouts, it is also the most precise in finding the
        %optimal yaw angles.
        function opt_yaw_angles=yaw_optimization_sq(obj)
            n_turbs=length(obj.layout_x);  
            yaw_angles=zeros(n_turbs,1);
            winning_power=0;
            options=linspace(obj.ya_lower,obj.ya_upper,obj.ya_options);
            p=zeros(length(options),1);
            sorted_indexes=obj.windfield.get_ordered_turbines();
            not_affecting_turbines=obj.windfield.calculate_affturbines();
            if length(sorted_indexes)==length(not_affecting_turbines)
               opt_yaw_angles=zeros(1,length(sorted_indexes));
               return
            end
            for i=1:length(not_affecting_turbines)
                pos=sorted_indexes==not_affecting_turbines(i);
                sorted_indexes(pos)=[];
            end
            if any(obj.turbine_status==0)
                fau=find(~obj.turbine_status);
                for i=1:length(fau)
                    idx=sorted_indexes==fau(i);
                    sorted_indexes(idx)=[];
                end
            end
            for j=1:length(sorted_indexes)
                for k=1:length(options)
                    yaw_angles(sorted_indexes(j))=options(k);
                    obj.set_yaw_angles(yaw_angles);
                    obj.calculate_wake();
                    p(k)=obj.get_farm_power();
                end
                if max(p)>winning_power
                    [~,fau]=max(p);
                    yaw_angles(sorted_indexes(j))=options(fau);
                end
            end
            opt_yaw_angles=yaw_angles';
            obj.set_yaw_angles(opt_yaw_angles);
            obj.calculate_wake();
        end

%ANN_optimizer, loading file is necessary
%         function [opt_yaw_angles,final_power]=nn_optimizer(obj)
%             load Mdl.mat;
%             a=obj.windfield.wind_speed;
%             b=obj.windfield.wind_direction;
%             n_turbs=length(obj.layout_x);  
%             yaw_angles=zeros(n_turbs,1);
%             winning_power=0;
%             options=linspace(obj.ya_lower,obj.ya_upper,obj.ya_options);
%             p_matrix=zeros(length(options),1);
%             sorted_indexes=obj.windfield.get_ordered_turbines();
%             not_affecting_turbines=obj.windfield.calculate_affturbines();
%             for i=1:length(not_affecting_turbines)
%                 pos=sorted_indexes==not_affecting_turbines(i);
%                 sorted_indexes(pos)=[];
%             end
%             for j=1:length(sorted_indexes)
%                 for k=1:length(options)
%                     yaw_angles(sorted_indexes(j))=options(k);
%                     c=yaw_angles;
%                     p_matrix(k)=predict(Mdl,[a b c']);
%                 end
%                 if max(p_matrix)>winning_power
%                     [winning_power,idx]=max(p_matrix);
%                     yaw_angles(sorted_indexes(j))=options(idx);
%                 end
%             end
%             opt_yaw_angles=yaw_angles';
%             obj.set_yaw_angles(opt_yaw_angles);
%             d=opt_yaw_angles;
%             final_power=predict(Mdl,[a b d]);
%         end
        
        %CALCULATE_AEP_OPTIMIZED is a function that outputs the AEP
        %optimized due to yaw steering for a given relative frequancy
        %distribution of wind speeds and wind directions. Wind data have to
        %be loaded before calling this function.
        function obj=calculate_aep_optimized(obj)
            if isempty(obj.energy.wdata.frequency_matrix)
                error('Please load wind data before calculating AEP opt')
            else
                obj.energy.energy_opt(obj)
            end
        end

        %REPORT_ENERGIES_OPT is a function that prints in the Matlab 
        %Command Window the values of the AEP considering the wake effect,
        %AEP optimized, the increased percentage in AEP, and the additional
        %revenue. AEP optimized has to be calculated before calling this
        %function.
        function obj=report_energies_opt(obj)
            if isempty(obj.energy.aep_opt)
                error('Please calculate opt AEP before printing report')
            else    
               obj.energy.report_yaw_optimization()
            end
        end

        %PLOT_GAIN_WDIRECTIONS is a function that, given a wind_speed as an
        %input, returns a polar histogram with the gain in power for each
        %wind direction after yaw optimization. This function is effective
        %to investigate which directions are more affected by the yaw
        %steering than others. Optimized AEP has to be calculated before
        %calling this function.
        function obj=plot_gain_wdirections(obj,ws)
           if isempty(obj.energy.aep_opt)
                error('Please calculate opt AEP before printing report')
           else    
              obj.energy.calculate_relative_power_gain(ws);
           end
        end
    end

    methods (Access=private)
        function power=cost_function(obj,yaw_angles,aff_turbines)
            vector=zeros(length(obj.layout_x));
            for i=1:length(aff_turbines)
                vector(aff_turbines(i))=yaw_angles(i);
            end
            obj.set_yaw_angles(vector);
            obj.calculate_wake();
            power=-obj.get_farm_power();
        end

        function power=fast_cost_function(obj,yaw_angles,low,upp)
            all_yaws=linspace(low,upp,obj.ya_options);
            yaw_angles=all_yaws(yaw_angles);
            obj.set_yaw_angles(yaw_angles);
            obj.calculate_wake();
            power=-obj.get_farm_power();
        end    
    end
end