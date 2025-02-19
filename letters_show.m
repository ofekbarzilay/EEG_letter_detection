clc;
close all;
clear all;

% presentation_type = 'images';
presentation_type = 'letters';

% Initialize variables
switch presentation_type
    case 'images'
        words = {'Dog.png', 'Home.png', 'Chair.png', 'Tree.png'}; % Paths to image files
    case 'letters'
        words = {'A', 'W', 'O', 'B'}; % The four words
end

num_trials = 20; % Number of repetitions for each image
stim_duration = 0.3; % Duration to display each image (in seconds)
iti_duration = 1; % Inter-trial interval (fixation cross duration in seconds)
fs = 128; % EEG sampling rate for EMOTIV (adjust if needed)

% Randomize the image order across trials
trials = repmat(1:4, 1, num_trials);
trials = trials(randperm(length(trials)));

% Prepare to record triggers for each image
word_triggers = cell(1, 4); % Store trigger times for each image

% Open a full-screen figure for the experiment
hFig = figure('Color', 'black', 'MenuBar', 'none', 'ToolBar', 'none', ...
              'Units', 'normalized', 'Position', [0 0 1 1]);
hAx = axes('Parent', hFig, 'Position', [0 0 1 1], 'Color', 'black'); % Axes for image placement
hText = text(hAx, 0.5, 0.5, '', 'FontSize', 48, 'Color', 'white', ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');

% Initialize experiment_start_time dynamically

disp('Starting experiment...');
experiment_start_time = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

for i = 1:length(trials)
    % Check if the figure is still open
    if ~isvalid(hFig)
        disp('Figure closed prematurely. Exiting...');
        break;
    end

    img_idx = trials(i); % Get the image index for this trial
    word = words{img_idx}; % Current image to display

   % Show fixation cross
    cla(hAx); % Clear axes
    text(0.5, 0.5, '+', 'FontSize', 72, 'Color', 'white', ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    axis([0 1 0 1]); % Ensure axes are scaled from 0 to 1 for consistent positioning
    drawnow; % Force update of the figure
    pause(iti_duration); % Pause for inter-trial interval

    % Show the image on the screen
    cla(hAx); % Clear axes
    switch presentation_type
        case 'images'
            img = imread(word); % Read the image file
            imshow(img, 'Parent', hAx); % Display the image
        case 'letters'
            text(0.5, 0.5, word, 'FontSize', 72, 'Color', 'white', ...
                 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    end 
    axis(hAx, 'off'); % Turn off axes
    drawnow; % Force update of the figure

    % Record actual display time
    image_display_start = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'); % Time before displaying the image
    delay = seconds(image_display_start - experiment_start_time); % Time relative to experiment start

    % Save the trigger
    word_triggers{img_idx} = [word_triggers{img_idx}, delay]; % Store trigger time for the image
    pause(stim_duration); % Display the image for stim_duration seconds
end

% Close the figure after the experiment
if isvalid(hFig)
    close(hFig);
end

% Save the triggers and experiment start timestamp
version = 4;
filename = sprintf('experiment_triggers_%s.mat', string(datetime('now','Format',"yyyy-MM-dd-HH-mm-ss")));
save(filename, 'word_triggers', 'trials', 'words', 'experiment_start_time', 'fs', 'version');

disp(['Experiment completed. Triggers and start timestamp saved to experiment_triggers.mat.']);
disp(['Experiment started at: ', char(experiment_start_time)]);
