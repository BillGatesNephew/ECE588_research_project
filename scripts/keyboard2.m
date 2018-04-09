classdef keyboard2 < handle
    properties
        keyArray;
        keyAreaArray;
        totalKeys;
        videoLocation;
        leftHandData;
        rightHandData;
        openPoseResolution;
        totalFrames; %Still need to figure this out
        fingersInsideKey;
        videoFrames;
        F;
        ax1;
        ax2;
        keyPressData
    end
    methods
        function obj = keyboard2(VideoLocation, OpenPoseFolder, KeyAreaFileLocation)
            obj.keyArray = {};
            obj.keyAreaArray = [];
            obj.totalKeys = 0;
            if(nargin>=1)
                obj.videoLocation = VideoLocation;
            else
                %Call File Open to Video
            end
            if(nargin>=2)
                [obj.leftHandData, obj.rightHandData] = readOpenPoseOutput(OpenPoseFolder, false);
                
            else
                %Call File Open to find directory
            end
            
            
            
            %Convert obj.leftHandData and obj.rightHandData back to original video resolution
            
            obj.totalFrames = length(obj.leftHandData);
            
            %             obj.SetAppleKeyboard();
            obj.FingerDerivative();
            obj.UnidirectionalCumulativeDerivative();
            % %              obj.KeyPositionReader(KeyAreaFileLocation);
            obj.KeyPositionFrameReader(KeyAreaFileLocation);
            obj.totalKeys = length(obj.keyArray);
            obj.DetermineAllKeyHover();
            %              obj.keyArray = {};
        end
        function[crossOverFrame] = DetectKeyPress(obj)
            
            threshold  = 15;
            
            for i = 1:obj.totalFrames-1  %all the cumulative derivative plot values)
                cumulativeMovement(1, i) = obj.leftHandData(i).thumbCumulativeMovement.x(end);
                cumulativeMovement(2, i) = obj.leftHandData(i).pointerCumulativeMovement.x(end);
                cumulativeMovement(3, i) = obj.leftHandData(i).middleCumulativeMovement.x(end);
                cumulativeMovement(4, i) = obj.leftHandData(i).indexCumulativeMovement.x(end);
                cumulativeMovement(5, i) = obj.leftHandData(i).pinkyCumulativeMovement.x(end);
                
                cumulativeMovement(6, i) = obj.rightHandData(i).thumbCumulativeMovement.x(end);
                cumulativeMovement(7, i) = obj.rightHandData(i).pointerCumulativeMovement.x(end);
                cumulativeMovement(8, i) = obj.rightHandData(i).middleCumulativeMovement.x(end);
                cumulativeMovement(9, i) = obj.rightHandData(i).indexCumulativeMovement.x(end);
                cumulativeMovement(10, i) = obj.rightHandData(i).pinkyCumulativeMovement.x(end);
            end
            movementDirection = sign(cumulativeMovement);
            movementDirectionShifted = circshift(movementDirection,1,2);
            
            figure
            hold on
            CurrKeyPresses = 0;
            for i = 1 : 10
                %for each finger determine spots it moved
                movementChangeLocations = find(movementDirection(i,:) ~= movementDirectionShifted(i,:));
                magnitudeChange = cumulativeMovement(i, movementChangeLocations(2:end)-1);
                for j = 1 : length(movementChangeLocations) - 1
                    if(abs(magnitudeChange(j))> threshold)
                        %find next opposite sign
                        for k = j + 1 : min( [ j + 5, length(movementChangeLocations)-1])
                            if(abs(magnitudeChange(k)) > threshold && sign(magnitudeChange(j)) == sign(magnitudeChange(k)))
                                break;
                            end
                            if(abs(magnitudeChange(k)) > threshold && sign(magnitudeChange(j)) ~= sign(magnitudeChange(k)))
                                %Detected KeyPress at frame for this finger
                                CurrKeyPresses = CurrKeyPresses + 1;
                                obj.keyPressData(CurrKeyPresses,:) = [movementChangeLocations(j) i];
                                fprintf('Finger %d: Start: %d End: %d\n', i, movementChangeLocations(j), movementChangeLocations(k));
                                j = k;
                                break;
                            end
                        end
                    end
                    temp = 0;
                end
                temp = 0;
            end
            obj.keyPressData = sortrows(obj.keyPressData);
            
        end
     
        function PlotKeys(obj)
            Vertices = zeros(8,3);
            figure
            
            for currFrame = 1 : obj.totalFrames
                clf('reset')
                if(currFrame == 200);
                    temp = 0;
                end
                for currKey = 1 : obj.totalKeys
                    Vertices(1:4,1:2) = obj.keyAreaArray(:,:,currKey);
                    Vertices(5:8,1:2) = obj.keyAreaArray(:,:,currKey);
                    Vertices(1:4,3) = 0;
                    
                    Vertices(5:8,3) =  sum(squeeze(obj.fingersInsideKey(:,currKey, currFrame)));
                    Faces = [1 2 3 4; 1 4 8 5; 4 3 7 8; 2 3 7 6; 1 2 6 5; 5 6 7 8]; % 3 4 7 8; 2 4 6 8; 1 2 5 6; 5 6 7 8
                    if(sum(squeeze(obj.fingersInsideKey(:,currKey, currFrame))))
                        patch('Vertices', Vertices, 'Faces', Faces, 'FaceColor', 'r');
                    else
                        patch('Vertices', Vertices, 'Faces', Faces, 'FaceColor', 'g');
                    end
                    hold on
                    
                end
                temp = 0;
                pause(0.1)
                currFrame
                %                 F(currFrame) = getframe(gcf);
            end
            %             obj.outputFrames = F;
        end
        function DetermineAllKeyHover(obj)
            %Check Hand Data for each finger
            for j = 1 : obj.totalFrames
                for currKeyNumber = 1 : obj.totalKeys
                    
                    currKeyX = squeeze(obj.keyAreaArray(:,2,currKeyNumber,j));
                    currKeyY = squeeze(obj.keyAreaArray(:,1,currKeyNumber,j));
                    currKeyX(end+1) = currKeyX(1);
                    currKeyY(end+1) = currKeyY(1);
                    obj.fingersInsideKey(1,currKeyNumber,j) = inpolygon(obj.leftHandData(j).thumb.x(end), obj.leftHandData(j).thumb.y(end),currKeyX, currKeyY);
                    
                    obj.fingersInsideKey(2,currKeyNumber,j) = inpolygon(obj.leftHandData(j).pointer.x(end), obj.leftHandData(j).pointer.y(end),currKeyX, currKeyY);
                    obj.fingersInsideKey(3,currKeyNumber,j) = inpolygon(obj.leftHandData(j).middle.x(end), obj.leftHandData(j).middle.y(end),currKeyX, currKeyY);
                    obj.fingersInsideKey(4,currKeyNumber,j) = inpolygon(obj.leftHandData(j).index.x(end), obj.leftHandData(j).index.y(end),currKeyX, currKeyY);
                    obj.fingersInsideKey(5,currKeyNumber,j) = inpolygon(obj.leftHandData(j).pinky.x(end), obj.leftHandData(j).pinky.y(end),currKeyX, currKeyY);
                    obj.fingersInsideKey(6,currKeyNumber,j) = inpolygon(obj.rightHandData(j).thumb.x(end), obj.rightHandData(j).thumb.y(end),currKeyX, currKeyY);
                    obj.fingersInsideKey(7,currKeyNumber,j) = inpolygon(obj.rightHandData(j).pointer.x(end), obj.rightHandData(j).pointer.y(end),currKeyX, currKeyY);
                    obj.fingersInsideKey(8,currKeyNumber,j) = inpolygon(obj.rightHandData(j).middle.x(end), obj.rightHandData(j).middle.y(end),currKeyX, currKeyY);
                    obj.fingersInsideKey(9,currKeyNumber,j) = inpolygon(obj.rightHandData(j).index.x(end), obj.rightHandData(j).index.y(end),currKeyX, currKeyY);
                    obj.fingersInsideKey(10,currKeyNumber,j) = inpolygon(obj.rightHandData(j).pinky.x(end), obj.rightHandData(j).pinky.y(end),currKeyX, currKeyY);
                end
            end
            for j = 1 : obj.totalFrames
                if(sum(obj.fingersInsideKey(1,:,j))==0)
                    %find closest key
                    currKeyData = squeeze(obj.keyAreaArray(:,:,:,j));
                    fingerPlace = repmat([ obj.leftHandData(j).thumb.y(end) obj.leftHandData(j).thumb.x(end)],[4,1,obj.totalKeys]);
                    manhattanDistance = currKeyData - fingerPlace;
                    distance = manhattanDistance.^2;
                    totalDistance = squeeze(sqrt(sum(distance(:,:,:),2)));
                    closestTotalDistance = min(totalDistance);
                    closestKey = find(min(closestTotalDistance)==closestTotalDistance,1);
                    if(min(closestTotalDistance) < 25 )
                        obj.fingersInsideKey(1,closestKey,j) = -1;
                    end
                end
                if(sum(obj.fingersInsideKey(2,:,j))==0)
                    currKeyData = squeeze(obj.keyAreaArray(:,:,:,j));
                    fingerPlace = repmat([ obj.leftHandData(j).pointer.y(end) obj.leftHandData(j).pointer.x(end)],[4,1,obj.totalKeys]);
                    manhattanDistance = currKeyData - fingerPlace;
                    distance = manhattanDistance.^2;
                    totalDistance = squeeze(sqrt(sum(distance(:,:,:),2)));
                    closestTotalDistance = min(totalDistance);
                    closestKey = find(min(closestTotalDistance)==closestTotalDistance,1);
                    if(min(closestTotalDistance) < 25 )
                        obj.fingersInsideKey(2,closestKey,j) = -1;
                    end
                end
                if(sum(obj.fingersInsideKey(3,:,j))==0)
                    currKeyData = squeeze(obj.keyAreaArray(:,:,:,j));
                    fingerPlace = repmat([ obj.leftHandData(j).middle.y(end) obj.leftHandData(j).middle.x(end)],[4,1,obj.totalKeys]);
                    manhattanDistance = currKeyData - fingerPlace;
                    distance = manhattanDistance.^2;
                    totalDistance = squeeze(sqrt(sum(distance(:,:,:),2)));
                    closestTotalDistance = min(totalDistance);
                    closestKey = find(min(closestTotalDistance)==closestTotalDistance,1);
                    if(min(closestTotalDistance) < 25 )
                        obj.fingersInsideKey(3,closestKey,j) = -1;
                    end
                end
                if(sum(obj.fingersInsideKey(4,:,j))==0)
                    currKeyData = squeeze(obj.keyAreaArray(:,:,:,j));
                    fingerPlace = repmat([ obj.leftHandData(j).index.y(end) obj.leftHandData(j).index.x(end)],[4,1,obj.totalKeys]);
                    manhattanDistance = currKeyData - fingerPlace;
                    distance = manhattanDistance.^2;
                    totalDistance = squeeze(sqrt(sum(distance(:,:,:),2)));
                    closestTotalDistance = min(totalDistance);
                    closestKey = find(min(closestTotalDistance)==closestTotalDistance,1);
                    if(min(closestTotalDistance) < 25 )
                        obj.fingersInsideKey(4,closestKey,j) = -1;
                    end
                end
                if(sum(obj.fingersInsideKey(5,:,j))==0)
                    currKeyData = squeeze(obj.keyAreaArray(:,:,:,j));
                    fingerPlace = repmat([ obj.leftHandData(j).pinky.y(end) obj.leftHandData(j).pinky.x(end)],[4,1,obj.totalKeys]);
                    manhattanDistance = currKeyData - fingerPlace;
                    distance = manhattanDistance.^2;
                    totalDistance = squeeze(sqrt(sum(distance(:,:,:),2)));
                    closestTotalDistance = min(totalDistance);
                    closestKey = find(min(closestTotalDistance)==closestTotalDistance,1);
                    if(min(closestTotalDistance) < 25 )
                        obj.fingersInsideKey(5,closestKey,j) = -1;
                    end
                end
                if(sum(obj.fingersInsideKey(6,:,j))==0)
                    currKeyData = squeeze(obj.keyAreaArray(:,:,:,j));
                    fingerPlace = repmat([ obj.rightHandData(j).thumb.y(end) obj.rightHandData(j).thumb.x(end)],[4,1,obj.totalKeys]);
                    manhattanDistance = currKeyData - fingerPlace;
                    distance = manhattanDistance.^2;
                    totalDistance = squeeze(sqrt(sum(distance(:,:,:),2)));
                    closestTotalDistance = min(totalDistance);
                    closestKey = find(min(closestTotalDistance)==closestTotalDistance,1);
                    if(min(closestTotalDistance) < 25 )
                        obj.fingersInsideKey(6,closestKey,j) = -1;
                    end
                end
                if(sum(obj.fingersInsideKey(7,:,j))==0)
                    
                    currKeyData = squeeze(obj.keyAreaArray(:,:,:,j));
                    fingerPlace = repmat([ obj.rightHandData(j).pointer.y(end) obj.rightHandData(j).pointer.x(end)],[4,1,obj.totalKeys]);
                    manhattanDistance = currKeyData - fingerPlace;
                    distance = manhattanDistance.^2;
                    totalDistance = squeeze(sqrt(sum(distance(:,:,:),2)));
                    closestTotalDistance = min(totalDistance);
                    closestKey = find(min(closestTotalDistance)==closestTotalDistance,1);
                    if(min(closestTotalDistance) < 25 )
                        obj.fingersInsideKey(7,closestKey,j) = -1;
                    end
                end
                if(sum(obj.fingersInsideKey(8,:,j))==0)
                    
                    currKeyData = squeeze(obj.keyAreaArray(:,:,:,j));
                    fingerPlace = repmat([ obj.rightHandData(j).middle.y(end) obj.rightHandData(j).middle.x(end)],[4,1,obj.totalKeys]);
                    manhattanDistance = currKeyData - fingerPlace;
                    distance = manhattanDistance.^2;
                    totalDistance = squeeze(sqrt(sum(distance(:,:,:),2)));
                    closestTotalDistance = min(totalDistance);
                    closestKey = find(min(closestTotalDistance)==closestTotalDistance,1);
                    if(min(closestTotalDistance) < 25 )
                        obj.fingersInsideKey(8,closestKey,j) = -1;
                    end
                end
                if(sum(obj.fingersInsideKey(9,:,j))==0)
                    
                    currKeyData = squeeze(obj.keyAreaArray(:,:,:,j));
                    fingerPlace = repmat([ obj.rightHandData(j).index.y(end) obj.rightHandData(j).index.x(end)],[4,1,obj.totalKeys]);
                    manhattanDistance = currKeyData - fingerPlace;
                    distance = manhattanDistance.^2;
                    totalDistance = squeeze(sqrt(sum(distance(:,:,:),2)));
                    closestTotalDistance = min(totalDistance);
                    closestKey = find(min(closestTotalDistance)==closestTotalDistance,1);
                    if(min(closestTotalDistance) < 25 )
                        obj.fingersInsideKey(9,closestKey,j) = -1;
                    end
                end
                if(sum(obj.fingersInsideKey(10,:,j))==0)
                    
                    currKeyData = squeeze(obj.keyAreaArray(:,:,:,j));
                    fingerPlace = repmat([ obj.rightHandData(j).pinky.y(end) obj.rightHandData(j).pinky.x(end)],[4,1,obj.totalKeys]);
                    manhattanDistance = currKeyData - fingerPlace;
                    distance = manhattanDistance.^2;
                    totalDistance = squeeze(sqrt(sum(distance(:,:,:),2)));
                    closestTotalDistance = min(totalDistance);
                    closestKey = find(min(closestTotalDistance)==closestTotalDistance,1);
                    if(min(closestTotalDistance) < 25 )
                        obj.fingersInsideKey(10,closestKey,j) = -1;
                    end
                end
                
            end
            
        end
        function PlotFingerDerivative(obj)
            figure
            hold on
            for i = 1  : obj.totalFrames - 1
