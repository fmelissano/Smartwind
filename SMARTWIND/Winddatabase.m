classdef Winddatabase < handle

    properties
        o1_k=cell2mat(readcell('wind_database.xlsx','Sheet','Option_1','Range','B2:B2'));
        o1_lambda=cell2mat(readcell('wind_database.xlsx','Sheet','Option_1','Range','B3:B3'));
        o1_dir_freq
        o2_vel_freq
        o2_dir_freq
        o3_table
    end

    properties
        vel_vector=[]
        vel_step=[]
        dir_vector=[]
        dir_step=[]
        frequency_matrix=[]
    end

    properties (SetAccess=immutable,Hidden)
        o1_dir_ending_table=cell2mat(readcell('wind_database.xlsx','Sheet','Option_1','Range','J4:J4'));
        o2_vel_ending_table=cell2mat(readcell('wind_database.xlsx','Sheet','Option_2','Range','E4:E4'));
        o2_dir_ending_table=cell2mat(readcell('wind_database.xlsx','Sheet','Option_2','Range','L4:L4'));
        o3_ending_table=cell2mat(readcell('wind_database.xlsx','Sheet','Option_3','Range','F4:F4'));
    end

    properties (Dependent)
       frequency_matrix_vel
       frequency_matrix_dir
    end

    methods
        function obj = Winddatabase()
            obj.o1_dir_freq=cell2mat(readcell('wind_database.xlsx','Sheet','Option_1','Range',sprintf('F2:G%d',obj.o1_dir_ending_table)));
            obj.o2_vel_freq=cell2mat(readcell('wind_database.xlsx','Sheet','Option_2','Range',sprintf('A2:B%d',obj.o2_vel_ending_table)));
            obj.o2_dir_freq=cell2mat(readcell('wind_database.xlsx','Sheet','Option_2','Range',sprintf('H2:I%d',obj.o2_dir_ending_table)));
            obj.o3_table=cell2mat(readcell('wind_database.xlsx','Sheet','Option_3','Range',sprintf('A2:C%d',obj.o3_ending_table)));
        end
        
        function obj=build_fmatrix_o1(obj)
            weibull_velocities=(0:1:30)';
            obj.vel_vector=weibull_velocities;
            obj.dir_vector=obj.o1_dir_freq(:,1);
            weibull_frequencies=(obj.o1_k/obj.o1_lambda)*(weibull_velocities/obj.o1_lambda).^(obj.o1_k-1).*exp(-((weibull_velocities/obj.o1_lambda).^obj.o1_k));
            o1_vel_freq=[weibull_velocities weibull_frequencies];
            obj.dir_step=obj.o1_dir_freq(2,1)-obj.o1_dir_freq(1,1);
            obj.vel_step=o1_vel_freq(2,1)-o1_vel_freq(1,1);
            frequency_matrix_tbn=zeros(length(obj.o1_dir_freq),length(o1_vel_freq));
            for i=1:length(obj.o1_dir_freq)
                for j=1:length(o1_vel_freq)
                    frequency_matrix_tbn(i,j)=obj.o1_dir_freq(i,2)*o1_vel_freq(j,2);
                end
            end
            obj.frequency_matrix=frequency_matrix_tbn./sum(frequency_matrix_tbn,'all');
        end

        function obj=build_fmatrix_o2(obj)
            obj.dir_vector=obj.o2_dir_freq(:,1);
            obj.vel_vector=obj.o2_vel_freq(:,1);
            frequency_matrix_tbn=zeros(length(obj.o2_dir_freq),length(obj.o2_vel_freq));
            obj.dir_step=obj.o2_dir_freq(2,1)-obj.o2_dir_freq(1,1);
            obj.vel_step=obj.o2_vel_freq(2,1)-obj.o2_vel_freq(1,1);
            for i=1:length(obj.o2_dir_freq)
                for j=1:length(obj.o2_vel_freq)
                    frequency_matrix_tbn(i,j)=obj.o2_dir_freq(i,2)*obj.o2_vel_freq(j,2);
                end
            end
            obj.frequency_matrix=frequency_matrix_tbn./sum(frequency_matrix_tbn,'all');
        end

        function obj=build_fmatrix_o3(obj)
            raw_wind_speeds=obj.o3_table(:,1);
            raw_wind_directions=obj.o3_table(:,2);
            raw_frequencies=obj.o3_table(:,3);
            wind_speeds=sort(unique(obj.o3_table(:,1)));
            obj.vel_vector=wind_speeds;
            wind_directions=sort(unique(obj.o3_table(:,2)));
            obj.dir_vector=wind_directions;
            obj.dir_step=wind_directions(2,1)-wind_directions(1,1);
            obj.vel_step=wind_speeds(2,1)-wind_speeds(1,1);
            [wind_speeds_grid,wind_directions_grid]=meshgrid(wind_speeds,wind_directions);
            frequency_matrix_tbn=griddata(raw_wind_directions,raw_wind_speeds,raw_frequencies,wind_directions_grid,wind_speeds_grid,'nearest');
            obj.frequency_matrix=frequency_matrix_tbn./sum(frequency_matrix_tbn,'all');
        end

        function frequency_matrix_vel=get.frequency_matrix_vel(obj)
            frequency_matrix_vel=sum(obj.frequency_matrix,1);
        end

        function frequency_matrix_dir=get.frequency_matrix_dir(obj)
            frequency_matrix_dir=sum(obj.frequency_matrix,2);
        end

        function plot_ws_distribution(obj)
            histogram('BinEdges',[obj.vel_vector',obj.vel_vector(end)+obj.vel_step],'BinCounts',obj.frequency_matrix_vel*100)
            xlabel('Wind Speed (m/s)')
            ytickformat('percentage')
            title('Annual Distribution Of Wind Speeds')
        end

        function plot_wd_distribution(obj)
            polarhistogram('BinEdges',deg2rad([obj.dir_vector',360]),'BinCounts',obj.frequency_matrix_dir*100);
            pax=gca;
            pax.ThetaDir = 'clockwise';
            pax.ThetaZeroLocation = 'top';
            rtickformat('percentage')
            title('Annual Distribution Of Wind Directions')
        end

        function plot_windrose_distribution(obj)
            bins=[0 3 6 10 15 20 26];
            auxiliary_vector=zeros(1,length(bins));
            for m=1:length(obj.vel_vector)
                auxiliary_vector(m)=sum(obj.vel_vector(m)>=bins);
            end
            frequency_matrix_resized=zeros(length(obj.dir_vector),length(bins));
            for i=1:length(obj.dir_vector)
                for j=1:length(obj.vel_vector)
                k=auxiliary_vector(j);
                frequency_matrix_resized(i,k)=frequency_matrix_resized(i,k)+obj.frequency_matrix(i,j);
                end
            end

            for k=2:length(bins)
                frequency_matrix_resized(:,k)=frequency_matrix_resized(:,k)+frequency_matrix_resized(:,k-1);
            end

            color_cell={'k','m','r','y','g','c','b'};
            for k=1:length(bins)
                polarhistogram('BinEdges',deg2rad([obj.dir_vector',360]),'BinCounts',frequency_matrix_resized(:,length(bins)+1-k)*100,'FaceColor',color_cell{k},'FaceAlpha',1);
                hold on
            end
            pax=gca;
            pax.ThetaDir = 'clockwise';
            pax.ThetaZeroLocation = 'top';
            rtickformat('percentage')
            title('Annual Wind Rose')
            legend_cell=cell(1,length(bins));
            for k=2:length(bins)
                legend_cell{k}=sprintf('%d-%d m/s',bins(end-k+1),bins(end-k+2));
            end
            legend_cell{1}=sprintf('%d+ m/s',bins(end));
            legend(legend_cell)
        end
    end
end