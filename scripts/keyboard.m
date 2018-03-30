classdef keyboard < handle
    properties
        keyArray;
        keyAreaArray;
        totalKeys;
        videoData;
        leftHandData;
        rightHandData;
        openPoseResolution;
        totalFrames; %Still need to figure this out
        fingersInsideKey;
        outputFrames;
    end
    methods
        function obj = Keyboard(VideoLocation, OpenPoseFolder, OpenPoseResolution)
            obj.keyArray = {};
            obj.keyAreaArray = [];
            obj.totalKeys = 0;
            if(nargin>=1)
                obj.videoData = VideoReader(VideoLocation);
            else
                %Call File Open to Video
            end
            if(nargin>=2)
                [obj.leftHandData, obj.rightHandData] = readOpenPoseOutput(OpenPoseFolder, false);
                
            else
                %Call File Open to find directory
            end
           
            
            if(nargin>=3)
                obj.openPoseResolution = OpenPoseResolution; % should be 2 dimensional matrix
            else
                %Ask for User Input
            end
             %Convert obj.leftHandData and obj.rightHandData back to original video resolution
             leftHandDataFields = fieldnames(obj.leftHandData);
             for i = 1 : length(leftHandDataFields)
                 currField = leftHandDataFields{i};
                 obj.leftHandData.(currField).x = obj.leftHandData.(currField).x/obj.openPoseResolution(1) .* obj.videoData.Width;
                 obj.leftHandData.(currField).x = obj.leftHandData.(currField).y/obj.openPoseResolution(2) .* obj.videoData.Height;
                 
                 obj.rightHandData.(currField).x = obj.rightHandData.(currField).x/obj.openPoseResolution(1) .* obj.videoData.Width;
                 obj.rightHandData.(currField).y = obj.rightHandData.(currField).y/obj.openPoseResolution(2) .* obj.videoData.Height;
             end
             obj.SetAppleKeyboard();
             
        end
        function SetAppleKeyboard(obj)
            obj.keyArray = {{'esc','f1','f2','f3','f4','f5','f6','f7','f8','f9','f10','f11','f12','Power'};...
                {'<','1','2','3','4','5','6','7','8','9','0','-','=','delete'};...
                {'tab','q','w','e','r','t','y','u','i','o','p','{','}','\'};...
                {'caps','a','s','d','e','f','g','h','j','k','l',';','''','Enter'};...
                {'shift','z','x','c','v','b','n','m',',','.','/','shift','esc'};...
                {'fn','control','option','command','space','command','option','left','down','right'}};
            obj.totalKeys = numel(obj.keyArray{1}) + numel(obj.keyArray{2}) + numel(obj.keyArray{3}) + numel(obj.keyArray{4})  + numel(obj.keyArray{5})  +numel(obj.keyArray{6}) ;
            obj.keyAreaArray = zeros(4,2,obj.totalKeys);
        end
        function SetKeyAreaArray(obj)
            currKey = 1;
            for j = 1 : numel(obj.keyArray)
                for i = 1 : numel(obj.keyArray{j});
                    obj.keyAreaArray(:,:,currKey) = [-i+1 -j+1; -i+1 -j; -i -j; -i -j+1];
                    currKey = currKey + 1;
                end
            end
        end
        function PlotKeys(obj)
            Vertices = zeros(8,3);
            figure
           
            for currFrame = 1 : obj.totalFrames
                hold off
                for currKey = 1 : obj.totalKeys
                    Vertices(1:4,1:2) = obj.keyAreaArray(:,:,currKey);
                    Vertices(5:8,1:2) = obj.keyAreaArray(:,:,currKey);
                    Vertices(1:4,3) = 0;
                    
                    Vertices(5:8,3) =  sum(squeeze(obj.fingersInsideKey(:,currKey, currFrame)));
                    Faces = [1 2 3 4; 1 4 8 5; 4 3 7 8; 2 3 7 6; 1 2 6 5; 5 6 7 8]; % 3 4 7 8; 2 4 6 8; 1 2 5 6; 5 6 7 8
                    
                    patch('Vertices', Vertices, 'Faces', Faces, 'FaceColor', 'g');
                    hold on
                    
                end
                F(currFrame) = getframe(gcf);
            end
            obj.outputFrames = F;
        end
        function DetermineAllKeyHover(obj)
            %Check Hand Data for each finger
            for currKeyNumber = 1 : obj.totalKeys
                currKeyX = squeeze(obj.keyAreaArray(:,1,currKeyNumber));
                currKeyY = squeeze(obj.keyAreaArray(:,2,currKeyNumber));
                currKeyX(end+1) = currKeyX(1);
                currKeyY(end+1) = currKeyY(1);
                
                
                obj.fingersInsideKey(1,currKeyNumber,:) = inpolygon(currKeyX, currKeyY, obj.leftHandData.thumb.x(:,end), obj.leftHandData.thumb.y(:,end));
                obj.fingersInsideKey(2,currKeyNumber,:) = inpolygon(currKeyX, currKeyY, obj.leftHandData.pointer.x(:,end), obj.leftHandData.pointer.y(:,end));
                obj.fingersInsideKey(3,currKeyNumber,:) = inpolygon(currKeyX, currKeyY, obj.leftHandData.middle.x(:,end), obj.leftHandData.middle.y(:,end));
                obj.fingersInsideKey(4,currKeyNumber,:) = inpolygon(currKeyX, currKeyY, obj.leftHandData.index.x(:,end), obj.leftHandData.index.y(:,end));
                obj.fingersInsideKey(5,currKeyNumber,:) = inpolygon(currKeyX, currKeyY, obj.leftHandData.pinky.x(:,end), obj.leftHandData.pinky.y(:,end));
                obj.fingersInsideKey(6,currKeyNumber,:) = inpolygon(currKeyX, currKeyY, obj.rightHandData.thumb.x(:,end), obj.rightHandData.thumb.y(:,end));
                obj.fingersInsideKey(7,currKeyNumber,:) = inpolygon(currKeyX, currKeyY, obj.rightHandData.pointer.x(:,end), obj.rightHandData.pointer.y(:,end));
                obj.fingersInsideKey(8,currKeyNumber,:) = inpolygon(currKeyX, currKeyY, obj.rightHandData.middle.x(:,end), obj.rightHandData.middle.y(:,end));
                obj.fingersInsideKey(9,currKeyNumber,:) = inpolygon(currKeyX, currKeyY, obj.rightHandData.index.x(:,end), obj.rightHandData.index.y(:,end));
                obj.fingersInsideKey(10,currKeyNumber,:) = inpolygon(currKeyX, currKeyY, obj.rightHandData.pinky.x(:,end), obj.rightHandData.pinky.y(:,end));
                
            end
            
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