function [leftHandData, rightHandData] = readOpenPoseOutput( directory, showPlots )
    %% Summary
    %   Inputs
    %       - directory - The path to the folder containing the data to use
    %       - showPlots - Optional flag specifying whether to show plots
    %   Outputs
    %       - leftHandData  - A vector of hand data structs
    %       - rightHandData - A vector of hand data structs
    %
    %% Struct Information
    %   Hand Data Struct Fields
    %       - allX    - All x coordinate positions
    %       - allY    - All y coordinate positions
    %       - allC    - All confidence values
    %       - thumb   - Finger struct representing the thumb
    %       - pointer - Finger struct representing the pointer finger
    %       - middle  - Finger struct representing the middle finger
    %       - index   - Finger struct representing the index finger
    %       - pinky   - Finger struct representing the pinky finger
    %
    %   Finger Data Struct Fields
    %       - x - X Coordinate positions for the finger
    %       - y - Y coordinate positions for the finger
    %       - c - Confidence values for the finger
    %
    
    %% Check For Proper Inputs
    switch nargin
        case 0 
            error('Error: No directory input supplied.')
        case 1
            % Show plots by default
            showPlots = 1;
    end

    %% Perform Basic Setup 
    directoryFiles = dir(directory);
    currFrame      = 1;
    
    %% Read Formatted JSON Data
    for fileIndex = 1 : length(directoryFiles)
        currentFile = directoryFiles(fileIndex);
        % Ignores Directories 
        if(~currentFile.isdir)
            filepath = fullfile(directory, currentFile.name);
            [leftHandData(currFrame,:), rightHandData(currFrame,:)] = readHandPositions(filepath);
            currFrame = currFrame + 1;
        end
    end 
    
    %% Plot If Specified
    figure
    axis([0 400 0 400])
    index = 1;
    runThroughs = 0;
    if showPlots
        while 1
            if index < currFrame
                clf;
                plot(leftHandData(index).allX, leftHandData(index).allY, 'b-o')
                hold on
                plot(rightHandData(index).allX, rightHandData(index).allY, 'r-o')
                legend({'Left Hand', 'Right Hand'});
                axis([0 1000 0 500])
                title(sprintf('Frame %d', index));
                pause(0.008);             
            else
                index = 0;
                runThroughs = runThroughs + 1;
                fprintf('Run through %d done!\n', runThroughs);
                if runThroughs == 3
                    break
                end 
            end
            index = index + 1;
        end 
    end 
end

function [leftHandData, rightHandData] = readHandPositions(filepath)
    %% Summary
    %
    %   Helper function for readOpenPoseOutput() function
    %
    %   Inputs
    %      - filepath - The relative path for the file to read data from
    %   Outputs
    %       - leftHandData  - The left hand struct for the file's data
    %       - rightHandData - The right hand struct for the file's data
    %
    %% Perform Basic Setup
    leftHandRegEx = '(?<=("hand_left_keypoints":\[))[^\]]*';
    rightHandRegEx = '(?<=("hand_right_keypoints":\[))[^\]]*';
    rawText = fileread(filepath);
    
    %% Get Hand Data
    % Left Hand
    leftHandRawText = regexp(rawText, leftHandRegEx, 'match');
    leftHandRawData = textscan(leftHandRawText{1}, '%f%f%f', 'Delimiter', ',');
    % Right Hand
    rightHandRawText = regexp(rawText, rightHandRegEx, 'match');
    rightHandRawData = textscan(rightHandRawText{1}, '%f%f%f', 'Delimiter', ',');

    %% Format the Left Hand Data
    % All Data
    leftHandData.allX      = leftHandRawData{1};
    leftHandData.allY      = leftHandRawData{2};
    leftHandData.allC      = leftHandRawData{3};
    % Thumb Formatting
    leftHandData.thumb.x   = leftHandRawData{1}(1:5);
    leftHandData.thumb.y   = leftHandRawData{2}(1:5);
    leftHandData.thumb.c   = leftHandRawData{3}(1:5);
    % Pointer Formatting
    leftHandData.pointer.x = leftHandRawData{1}(6:9);
    leftHandData.pointer.y = leftHandRawData{2}(6:9);
    leftHandData.pointer.c = leftHandRawData{3}(6:9);
    % Middle Formatting
    leftHandData.middle.x  = leftHandRawData{1}(10:13);
    leftHandData.middle.y  = leftHandRawData{2}(10:13);
    leftHandData.middle.c  = leftHandRawData{3}(10:13);
    % Index Formatting
    leftHandData.index.x   = leftHandRawData{1}(14:17);
    leftHandData.index.y   = leftHandRawData{2}(14:17);
    leftHandData.index.c   = leftHandRawData{3}(14:17);
    % Pinky Formatting
    leftHandData.pinky.x   = leftHandRawData{1}(18:21);
    leftHandData.pinky.y   = leftHandRawData{2}(18:21);
    leftHandData.pinky.c   = leftHandRawData{3}(18:21);

    %% Format the Right Hand Data
    % All Data
    rightHandData.allX      = rightHandRawData{1};
    rightHandData.allY      = rightHandRawData{2};
    rightHandData.allC      = rightHandRawData{3};
    % Thumb Formatting
    rightHandData.thumb.x   = rightHandRawData{1}(1:5);
    rightHandData.thumb.y   = rightHandRawData{2}(1:5);
    rightHandData.thumb.c   = rightHandRawData{3}(1:5);
    % Pointer Formatting
    rightHandData.pointer.x = rightHandRawData{1}(6:9);
    rightHandData.pointer.y = rightHandRawData{2}(6:9);
    rightHandData.pointer.c = rightHandRawData{3}(6:9);
    % Middle Formatting
    rightHandData.middle.x  = rightHandRawData{1}(10:13);
    rightHandData.middle.y  = rightHandRawData{2}(10:13);
    rightHandData.middle.c  = rightHandRawData{3}(10:13);
    % Index Formatting
    rightHandData.index.x   = rightHandRawData{1}(14:17);
    rightHandData.index.y   = rightHandRawData{2}(14:17);
    rightHandData.index.c   = rightHandRawData{3}(14:17);
    % Pinky Formatting
    rightHandData.pinky.x   = rightHandRawData{1}(18:21);
    rightHandData.pinky.y   = rightHandRawData{2}(18:21);
    rightHandData.pinky.c   = rightHandRawData{3}(18:21);

end

