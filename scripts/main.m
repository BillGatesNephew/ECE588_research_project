function [] = runDetection(inputVideo, outputVideo)
    % A centralized function for running the combined processes needed for project

    %% Constants 
    openPoseFolder    = 'C:\Users\qgaumer\Documents\MATLAB\typing_test\';
    keyLocationFolder = '.\data\key_locations\';
    pythonCmdPrefix   = 'python3 keyDetection.py ';

    %% Check Input Args
    if nargin < 1
        error('Error: No input video provided.')
    end 
    
    %% Run Python Key Location Script
    pythonCommand = strcat(pythonCmdPrefix, inputVideo);
    [status, results] = system(pythonCommand);
    if status ~= 0
        error('Could not run python script for key locations.')
    end 

    %% Create Keyboard Object 
    resultObject = keyboard2(inputVideo, openPoseFolder, keyLocationFolder);

    %% Run any subsequent routines with the result of keyboard2() below

    
end 




