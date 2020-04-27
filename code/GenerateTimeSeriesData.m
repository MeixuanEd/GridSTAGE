% Author: Sai Pushpak Nandanoori (uses PST)
% Date created: October 22, 2019
% Updated: April 8, 2020 by Seemita Pal
% updated: April 27, 2020 by Sai Pushpak
%--------------------------------------------------------------------------
% Main code follows from here
clearvars; clear global; close all; % clc;
% PST_path = genpath('Matlab_PST'); % Provide filepath to Matlab PST folders
% addpath(PST_path)
SF_path = genpath('Supporting_files');
addpath(SF_path)
rng(700,'v5uniform') % The seeding can be changed for different batch runs
% =========================================================================
% For the load modulation case (Laurentiu Dan Marinovici - 2017/02/14)
global h_sol TimeStep_of_simulation load_change_parameters n_lhc_samples n_lc_events_per_scenario
global fmeas_con busDeltaAngle busDeltaFreqPU dBusDeltaFreqPU busFreq dbusFreq
global line amount_of_load_change_per_scen loads_undergoing_change_sorted
% -------------------------------------------------------------------------
% For AGC
global agc_ratio agc_zm freq_zm agc_z1 agc_z2 agc_zm1 agc_zm2 agc_z
global agc_time_step agc_control gen_inputs load_changes num_area
% -------------------------------------------------------------------------
global ace1 ace2 S1_agcm S2_agcm area1_buses area2_buses
global basmva simParams
global PMU_locations PMU_samples PMU_samples_f PMU_samples_fdot
global AttackLocation AttackVector
global PMU SCADA n_PMU SCADA_row_location PMU_SCADA_Difference
global SCADA_locations SCADA_samples
global PMU_area1_locations PMU_area2_locations
global ACE_data count count2
global PMU_SamplingFreq attack AttackTypes PMU_attack AT BernoulliProcess NewTimes
% =========================================================================

% User-defined parameters:
SavePlots = 1; % '1' for saving plots; '0' for not saving
% -------------------------------------------------------------------------

% System configurations
Network = '68'; % Choose the IEEE bus system: '9', '39', '68', '145'
agc_control = 1; % '1' enables AGC control; '0' disables AGC control
agc_time_step = 4; % time interval in seconds between agc control
pss_control = 0; % '1' enables PSS control; '0' disables PSS control
num_area = 2; % 1- one area and 2 - two area
load_changes = 1; % '1' enables load changes; '0' disables load changes
TimeStep_of_simulation = 0.01; % in seconds
SimulationTime = 60; % in seconds
PMU_SamplingFreq  = 50; % Measurements every second
% -------------------------------------------------------------------------

