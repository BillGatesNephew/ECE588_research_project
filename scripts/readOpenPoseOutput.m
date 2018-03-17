function [leftHandData, rightHandData] = readOpenPoseOutput( directory, showPlots, plotNum )
    %% Inputs:
    %   directory: File directory of openpose output data
    %% Outputs:
    %   leftHandData:  [21 x 3 x frames] matrix containing X,Y Hand Positions as well as confidence level for each frame
    %   rightHandData: [21 x 3 x frames] matrix containing X,Y Hand Positions as well as confidence level for each frame

    %% HandData Information
    %   Thumb:   datapoints 1:5
    %   Pointer: datapoints 6:9
    %   Middle:  datapoints 10:13
    %   Ring:    datapoints 14:17
    %   Pinky:   datapoints 18:21

    %% Check For Proper Inputs
        switch nargin
            case 0 
                error('Error: No directory input supplied.')
            case 1
                % Show plots by default
                showPlots = 1;
            case 2 
                % Show first 3 plots by default
                plotNum = 3;

        end

    %% Perform Basic Setup 
    directoryFiles = dir(directory);
    numFiles       = length(directoryFiles - 2); 
    currFrame      = 1;

    %% Read Formatted JSON Data
    for fileIndex = 1 : length(directoryFiles)
        currentFile = directoryFiles(fileIndex);
        % Ignores Directories 
        if(~currentFile.isdir)
            filepath = fullfile(directory, currentFile.name);
            [ 
                leftHandData[ currFrame ], 
                rightHandData[ currFrame ] 
            ] = readHandPositions(filepath);
            currFrame = currFrame + 1;
        end
    end 

    %% Plot if Needed
    if showPlots
        for index = 1 : plotNum
            if index <= currFrame
                plot(leftHandData[index].allX, leftHandData[index].allY, '-o')
                plot(rightHandData[index].allX, rightHandData[index].allY, '-o')
            end 
        end 
    end 
    % plot(leftHandX(1:5), leftHandY(1:5), '-o')
    % hold on
    % plot(leftHandX([1,6:9]), leftHandY([1,6:9]), '-o')
    % plot(leftHandX([1,10:13]), leftHandY([1,10:13]), '-o')
    % plot(leftHandX([1,14:17]), leftHandY([1,14:17]), '-o')
    % plot(leftHandX([1,18:21]), leftHandY([1,18:21]), '-o')
    %
    % plot(rightHandX(1:5), rightHandY(1:5), '-o')
    % plot(rightHandX([1,6:9]), rightHandY([1,6:9]), '-o')
    % plot(rightHandX([1,10:13]), rightHandY([1,10:13]), '-o')
    % plot(rightHandX([1,14:17]), rightHandY([1,14:17]), '-o')
    % plot(rightHandX([1,18:21]), rightHandY([1,18:21]), '-o')
    % legend({'LThumb', 'LPointer', 'LMiddle', 'LRing', 'LPinky', 'RThumb', 'RPointer', 'RMiddle', 'RRing', 'RPinky'})
end

function [leftHandData, rightHandData] = readHandPositions(filepath)
    %% Perform Basic Setup
    leftHandRegEx = '(?<="hand_left_keypoints":\[\n).*(\n\])';
    rightHandRegEx = '(?<="hand_right_keypoints":\[\n).*(\n\])';
    rawText = fileread(filepath);

    %% Get Hand Data
    % Left Hand
    leftHandRawText = regexp(rawText, leftHandRegEx, 'match');
    leftHandRawData = textscan(leftHandRawText, '%f%f%f', 'Delimiter', ',');
    % Right Hand
    rightHandRawText = regexp(rawText, rightHandRegEx, 'match');
    rightHandRawData = textscan(rightHandRawText, '%f%f%f', 'Delimiter', ',');

    %% Format the Left Hand Data
    % All Data
    leftHandData.allX      = leftHandRawData{1};
    leftHandData.allY      = leftHandRawData{2};
    leftHandData.allC      = leftHandRawData{3};
    % Thumb Formatting
    leftHandData.thumb.x   = leftHandRawData{1}[1:5];
    leftHandData.thumb.y   = leftHandRawData{2}[1:5];
    leftHandData.thumb.c   = leftHandRawData{3}[1:5];
    % Pointer Formatting
    leftHandData.pointer.x = leftHandRawData{1}[6:9];
    leftHandData.pointer.y = leftHandRawData{2}[6:9];
    leftHandData.pointer.c = leftHandRawData{3}[6:9];
    % Middle Formatting
    leftHandData.middle.x  = leftHandRawData{1}[10:13];
    leftHandData.middle.y  = leftHandRawData{2}[10:13];
    leftHandData.middle.c  = leftHandRawData{3}[10:13];
    % Index Formatting
    leftHandData.index.x   = leftHandRawData{1}[14:17];
    leftHandData.index.y   = leftHandRawData{2}[14:17];
    leftHandData.index.c   = leftHandRawData{3}[14:17];
    % Pinky Formatting
    leftHandData.pinky.x   = leftHandRawData{1}[18:21];
    leftHandData.pinky.y   = leftHandRawData{2}[18:21];
    leftHandData.pinky.c   = leftHandRawData{3}[18:21];

    %% Format the Right Hand Data
    % All Data
    rightHandData.allX      = rightHandRawData{1};
    rightHandData.allY      = rightHandRawData{2};
    rightHandData.allC      = rightHandRawData{3};
    % Thumb Formatting
    rightHandData.thumb.x   = rightHandRawData{1}[1:5];
    rightHandData.thumb.y   = rightHandRawData{2}[1:5];
    rightHandData.thumb.c   = rightHandRawData{3}[1:5];
    % Pointer Formatting
    rightHandData.pointer.x = rightHandRawData{1}[6:9];
    rightHandData.pointer.y = rightHandRawData{2}[6:9];
    rightHandData.pointer.c = rightHandRawData{3}[6:9];
    % Middle Formatting
    rightHandData.middle.x  = rightHandRawData{1}[10:13];
    rightHandData.middle.y  = rightHandRawData{2}[10:13];
    rightHandData.middle.c  = rightHandRawData{3}[10:13];
    % Index Formatting
    rightHandData.index.x   = rightHandRawData{1}[14:17];
    rightHandData.index.y   = rightHandRawData{2}[14:17];
    rightHandData.index.c   = rightHandRawData{3}[14:17];
    % Pinky Formatting
    rightHandData.pinky.x   = rightHandRawData{1}[18:21];
    rightHandData.pinky.y   = rightHandRawData{2}[18:21];
    rightHandData.pinky.c   = rightHandRawData{3}[18:21];

end

