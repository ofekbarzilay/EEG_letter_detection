%% section 1
clc;
close all;
clear all;
% Load the CSV file, skipping the first row
disp('Section 1')


EEG_file =  'EEG29.mat';
CSV_file =  'EEG29_EPOCX_256085_2025.01.09T14.22.08+02.00.csv';

opts1 = detectImportOptions(CSV_file, 'NumHeaderLines', 0);
opts = detectImportOptions(CSV_file, 'NumHeaderLines', 1);
data = readtable(CSV_file, opts);

% Extract the EEG start timestamp from the first row, second column
raw_EEG_start_timestamp = opts1.VariableNames{1, 2}; % Assuming the second column contains the start timestamp

% Remove the "start timestamp:" prefix and convert to numeric
if ischar(raw_EEG_start_timestamp) || isstring(raw_EEG_start_timestamp)
    %EEG_start_time = str2double(erase(raw_EEG_start_timestamp, 'startTimestamp_'));
    EEG_start_time = erase(raw_EEG_start_timestamp, 'startTimestamp_');
else
    error('Unexpected format in EEG start timestamp.');
end
% Split the string into parts using '_'
time_parts = split(EEG_start_time, '_');

% Convert each part to numeric
seconds_part = str2double(time_parts{1});
fractional_part = str2double(['0.', time_parts{2}]);

% Combine the seconds and fractional seconds
EEG_start_time_numeric = seconds_part + fractional_part;