% Attack Parameters
PMU_attack = 1; % '1' enables cyber-attacks on PMUs; '0' disables cyber-attacks on PMUs
AttackTypes = {'Latency','PacketDrop','Ramp','Step','Poisoning','Trapezoid'};
AT = AttackTypes{3};
% Cyber-attack is to be introduced in PMU sensors at attack location bus
% AttackTypes{1}: 'Latency' attack (additional delays introduced  in PMU packet latencies)
% AttackTypes{2}: 'PacketDrop' attack (unauthorized  dropping  of  PMU packets)
% AttackTypes{3}: 'Ramp' attack (PMU measurement gradually modified over attack period
% AttackTypes{4}: 'Step' attack (PMU measurement scaled based on scaling factor)
% AttackTypes{5}: 'Poisoning' attack (PMU measurement are randomly corrupted
% AttackTypes{6}: 'Trapezoid' attack (PMU measurement are gradually
% increased, kept on hold and gradually decreased or viceversa
% For Poisoning attack noise parameters are picked from a Gaussian distribution
%%%%% the below attack characteristics get activated only if PMU_attack==1
% Predefine the mean and variance for data poisioning
data_poison.mean = 0.0;
% Rows    - attack location
% Columns - indicate scenario's
data_poison.var  = [0.005;
    0.006;
    0.005;
    0.008];
% Predefined set of attack magnitude percentages to be simulated
% Rows    - attack location
% Columns - indicate scenario's
attack_magnitudes_percent = [0.03 0.1 0.2;
    0.04 0.1 0.2;
    0.05 0.1 0.2;
    0.02 0.1 0.2]; % Attack magnitudes
attack_magnitudes_percent(:,1) = 0.07;
%--------------------------------------------------------------------------

% Multiple scenario generation parameters
% Number of scenarios with cyber-attacks to simulate
n_attack_scenarios = 1;
% Number of fault scenarios (data with respect to each fault location will be saved as a single scenario)
n_fault_scenarios = 1;
% Number of fault-types (data with respect to each fault type will be saved as a single scenario)
n_fault_type = 1;
% Below select number of attack_magnitudes_percent values to be simulated from the set above
n_attacks_on_magnitude = 1; % Should be less than max(size(attack_magnitudes_percent))
% Below select number of attacks on attack duration
% (data corresponding to each attack duration value will be saved as a scenario)
n_attacks_on_duration_of_attack = 2;
% Mention the start time for the attack in seconds or make it a random
% variable
attack.start_time_in_sec = 20; % randi(round(0.8*simParams.simTime),1,1);
% Mention the attack duration for the attack in seconds
attack_durations = linspace(15,25,n_attacks_on_duration_of_attack);
% Number of load change scenarios
n_lc_scenarios = 1; % Number of load changes (== # num of scenarios corresponding to the load changes)
n_lc_events_per_scenario = 2; % Number of load changes in single scenario
% How many loads needs to change their nominal value during the simulation?
% Can be a pre-defined number of loads or can be a random number
n_loads_to_change = 2; % randi(10);
n_lc_scen = 1;
%--------------------------------------------------------------------------
Initialization
%--------------------------------------------------------------------------
for i_lc_scen = 1:n_lc_scen
    % ------- Latin Hyper Cube sampling to generate multiple load vectors -----
    % Determine the buses at which load changes needs to happen
    % Below, the load change buses are picked randomly (user can mention the
    % load bus numbers without making them a random number)
    loads_undergoing_change = randsample(load_locations, n_loads_to_change);
    tmp_lvs = nominal_load_values(loads_undergoing_change);
    loads_undergoing_change_sorted = zeros(n_loads_to_change,1);
    
    for i_l = 1:n_loads_to_change
        loads_undergoing_change_sorted(i_l) = find(load_locations == loads_undergoing_change(i_l));
    end
    
    % load changes -- based on Latin Hyper Cube sampling
    amount_of_load_change = (lhsnorm(tmp_lvs', diag(tmp_lvs*0.08),n_lhc_samples))'...
        - nominal_load_values(loads_undergoing_change);
    %--------------------------------------------------------------------------
    
    for i_load_changes = 1:n_lc_scenarios
        % The below load_change_parameters start_time and end_time properties can be either
        % scalar or vector [depending on how many load changes are needed in one run].
        % %% start_time is chosen randomly
        % load_change_parameters.start_time = diag(sort(randi(SimulationTime-15,n_lc_events),'ascend'));
        % %% start_time is chosen deterministically
        load_change_parameters.start_time = [randi([5,16],1,1) randi([25,40],1,1)];% sort(randi([0, 40],1,n_lc_events),'ascend'); % [15 35]; %
        % %% load changes are permanent: leave the end_time variable as empty
        % %% load changes are temporary: end_time variable is nonempty
        load_change_parameters.end_time   = []; % load_change_parameters.start_time + 0.01;
        
        amount_of_load_change_per_scen = 0.8*amount_of_load_change(:,(i_load_changes-1)*n_lc_events_per_scenario+1:i_load_changes*n_lc_events_per_scenario);
        % load changes -- based on random choice
        % amount_of_load_change = ...
        % 1*rand(num_loads_to_change,1).*randn(num_loads_to_change,1);
        
        for i_fault_location = n_fault_scenarios:n_fault_scenarios
            for i_fault_type = 1:n_fault_type
                
                %{
            row 1 col1  simulation start time (s) (cols 2 to 6 zeros)
                  col7  initial time step (s)
            row 2 col1  fault application time (s)
                  col2  bus number at which fault is applied
                  col3  bus number defining far end of faulted line
                  col4  zero sequence impedance in pu on system base
                  col5  negative sequence impedance in pu on system base
                  col6  type of fault  - 0 three phase
                                       - 1 line to ground
                                       - 2 line-to-line to ground
                                       - 3 line-to-line
                                       - 4 loss of line with no fault
                                       - 5 loss of load at bus
                                       - 6 no action
                  col7  time step for fault period (s)
            row 3 col1  near end fault clearing time (s) (cols 2 to 6 zeros)
                  col7  time step for second part of fault (s)
            row 4 col1  far end fault clearing time (s) (cols 2 to 6 zeros)
                  col7  time step for fault cleared simulation (s)
            row 5 col1  time to change step length (s)
                  col7  time step (s)
                %}
                
                sw_con = [...
                    0.0    0    0    0    0    0      0.005; %sets intitial time step
                    0.05  line(i_fault_location,1)   line(i_fault_location,2)   0    0   6       0.005; %apply three phase fault at bus 1, on line 1-2
                    0.1 0    0    0    0    0      0.005; %clear fault at bus
                    0.2 0    0    0    0    0      0.005; %clear remote end
                    0.5 0    0    0    0    0      0.005; % increase time step
                    %             1.0  0    0    0    0    0    0.005; % increase time step
                    SimulationTime  0    0    0    0    0    0]; % end simulation
                
                % Changing the time-step of simulation to user-defined value
                sw_con(:,end) = TimeStep_of_simulation;
                FaultCases = {'three phase fault', 'line to ground fault',...
                    'line-to-line to ground fault','line-to-line fault',...
                    'loss of line with no fault', 'loss of load at bus','no fault'};
                FaultType = FaultCases(sw_con(2,6)+1);
                fprintf('[INFO] Fault: %s\n',upper(FaultType{1}))
                
                % Saving the Scenario description.txt file based on the user inputs:
                Bus1      = sw_con(2,2);
                Bus2      = sw_con(2,3);
                
                %--------------------------------------------------------------------------
                
                % Running over the list of attack locations
                % Attack properties are varied to generate multiple scenarios)
                scenIdx_local = 0;
                
                for i_attack_location = 1:n_attack_scenarios
                    % Mention the attack buses
                    % This can be random buses or user can define these!
                    AttackLocation = [66 32 52 37]; % [4 38 47 57]; % randperm(length(PMU_locations),i_attack_location);
                    for i_attack_duration = 1:n_attacks_on_duration_of_attack
                        % Calculate end time of attack in seconds
                        attack.duration_in_sec = attack_durations(i_attack_duration);
                        attack.end_time_in_sec = attack.start_time_in_sec + attack.duration_in_sec;
                        
                        for i_attack_magnitude = 1:n_attacks_on_magnitude
                            attack.max_mod_frac = 1 + (attack_magnitudes_percent(:,i_attack_magnitude)/100);
                            tic
                            if num_area == 1
                                % ACE_data.ACE = [];
                                ACE_data.k = []; ACE_data.myACE = [];
                            elseif num_area == 2
                                % ACE_data.ACE1 = []; ACE_data.ACE2 = [];
                                ACE_data.myACE1 = []; ACE_data.myACE2 = [];  ACE_data.k = [];
                            end
                            scenIdx_local = scenIdx_local+1;
                            %----------------------------------------------------------
                            attack_description
                            %----------------------------------------------------------
                            scenario_description
                            %----------------------------------------------------------
                            if PMU_attack
                                fprintf('[INFO] Attack locations: Buses %d \n', AttackLocation)
                                if strcmp(AT,'Ramp') || strcmp(AT,'Step')
                                    fprintf('[INFO] Attack magnitudes in percentages: %0.2f%% \n',attack_magnitudes_percent(:,i_attack_magnitude))
                                elseif strcmp(AT,'Poisoning')
                                    fprintf('[INFO] Variance of attack: %0.4f%% \n', data_poison.var)
                                    fprintf('[INFO] Mean of attack: %0.4f%% \n', data_poison.mean)
                                end
                            end
                            %----------------------------------------------------------
                            s_simu_PD % Main code running power flow and time-domain simulations
                            %----------------------------------------------------------
                            data_processing_and_plotting
                            %----------------------------------------------------------
                            % Save the plots and data
                            if SavePlots
                                %{
                            FigureFile = sprintf('%s/PMU_Vm',scenDir);
                            saveas(voltage_magnitude_plot,FigureFile,'jpg')
                            FigureFile = sprintf('%s/Metrics',scenDir);
                            saveas(impact_plot,FigureFile,'jpg')
                            FigureFile = sprintf('%s/Real_powers',scenDir);
                            saveas(real_power_plot,FigureFile,'jpg')
                                %}
                                FigureFile = sprintf('%s/PMU_V',scenDir);
                                saveas(voltage_plot,FigureFile,'jpg')
                                
                                FigureFile = sprintf('%s/PMU_F',scenDir);
                                saveas(frequency_plot,FigureFile,'jpg')
                                if agc_control
                                    FigureFile = sprintf('%s/ACE',scenDir);
                                    saveas(ace_plot,FigureFile,'jpg')
                                end
                                % close all
                            end
                            save(sprintf('%s/PMUData.mat',scenDir), 'PMU','PMU_SamplingFreq','SimulationTime', 'fmeas_con', 'TimeStep_of_simulation', 'AttackLocation', 't', 'PMU_samples', 'pelect');
                            save(sprintf('%s/SCADAData.mat',scenDir), 'SCADA','Required_NumofMeasEvery2Seconds_SCADA','SimulationTime','Vmeas_con');
                            if compute_metrics
                                save(sprintf('%s/MetricData.mat',scenDir), 'PMU_SCADA_Difference', 'PMU_SCADA_difference_norm');
                            end
                            if agc_control, save(sprintf('%s/ACEData.mat',scenDir), 'ACE_data', 'tg_sig', 'agc_zm'); end
                            et = toc;
                            ets = num2str(et);
                            disp(['elapsed time = ' ets 's'])
                            fprintf('------------------------*---------------------------\n')
                        end
                    end
                end
            end
        end
    end
end
% Convert to table format and write the table to a CSV file
scenDes_full_table = cell2table(scenDes_full);
writetable(scenDes_full_table,sprintf('%s/FullScenarioData.csv',ResDir),'WriteVariableNames',0)
fprintf('\n All the data is saved and the simulation is complete now.\n')
%--------------------------------------------------------------------------