%                 plot(i, obj.leftHandData(i).thumbMovement.x(1), 'm*');
%                 plot(i, obj.leftHandData(i).thumbMovement.y(1), 'mo');
%                 
%                 plot(i, obj.rightHandData(i).thumbMovement.x(1), 'y*');
%                 plot(i, obj.rightHandData(i).thumbMovement.y(1), 'yo');
                
                %                 plot(i, obj.leftHandData(i).thumbMovement.x(end), 'r*');
                %                 plot(i, obj.leftHandData(i).thumbMovement.y(end), 'ro');
                %
%                 if(abs(obj.leftHandData(i).pointerMovement.x(1)) > 5)
%                     plot(i, obj.leftHandData(i).pointerMovement.x(end), 'g*');
%                     plot(i, obj.leftHandData(i).pointerMovement.y(end), 'go');
%                 end
                plot(i, obj.leftHandData(i).pointerCumulativeMovement.x(end), 'r*')
%                 plot(i, obj.leftHandData(i).thumbCumulativeMovement.x(end), 'c*');
                %                 plot(i, obj.leftHandData(i).pointerMovement.x(end), 'g*');
                %                 plot(i, obj.leftHandData(i).pointerMovement.y(end), 'go');
                %
                %                 plot(i, obj.leftHandData(i).middleMovement.x(end), 'k*');
                %                 plot(i, obj.leftHandData(i).middleMovement.y(end), 'ko');
                %
                %
                %                 plot(i, obj.leftHandData(i).indexMovement.x(end), 'b*');
                %                 plot(i, obj.leftHandData(i).indexMovement.y(end), 'bo');
                %
                %
                %                 plot(i, obj.leftHandData(i).pinkyMovement.x(end), 'c*');
                %                 plot(i, obj.leftHandData(i).pinkyMovement.y(end), 'co');
                
            end
        end
        function UnidirectionalCumulativeDerivative(obj)
            
                obj.leftHandData(1).pointerCumulativeMovement.x = obj.leftHandData(1).pointerMovement.x;
                
                for i = 2 : obj.totalFrames - 1
                    
                    movementDirection = sign(obj.leftHandData(i-1).pointerMovement.x);
                    
                    movementDirection2 = sign(obj.leftHandData(i).pointerMovement.x);
                    
                    for j = 1 : length(movementDirection)
                        
                        if(movementDirection(j) == movementDirection2(j))
                            
                            obj.leftHandData(i).pointerCumulativeMovement.x(j) = obj.leftHandData(i-1).pointerCumulativeMovement.x(j) + obj.leftHandData(i).pointerMovement.x(j);
                            
                        else
                            
                            obj.leftHandData(i).pointerCumulativeMovement.x(j) = obj.leftHandData(i).pointerMovement.x(j);
                            
                        end
                        
                    end
                    
                end
                
                
                
                obj.leftHandData(1).middleCumulativeMovement.x = obj.leftHandData(1).middleMovement.x;
                
                for i = 2 : obj.totalFrames - 1
                    
                    movementDirection = sign(obj.leftHandData(i-1).middleMovement.x);
                    
                    movementDirection2 = sign(obj.leftHandData(i).middleMovement.x);
                    
                    for j = 1 : length(movementDirection)
                        
                        if(movementDirection(j) == movementDirection2(j))
                            
                            obj.leftHandData(i).middleCumulativeMovement.x(j) = obj.leftHandData(i-1).middleCumulativeMovement.x(j) + obj.leftHandData(i).middleMovement.x(j);
                            
                        else
                            
                            obj.leftHandData(i).middleCumulativeMovement.x(j) = obj.leftHandData(i).middleMovement.x(j);
                            
                        end
                        
                    end
                    
                end
                
                
                
                obj.leftHandData(1).indexCumulativeMovement.x = obj.leftHandData(1).indexMovement.x;
                
                for i = 2 : obj.totalFrames - 1
                    
                    movementDirection = sign(obj.leftHandData(i-1).indexMovement.x);
                    
                    movementDirection2 = sign(obj.leftHandData(i).indexMovement.x);
                    
                    for j = 1 : length(movementDirection)
                        
                        if(movementDirection(j) == movementDirection2(j))
                            
                            obj.leftHandData(i).indexCumulativeMovement.x(j) = obj.leftHandData(i-1).indexCumulativeMovement.x(j) + obj.leftHandData(i).indexMovement.x(j);
                            
                        else
                            
                            obj.leftHandData(i).indexCumulativeMovement.x(j) = obj.leftHandData(i).indexMovement.x(j);
                            
                        end
                        
                    end
                    
                end
                
                
                
                obj.leftHandData(1).pinkyCumulativeMovement.x = obj.leftHandData(1).pinkyMovement.x;
                
                for i = 2 : obj.totalFrames - 1
                    
                    movementDirection = sign(obj.leftHandData(i-1).pinkyMovement.x);
                    
                    movementDirection2 = sign(obj.leftHandData(i).pinkyMovement.x);
                    
                    for j = 1 : length(movementDirection)
                        
                        if(movementDirection(j) == movementDirection2(j))
                            
                            obj.leftHandData(i).pinkyCumulativeMovement.x(j) = obj.leftHandData(i-1).pinkyCumulativeMovement.x(j) + obj.leftHandData(i).pinkyMovement.x(j);
                            
                        else
                            
                            obj.leftHandData(i).pinkyCumulativeMovement.x(j) = obj.leftHandData(i).pinkyMovement.x(j);
                            
                        end
                        
                    end
                    
                end
                
                
                
                obj.leftHandData(1).thumbCumulativeMovement.x = obj.leftHandData(1).thumbMovement.x;
                
                for i = 2 : obj.totalFrames - 1
                    
                    movementDirection = sign(obj.leftHandData(i-1).thumbMovement.x);
                    
                    movementDirection2 = sign(obj.leftHandData(i).thumbMovement.x);
                    if(i == 89)
                        temp = 0;
                    end
                    for j = 1 : length(movementDirection)
                        
                        if(movementDirection(j) == movementDirection2(j))
                            
                            obj.leftHandData(i).thumbCumulativeMovement.x(j) = obj.leftHandData(i-1).thumbCumulativeMovement.x(j) + obj.leftHandData(i).thumbMovement.x(j);
                            
                        else
                            
                            obj.leftHandData(i).thumbCumulativeMovement.x(j) = obj.leftHandData(i).thumbMovement.x(j);
                            
                        end
                        
                    end
                    
                end
                
                
                
                obj.rightHandData(1).pointerCumulativeMovement.x = obj.rightHandData(1).pointerMovement.x;
                
                for i = 2 : obj.totalFrames - 1
                    
                    movementDirection = sign(obj.rightHandData(i-1).pointerMovement.x);
                    
                    movementDirection2 = sign(obj.rightHandData(i).pointerMovement.x);
                    
                    for j = 1 : length(movementDirection)
                        
                        if(movementDirection(j) == movementDirection2(j))
                            
                            obj.rightHandData(i).pointerCumulativeMovement.x(j) = obj.rightHandData(i-1).pointerCumulativeMovement.x(j) + obj.rightHandData(i).pointerMovement.x(j);
                            
                        else
                            
                            obj.rightHandData(i).pointerCumulativeMovement.x(j) = obj.rightHandData(i).pointerMovement.x(j);
                            
                        end
                        
                    end
                    
                end
                
                
                
                obj.rightHandData(1).middleCumulativeMovement.x = obj.rightHandData(1).middleMovement.x;
                
                for i = 2 : obj.totalFrames - 1
                    
                    movementDirection = sign(obj.rightHandData(i-1).middleMovement.x);
                    
                    movementDirection2 = sign(obj.rightHandData(i).middleMovement.x);
                    
                    for j = 1 : length(movementDirection)
                        
                        if(movementDirection(j) == movementDirection2(j))
                            
                            obj.rightHandData(i).middleCumulativeMovement.x(j) = obj.rightHandData(i-1).middleCumulativeMovement.x(j) + obj.rightHandData(i).middleMovement.x(j);
                            
                        else
                            
                            obj.rightHandData(i).middleCumulativeMovement.x(j) = obj.rightHandData(i).middleMovement.x(j);
                            
                        end
                        
                    end
                    
                end
                
                
                
                obj.rightHandData(1).indexCumulativeMovement.x = obj.rightHandData(1).indexMovement.x;
                
                for i = 2 : obj.totalFrames - 1
                    
                    movementDirection = sign(obj.rightHandData(i-1).indexMovement.x);
                    
                    movementDirection2 = sign(obj.rightHandData(i).indexMovement.x);
                    
                    for j = 1 : length(movementDirection)
                        
                        if(movementDirection(j) == movementDirection2(j))
                            
                            obj.rightHandData(i).indexCumulativeMovement.x(j) = obj.rightHandData(i-1).indexCumulativeMovement.x(j) + obj.rightHandData(i).indexMovement.x(j);
                            
                        else
                            
                            obj.rightHandData(i).indexCumulativeMovement.x(j) = obj.rightHandData(i).indexMovement.x(j);
                            
                        end
                        
                    end
                    
                end
                
                
                
                obj.rightHandData(1).pinkyCumulativeMovement.x = obj.rightHandData(1).pinkyMovement.x;
                
                for i = 2 : obj.totalFrames - 1
                    
                    movementDirection = sign(obj.rightHandData(i-1).pinkyMovement.x);
                    
                    movementDirection2 = sign(obj.rightHandData(i).pinkyMovement.x);
                    
                    for j = 1 : length(movementDirection)
                        
                        if(movementDirection(j) == movementDirection2(j))
                            
                            obj.rightHandData(i).pinkyCumulativeMovement.x(j) = obj.rightHandData(i-1).pinkyCumulativeMovement.x(j) + obj.rightHandData(i).pinkyMovement.x(j);
                            
                        else
                            
                            obj.rightHandData(i).pinkyCumulativeMovement.x(j) = obj.rightHandData(i).pinkyMovement.x(j);
                            
                        end
                        
                    end
                    
                end
                
                
                                
                obj.rightHandData(1).thumbCumulativeMovement.x = obj.rightHandData(1).thumbMovement.x;
                
                for i = 2 : obj.totalFrames - 1
                    
                    movementDirection = sign(obj.rightHandData(i-1).thumbMovement.x);
                    
                    movementDirection2 = sign(obj.rightHandData(i).thumbMovement.x);
                    
                    for j = 1 : length(movementDirection)
                        
                        if(movementDirection(j) == movementDirection2(j))
                            
                            obj.rightHandData(i).thumbCumulativeMovement.x(j) = obj.rightHandData(i-1).thumbCumulativeMovement.x(j) + obj.rightHandData(i).thumbMovement.x(j);
                            
                        else
                            
                            obj.rightHandData(i).thumbCumulativeMovement.x(j) = obj.rightHandData(i).thumbMovement.x(j);
                            
                        end
                        
                    end
                    
                end
                
                
                
        end
        function KeyPositionReader(obj, fileLocation)
            fid = fopen(fileLocation, 'r');
            tline = fgetl(fid);
            tline = fgetl(fid);
            tline = fgetl(fid);
            currKey = 0;
            while ischar(tline)
                
                tline = strrep(tline, '[', '');
                tline = strrep(tline, ']', '');
                keyData = textscan(tline, '%s%f%f%f%f%f%f%f%f', 'Delimiter', {'|'});
                obj.keyArray{currKey+1} = keyData{1};
                obj.keyAreaArray(:,:,currKey+1) = [1080-keyData{2}, keyData{3}; 1080-keyData{4}, keyData{5}; 1080-keyData{8}, keyData{9}; 1080-keyData{6}, keyData{7}];
                tline = fgetl(fid);
                currKey = currKey + 1;
            end
            obj.totalKeys = currKey;
            fclose(fid);
        end
        function KeyPositionFrameReader(obj,folderLocation)
            directoryFiles = dir(folderLocation);
            currFrame      = 1;
            
            %% Read Data Data
            for i = 1 : length(directoryFiles)
                currentFile = directoryFiles(i);
                % Ignores Directories
                if(~currentFile.isdir)
                    filepath = fullfile(folderLocation, currentFile.name);
                    %                     textscan(currentFile.name, '%s_%d.txt'
                    fid = fopen(filepath);
                    tline = fgetl(fid);
                    tline = fgetl(fid);
                    tline = fgetl(fid);
                    currKey = 0;
                    while ischar(tline)
                        
                        tline = strrep(tline, '[', '');
                        tline = strrep(tline, ']', '');
                        keyData = textscan(tline, '%s%f%f%f%f%f%f%f%f', 'Delimiter', {'|'});
                        obj.keyArray{currKey+1} = keyData{1};
                        obj.keyAreaArray(:,:,currKey+1, currFrame) = [1080-keyData{2}, keyData{3}; 1080-keyData{4}, keyData{5}; 1080-keyData{8}, keyData{9}; 1080-keyData{6}, keyData{7}];
                        if(currKey == 0)
                            temp = 0;
                        end
                        tline = fgetl(fid);
                        currKey = currKey + 1;
                    end
                    if(currKey>61)
                        currKey
                    end
                    fclose(fid);
                    currFrame = currFrame + 1;
                end
            end
        end
        function FingerDerivative(obj)
            %             for i = 1 : length(obj.leftHandData.thumb.x(
            for i = 2 : obj.totalFrames
                obj.leftHandData(i-1).thumbMovement.x = obj.leftHandData(i-1).thumb.x - obj.leftHandData(i).thumb.x;
                obj.leftHandData(i-1).thumbMovement.y = obj.leftHandData(i-1).thumb.y - obj.leftHandData(i).thumb.y;
                
                obj.leftHandData(i-1).pointerMovement.x = obj.leftHandData(i-1).pointer.x - obj.leftHandData(i).pointer.x;
                obj.leftHandData(i-1).pointerMovement.y = obj.leftHandData(i-1).pointer.y - obj.leftHandData(i).pointer.y;
                
                obj.leftHandData(i-1).middleMovement.x = obj.leftHandData(i-1).middle.x - obj.leftHandData(i).middle.x;
                obj.leftHandData(i-1).middleMovement.y = obj.leftHandData(i-1).middle.y - obj.leftHandData(i).middle.y;
                
                obj.leftHandData(i-1).indexMovement.x = obj.leftHandData(i-1).index.x - obj.leftHandData(i).index.x;
                obj.leftHandData(i-1).indexMovement.y = obj.leftHandData(i-1).index.y - obj.leftHandData(i).index.y;
                
                obj.leftHandData(i-1).pinkyMovement.x = obj.leftHandData(i-1).pinky.x - obj.leftHandData(i).pinky.x;
                obj.leftHandData(i-1).pinkyMovement.y = obj.leftHandData(i-1).pinky.y - obj.leftHandData(i).pinky.y;
                
                obj.rightHandData(i-1).thumbMovement.x = obj.rightHandData(i-1).thumb.x - obj.rightHandData(i).thumb.x;
                obj.rightHandData(i-1).thumbMovement.y = obj.rightHandData(i-1).thumb.y - obj.rightHandData(i).thumb.y;
                
                obj.rightHandData(i-1).pointerMovement.x = obj.rightHandData(i-1).pointer.x - obj.rightHandData(i).pointer.x;
                obj.rightHandData(i-1).pointerMovement.y = obj.rightHandData(i-1).pointer.y - obj.rightHandData(i).pointer.y;
                
                obj.rightHandData(i-1).middleMovement.x = obj.rightHandData(i-1).middle.x - obj.rightHandData(i).middle.x;
                obj.rightHandData(i-1).middleMovement.y = obj.rightHandData(i-1).middle.y - obj.rightHandData(i).middle.y;
                
                obj.rightHandData(i-1).indexMovement.x = obj.rightHandData(i-1).index.x - obj.rightHandData(i).index.x;
                obj.rightHandData(i-1).indexMovement.y = obj.rightHandData(i-1).index.y - obj.rightHandData(i).index.y;
                
                obj.rightHandData(i-1).pinkyMovement.x = obj.rightHandData(i-1).pinky.x - obj.rightHandData(i).pinky.x;
                obj.rightHandData(i-1).pinkyMovement.y = obj.rightHandData(i-1).pinky.y - obj.rightHandData(i).pinky.y;
            end
        end
        function SliderHandPlot(obj)
            obj.F = figure;
            H = uicontrol(obj.F, 'style', 'slider', 'Min', 1, 'Max', obj.totalFrames, 'Value', 1, 'Position', [0 0 480 20]);
            addlistener(H, 'Value', 'PostSet', @myCallBack);
            obj.ax1 = subplot(1,2,1)
            v = VideoReader(obj.videoLocation);
            videoFrame = readFrame(v);
            
            h = image(videoFrame);
            
            hold on;
            plot(obj.leftHandData(1).thumb.x,obj.leftHandData(1).thumb.y);
            plot(obj.leftHandData(1).pointer.x,obj.leftHandData(1).pointer.y);
            plot(obj.leftHandData(1).middle.x,obj.leftHandData(1).middle.y);
            plot(obj.leftHandData(1).index.x,obj.leftHandData(1).index.y);
            plot(obj.leftHandData(1).pinky.x,obj.leftHandData(1).pinky.y);
            
            plot(obj.rightHandData(1).thumb.x,obj.rightHandData(1).thumb.y);
            plot(obj.rightHandData(1).pointer.x,obj.rightHandData(1).pointer.y);
            plot(obj.rightHandData(1).middle.x,obj.rightHandData(1).middle.y);
            plot(obj.rightHandData(1).index.x,obj.rightHandData(1).index.y);
            h = plot(obj.rightHandData(1).pinky.x,obj.rightHandData(1).pinky.y);
            hold off;
            view([90 90])
            obj.ax2 = subplot(1,2,2)
            
            plot(1, obj.leftHandData(1).thumbMovement.x(1), 'r*');
            hold on;
            plot(1, obj.leftHandData(1).thumbMovement.y(1), 'ro');
            plot(1, obj.leftHandData(1).thumbMovement.x(end), 'g*');
            plot(1, obj.leftHandData(1).thumbMovement.y(end), 'go');
            
            plot(2, obj.leftHandData(1).pointerMovement.x(1), 'r*');
            plot(2, obj.leftHandData(1).pointerMovement.y(1), 'ro');
            plot(2, obj.leftHandData(1).pointerMovement.x(end), 'g*');
            plot(2, obj.leftHandData(1).pointerMovement.y(end), 'go');
            
            plot(3, obj.leftHandData(1).middleMovement.x(1), 'r*');
            plot(3, obj.leftHandData(1).middleMovement.y(1), 'ro');
            plot(3, obj.leftHandData(1).middleMovement.x(end), 'g*');
            plot(3, obj.leftHandData(1).middleMovement.y(end), 'go');
            
            plot(4, obj.leftHandData(1).indexMovement.x(1), 'r*');
            plot(4, obj.leftHandData(1).indexMovement.y(1), 'ro');
            plot(4, obj.leftHandData(1).indexMovement.x(end), 'g*');
            plot(4, obj.leftHandData(1).indexMovement.y(end), 'go');
            
            plot(5, obj.leftHandData(1).pinkyMovement.x(1), 'r*');
            plot(5, obj.leftHandData(1).pinkyMovement.y(1), 'ro');
            plot(5, obj.leftHandData(1).pinkyMovement.x(end), 'g*');
            plot(5, obj.leftHandData(1).pinkyMovement.y(end), 'go');
            
            plot(6, obj.rightHandData(1).thumbMovement.x(1), 'r*');
            plot(6, obj.rightHandData(1).thumbMovement.y(1), 'ro');
            plot(6, obj.rightHandData(1).thumbMovement.x(end), 'g*');
            plot(6, obj.rightHandData(1).thumbMovement.y(end), 'go');
            
            plot(7, obj.rightHandData(1).pointerMovement.x(1), 'r*');
            plot(7, obj.rightHandData(1).pointerMovement.y(1), 'ro');
            plot(7, obj.rightHandData(1).pointerMovement.x(end), 'g*');
            plot(7, obj.rightHandData(1).pointerMovement.y(end), 'go');
            
            plot(8, obj.rightHandData(1).middleMovement.x(1), 'r*');
            plot(8, obj.rightHandData(1).middleMovement.y(1), 'ro');
            plot(8, obj.rightHandData(1).middleMovement.x(end), 'g*');
            plot(8, obj.rightHandData(1).middleMovement.y(end), 'go');
            
            plot(9, obj.rightHandData(1).indexMovement.x(1), 'r*');
            plot(9, obj.rightHandData(1).indexMovement.y(1), 'ro');
            plot(9, obj.rightHandData(1).indexMovement.x(end), 'g*');
            plot(9, obj.rightHandData(1).indexMovement.y(end), 'go');
            
            plot(10, obj.rightHandData(1).pinkyMovement.x(1), 'r*');
            plot(10, obj.rightHandData(1).pinkyMovement.y(1), 'ro');
            plot(10, obj.rightHandData(1).pinkyMovement.x(end), 'g*');
            plot(10, obj.rightHandData(1).pinkyMovement.y(end), 'go');
            hold off;
            function myCallBack(hObj, event)
                val = ceil(event.AffectedObject.Value)
                
                %                 subplot(1,2,1, obj.F)
                v = VideoReader(obj.videoLocation);
                v.CurrentTime = val/v.FrameRate;
                videoFrame = readFrame(v);
                axes(obj.ax1)
                h = image(videoFrame);
                hold on;
                plot(obj.leftHandData(val).thumb.x,obj.leftHandData(val).thumb.y);
                plot(obj.leftHandData(val).pointer.x,obj.leftHandData(val).pointer.y);
                plot(obj.leftHandData(val).middle.x,obj.leftHandData(val).middle.y);
                plot(obj.leftHandData(val).index.x,obj.leftHandData(val).index.y);
                plot(obj.leftHandData(val).pinky.x,obj.leftHandData(val).pinky.y);
                
                plot(obj.rightHandData(val).thumb.x,obj.rightHandData(val).thumb.y);
                plot(obj.rightHandData(val).pointer.x,obj.rightHandData(val).pointer.y);
                plot(obj.rightHandData(val).middle.x,obj.rightHandData(val).middle.y);
                plot(obj.rightHandData(val).index.x,obj.rightHandData(val).index.y);
                h = plot(obj.rightHandData(val).pinky.x,obj.rightHandData(val).pinky.y);
                hold off;
                view([90 90])
                axes(obj.ax2)
                
                plot(1, obj.leftHandData(val).thumbMovement.x(1), 'r*');
                hold on;
                plot(1, obj.leftHandData(val).thumbMovement.y(1), 'ro');
                plot(1, obj.leftHandData(val).thumbMovement.x(end), 'g*');
                plot(1, obj.leftHandData(val).thumbMovement.y(end), 'go');
                
                plot(2, obj.leftHandData(val).pointerMovement.x(1), 'r*');
                plot(2, obj.leftHandData(val).pointerMovement.y(1), 'ro');
                plot(2, obj.leftHandData(val).pointerMovement.x(end), 'g*');
                plot(2, obj.leftHandData(val).pointerMovement.y(end), 'go');
                
                plot(3, obj.leftHandData(val).middleMovement.x(1), 'r*');
                plot(3, obj.leftHandData(val).middleMovement.y(1), 'ro');
                plot(3, obj.leftHandData(val).middleMovement.x(end), 'g*');
                plot(3, obj.leftHandData(val).middleMovement.y(end), 'go');
                
                plot(4, obj.leftHandData(val).indexMovement.x(1), 'r*');
                plot(4, obj.leftHandData(val).indexMovement.y(1), 'ro');
                plot(4, obj.leftHandData(val).indexMovement.x(end), 'g*');
                plot(4, obj.leftHandData(val).indexMovement.y(end), 'go');
                
                plot(5, obj.leftHandData(val).pinkyMovement.x(1), 'r*');
                plot(5, obj.leftHandData(val).pinkyMovement.y(1), 'ro');
                plot(5, obj.leftHandData(val).pinkyMovement.x(end), 'g*');
                plot(5, obj.leftHandData(val).pinkyMovement.y(end), 'go');
                
                
                plot(6, obj.rightHandData(val).thumbMovement.x(1), 'r*');
                plot(6, obj.rightHandData(val).thumbMovement.y(1), 'ro');
                plot(6, obj.rightHandData(val).thumbMovement.x(end), 'g*');
                plot(6, obj.rightHandData(val).thumbMovement.y(end), 'go');
                
                plot(7, obj.rightHandData(val).pointerMovement.x(1), 'r*');
                plot(7, obj.rightHandData(val).pointerMovement.y(1), 'ro');
                plot(7, obj.rightHandData(val).pointerMovement.x(end), 'g*');
                plot(7, obj.rightHandData(val).pointerMovement.y(end), 'go');
                
                plot(8, obj.rightHandData(val).middleMovement.x(1), 'r*');
                plot(8, obj.rightHandData(val).middleMovement.y(1), 'ro');
                plot(8, obj.rightHandData(val).middleMovement.x(end), 'g*');
                plot(8, obj.rightHandData(val).middleMovement.y(end), 'go');
                
                plot(9, obj.rightHandData(val).indexMovement.x(1), 'r*');
                plot(9, obj.rightHandData(val).indexMovement.y(1), 'ro');
                plot(9, obj.rightHandData(val).indexMovement.x(end), 'g*');
                plot(9, obj.rightHandData(val).indexMovement.y(end), 'go');
                
                plot(10, obj.rightHandData(val).pinkyMovement.x(1), 'r*');
                plot(10, obj.rightHandData(val).pinkyMovement.y(1), 'ro');
                plot(10, obj.rightHandData(val).pinkyMovement.x(end), 'g*');
                plot(10, obj.rightHandData(val).pinkyMovement.y(end), 'go');
                hold off;
            end
        end
        
        function HandVideo(obj)
            h = figure;%('units', 'normalized', 'outerposition', [0 0 1 1]);
            v = VideoWriter('Typing_Fingers.avi');
            vIn = VideoReader(obj.videoLocation);
            
            open(v);
            for i = 1 : obj.totalFrames
                ax = subplot(1,2,1);
                videoFrame = readFrame(vIn);
                h = image(videoFrame);
                
                hold on;
                for currKey = 1 : obj.totalKeys
                    Vertices(1:4,1:2) = obj.keyAreaArray(:,:,currKey,i);
                    Vertices(5:8,1:2) = obj.keyAreaArray(:,:,currKey,i);
                    temp = Vertices(:,1);
                    Vertices(:,1) = Vertices(:,2);
                    Vertices(:,2) = temp;
                    Vertices(1:4,3) = 0;
                    
                    Vertices(5:8,3) =  sum(squeeze(obj.fingersInsideKey(:,currKey, i)));
                    Faces = [1 2 3 4; 1 4 8 5; 4 3 7 8; 2 3 7 6; 1 2 6 5; 5 6 7 8]; % 3 4 7 8; 2 4 6 8; 1 2 5 6; 5 6 7 8
                    if(sum(squeeze(obj.fingersInsideKey(:,currKey, i)))>0)
                        patch('Vertices', Vertices, 'Faces', Faces, 'FaceColor', 'r', 'FaceAlpha', '0.2');
                    elseif(sum(squeeze(obj.fingersInsideKey(:,currKey, i)))<0)
                        patch('Vertices', Vertices, 'Faces', Faces, 'FaceColor', 'b', 'FaceAlpha', '0.2');
                    else
                        patch('Vertices', Vertices, 'Faces', Faces, 'FaceColor', 'g', 'FaceAlpha', '0.2');
                    end
                end
                 view([90 90])
                currFrameKeyPresses = find(obj.keyPressData(:,1) == i);
                for j = 1 : length(currFrameKeyPresses) 
                    currFinger = obj.keyPressData(currFrameKeyPresses(j),2);
                    currKey = find(obj.fingersInsideKey(currFinger,:,i));
                    if(~isempty(currKey))
                        fprintf('Key %s pressed at frame: %d\n',obj.keyArray{currKey}{1} ,i);
                    end
                end
                
               
                plot(obj.leftHandData(i).thumb.x,obj.leftHandData(i).thumb.y);
                plot(obj.leftHandData(i).pointer.x,obj.leftHandData(i).pointer.y);
                plot(obj.leftHandData(i).middle.x,obj.leftHandData(i).middle.y);
                plot(obj.leftHandData(i).index.x,obj.leftHandData(i).index.y);
                plot(obj.leftHandData(i).pinky.x,obj.leftHandData(i).pinky.y);
                
                plot(obj.rightHandData(i).thumb.x,obj.rightHandData(i).thumb.y);
                plot(obj.rightHandData(i).pointer.x,obj.rightHandData(i).pointer.y);
                plot(obj.rightHandData(i).middle.x,obj.rightHandData(i).middle.y);
                plot(obj.rightHandData(i).index.x,obj.rightHandData(i).index.y);
                h = plot(obj.rightHandData(i).pinky.x,obj.rightHandData(i).pinky.y);
                hold off;
                subplot(1,2,2)
                currFrameKeyPresses = find(obj.keyPressData(:,1) <= i);
                if(~isempty(currFrameKeyPresses))
                    for i = 1 : length(currFrameKeyPresses)
                        
                    end
                end
                %                 subplot(1,2,2)
                %
                %                 plot(1, obj.leftHandData(i).thumbMovement.x(1), 'r*');
                %                 hold on;
                %                 plot(1, obj.leftHandData(i).thumbMovement.y(1), 'ro');
                %                 plot(1, obj.leftHandData(i).thumbMovement.x(end), 'g*');
                %                 plot(1, obj.leftHandData(i).thumbMovement.y(end), 'go');
                %
                %                 plot(2, obj.leftHandData(i).pointerMovement.x(1), 'r*');
                %                 plot(2, obj.leftHandData(i).pointerMovement.y(1), 'ro');
                %                 plot(2, obj.leftHandData(i).pointerMovement.x(end), 'g*');
                %                 plot(2, obj.leftHandData(i).pointerMovement.y(end), 'go');
                %
                %                 plot(3, obj.leftHandData(i).middleMovement.x(1), 'r*');
                %                 plot(3, obj.leftHandData(i).middleMovement.y(1), 'ro');
                %                 plot(3, obj.leftHandData(i).middleMovement.x(end), 'g*');
                %                 plot(3, obj.leftHandData(i).middleMovement.y(end), 'go');
                %
                %                 plot(4, obj.leftHandData(i).indexMovement.x(1), 'r*');
                %                 plot(4, obj.leftHandData(i).indexMovement.y(1), 'ro');
                %                 plot(4, obj.leftHandData(i).indexMovement.x(end), 'g*');
                %                 plot(4, obj.leftHandData(i).indexMovement.y(end), 'go');
                %
                %                 plot(5, obj.leftHandData(i).pinkyMovement.x(1), 'r*');
                %                 plot(5, obj.leftHandData(i).pinkyMovement.y(1), 'ro');
                %                 plot(5, obj.leftHandData(i).pinkyMovement.x(end), 'g*');
                %                 plot(5, obj.leftHandData(i).pinkyMovement.y(end), 'go');
                %                 hold off;
                %                 pause(0.1)
                F(i) = getframe();
                writeVideo(v,F(i));
                
            end
            close(v)
            %             close(v_in)
        end
        function key = DeterminePoint(obj, location)
            if(true)
                %Search through obj.keyAreaArray to see if location is
                %located within
                
            else
                key = {};
            end
        end
    end
end