% Convert to datetime
EEG_start_datetime = datetime(EEG_start_time_numeric, 'ConvertFrom', 'posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

% add 2 hours for time zone
EEG_start_datetime = EEG_start_datetime + hours(2);
% Load experiment start timestamp from .mat file
load(EEG_file, 'experiment_start_time', 'word_triggers', 'trials', 'fs', 'words');


% Calculate the duration difference
time_difference = experiment_start_time - EEG_start_datetime ;

% Convert duration to seconds + difference in times between computers
trigger_time_offset = seconds(time_difference);

% Display the offset
disp(['Trigger Time Offset: ', num2str(trigger_time_offset), ' seconds']);

% find the signal length by using P7 electrode
signal = data.('EEG_P7');
signal_length = length(signal);

triggers_signal = zeros( signal_length,1); % Initialize to zeros

% Adjust the word triggers with the time offset
adjusted_triggers = cell(size(word_triggers)); % Initialize adjusted triggers
for word_idx = 1:length(word_triggers)
    % Adjust each trigger time using the offset and convert to sample indices
    adjusted_triggers{word_idx} = round((word_triggers{word_idx} + trigger_time_offset) * fs);
end

% Populate triggers_signal with the corresponding word indices
for word_idx = 1:length(adjusted_triggers)
    for i = 1:length(adjusted_triggers{word_idx})
        trigger_sample = adjusted_triggers{word_idx}(i); % Get the sample index
        if trigger_sample > 0 && trigger_sample <= signal_length
            triggers_signal(trigger_sample) = word_idx; % Assign the word index to the signal
        end
    end
end

% Display the resulting triggers_signal vector length and sample
disp('Triggers signal generated:');
disp(['Length: ', num2str(length(triggers_signal))]);
save('triggers_signal');





% EEGLAB preprocess

% Step 1: Extract relevant columns (columns 5 to 18)
eeg_data = table2array(data(:, 5:18)); % Extract only columns 5 to 18

% Focus only on P7, O1, O2, P8
eeg_data = eeg_data(:, [6, 7, 8, 9]);

% Step 2: Define metadata for EEGLAB
fs = 128; % Sampling rate (adjust as per your data)
EEG = eeg_emptyset(); % Create an empty EEGLAB dataset
EEG.data = eeg_data'; % Transpose to match EEGLAB format (channels × time)
EEG.srate = fs; % Sampling rate
EEG.nbchan = size(EEG.data, 1); % Number of channels (4 in this case)
EEG.pnts = size(EEG.data, 2); % Number of time points
EEG.trials = 1; % Continuous data
EEG.xmin = 0; % Start time (in seconds)
EEG.xmax = (EEG.pnts - 1) / fs; % End time (in seconds)
EEG.setname = 'EEG Unfiltered Data'; % Dataset name


% step 3: names for channels
EEG.chanlocs = struct('labels', {'P7','CP3','CP4','P8'});
channel_names = {'P7','CP3','CP4','P8'};
% Ensure the number of labels matches the number of channels


% Step 4: Save the dataset as a .set file
output_file = 'EEG Data.set';
output_path = pwd; % Current working directory
pop_saveset(EEG, 'filename', output_file, 'filepath', output_path);

% Step 5: Open the .set file in EEGLAB 
disp(['Dataset saved as ', fullfile(output_path, output_file)]);


eeglab;

%% section 2
disp('Section 2')

% Load EEG data into EEGLAB
filtered_signal_filename = 'EEG Data.set';
EEG = pop_loadset('filename', filtered_signal_filename);

% Add the triggers_signal as a new channel
EEG.data(end+1, :) = triggers_signal; % Append triggers_signal as the last channel
EEG.nbchan = size(EEG.data, 1); % Update the number of channels

% Update channel labels
EEG.chanlocs(end+1).labels = 'TriggerSignal'; % Name the new channel

% Save the modified dataset
pop_saveset(EEG, 'filename', 'EEG Data.set', 'filepath', './');


%% Section 3: Remove Noisy Epochs
disp('Section 3')

% Load the EEG data again for modification
EEG = pop_loadset('filename', 'EEG Data.set');

% Initialize a list to keep track of valid epochs
valid_epochs = true(1, EEG.trials); % Assume all epochs are valid initially

% Loop through each epoch
for epoch_idx = 1:EEG.trials
    epoch_data = EEG.data(:, :, epoch_idx); % Extract data for the current epoch (channels x time points)
    
   

    is_noisy = any(abs(epoch_data(:)) > 4 * std(epoch_data(:)));
    % Mark the epoch as invalid if it's noisy
    if is_noisy
        valid_epochs(epoch_idx) = false;
    end
end

% Count and display the number of valid and removed epochs
num_removed_epochs = sum(~valid_epochs);
disp(['Number of removed epochs: ', num2str(num_removed_epochs)]);
disp(['Number of remaining valid epochs: ', num2str(sum(valid_epochs))]);

% Keep only the valid epochs in the EEG data
EEG = pop_select(EEG, 'trial', find(valid_epochs));

% Save the cleaned dataset
pop_saveset(EEG, 'filename', 'EEG Data.set', 'filepath', './');



%% section 4
disp('Section 4')

% Load the updated signal
EEG = pop_loadset('filename', 'EEG Data.set');



% Initialize variables
num_channels = size(EEG.data, 1); % Number of channels
num_events = 4; % Number of event types
avg_signals = zeros(num_channels, size(EEG.data, 2), num_events); % Channels x time points x events
P300_values = zeros(num_channels, num_events); % To store P300 values for each channel and event
chosen_words = cell(num_channels, 1); % To store the chosen word for each channel


% Loop through each event type
for event_type = 1:num_events
    % Find epochs corresponding to this event type
    epochs_for_event = find([EEG.event.type] == event_type);
    
    % Extract data for these epochs (channels x time points x epochs)
    event_epochs = EEG.data(:, :, epochs_for_event);
    
    % Compute the average across epochs for each channel
    avg_signals(:, :, event_type) = mean(event_epochs, 3); % Average over the 3rd dimension
end

% Generate a separate figure for each channel
time = EEG.times; % Time vector in ms

for channel = 1:num_channels
    figure; % Create a new figure for the current channel
    sgtitle(strcat("Average Signals for Channel ", channel_names(channel), " with P300"));
    
    for event_type = 1:num_events
        % Get the average signal for the current channel and event type
        avg_signal = avg_signals(channel, :, event_type);
        
        % Find the P300 value (maximum amplitude in the range 200-600 ms)
        time_idx = find(time >= 200 & time <= 600); 
        [P300_value, max_idx] = max(avg_signal(time_idx)); % Maximum value and its index
        max_time = time(time_idx(max_idx)); % Time of the maximum value
        
        % Store the P300 value
        P300_values(channel, event_type) = P300_value;
        
        % Plot the average signal
        subplot(2, 2, event_type); % Arrange plots in a 2x2 grid
        plot(time, avg_signal, 'b');
        xlim([0, time(end)]);
        hold on;
        
        % Add a dot at the maximum value
        plot(max_time, P300_value, 'ro', 'MarkerSize', 6, 'DisplayName', 'P300');
        
        % Add title and labels
        title(['Event: ' words{event_type}]);
        xlabel('Time (ms)');
        ylabel('Amplitude (µV)');
        legend('show');
        hold off;
    end
    
    % Determine the chosen word for this channel
    [~, chosen_word_idx] = max(P300_values(channel, :));
    chosen_words{channel} = words{chosen_word_idx};
end

% Display the chosen words for each channel
for channel = 1:num_channels
    disp(strcat("Channel ", channel_names(channel), ": Chosen word is ", chosen_words{channel}));
end
