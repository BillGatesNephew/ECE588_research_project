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
        outputFrames;
    end
    methods
        function obj = keyboard2(VideoLocation, OpenPoseFolder, OpenPoseResolution)
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
           
            
            if(nargin>=3)
                obj.openPoseResolution = OpenPoseResolution; % should be 2 dimensional matrix
            else
                %Ask for User Input
            end
             %Convert obj.leftHandData and obj.rightHandData back to original video resolution
            
                 obj.totalFrames = length(obj.leftHandData);
%                  for j = 1 : obj.totalFrames
%                     obj.leftHandData(j).allX = obj.leftHandData(j).allX/obj.openPoseResolution(1) .* obj.videoData.Width;
%                     obj.leftHandData(j).allY = obj.leftHandData(j).allY/obj.openPoseResolution(2) .* obj.videoData.Height;
%                     obj.leftHandData(j).thumb.x = obj.leftHandData(j).thumb.x/obj.openPoseResolution(1) .* obj.videoData.Width;
%                     obj.leftHandData(j).thumb.y = obj.leftHandData(j).thumb.y/obj.openPoseResolution(2) .* obj.videoData.Height;
%                     obj.leftHandData(j).pointer.x = obj.leftHandData(j).pointer.x/obj.openPoseResolution(1) .* obj.videoData.Width;
%                     obj.leftHandData(j).pointer.y = obj.leftHandData(j).pointer.y/obj.openPoseResolution(2) .* obj.videoData.Height;
%                     obj.leftHandData(j).middle.x = obj.leftHandData(j).middle.x/obj.openPoseResolution(1) .* obj.videoData.Width;
%                     obj.leftHandData(j).middle.y = obj.leftHandData(j).middle.y/obj.openPoseResolution(2) .* obj.videoData.Height;
%                     obj.leftHandData(j).index.x = obj.leftHandData(j).index.x/obj.openPoseResolution(1) .* obj.videoData.Width;
%                     obj.leftHandData(j).index.y = obj.leftHandData(j).index.y/obj.openPoseResolution(2) .* obj.videoData.Height;
%                     obj.leftHandData(j).pinky.x = obj.leftHandData(j).pinky.x/obj.openPoseResolution(1) .* obj.videoData.Width;
%                     obj.leftHandData(j).pinky.y = obj.leftHandData(j).pinky.y/obj.openPoseResolution(2) .* obj.videoData.Height;
%                     
%                     obj.rightHandData(j).allX = obj.rightHandData(j).allX/obj.openPoseResolution(1) .* obj.videoData.Width;
%                     obj.rightHandData(j).allY = obj.rightHandData(j).allY/obj.openPoseResolution(2) .* obj.videoData.Height;
%                     obj.rightHandData(j).thumb.x = obj.rightHandData(j).thumb.x/obj.openPoseResolution(1) .* obj.videoData.Width;
%                     obj.rightHandData(j).thumb.y = obj.rightHandData(j).thumb.y/obj.openPoseResolution(2) .* obj.videoData.Height;
%                     obj.rightHandData(j).pointer.x = obj.rightHandData(j).pointer.x/obj.openPoseResolution(1) .* obj.videoData.Width;
%                     obj.rightHandData(j).pointer.y = obj.rightHandData(j).pointer.y/obj.openPoseResolution(2) .* obj.videoData.Height;
%                     obj.rightHandData(j).middle.x = obj.rightHandData(j).middle.x/obj.openPoseResolution(1) .* obj.videoData.Width;
%                     obj.rightHandData(j).middle.y = obj.rightHandData(j).middle.y/obj.openPoseResolution(2) .* obj.videoData.Height;
%                     obj.rightHandData(j).index.x = obj.rightHandData(j).index.x/obj.openPoseResolution(1) .* obj.videoData.Width;
%                     obj.rightHandData(j).index.y = obj.rightHandData(j).index.y/obj.openPoseResolution(2) .* obj.videoData.Height;
%                     obj.rightHandData(j).pinky.x = obj.rightHandData(j).pinky.x/obj.openPoseResolution(1) .* obj.videoData.Width;
%                     obj.rightHandData(j).pinky.y = obj.rightHandData(j).pinky.y/obj.openPoseResolution(2) .* obj.videoData.Height;
%                  end
             
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
        function fingerDerivative(obj)
%             for i = 1 : length(obj.leftHandData.thumb.x(
            
        end
        function output = plotHands(obj)
            figure
            min_x = 0;
            max_x = 1920;
            min_y = 0;
            max_y = 1080;
            v_in = VideoReader(obj.videoLocation);
            v = VideoWriter('Typing_Fingers.avi');
            open(v);
            for i = 1 : obj.totalFrames
                videoFrame = readFrame(v_in);
                image(videoFrame);
                hold on;
                plot(obj.leftHandData(i).thumb.x,obj.leftHandData(i).thumb.y);
                plot(obj.leftHandData(i).pointer.x,obj.leftHandData(i).pointer.y);
                plot(obj.leftHandData(i).middle.x,obj.leftHandData(i).middle.y);
                plot(obj.leftHandData(i).index.x,obj.leftHandData(i).index.y);
                plot(obj.leftHandData(i).pinky.x,obj.leftHandData(i).pinky.y);
                
                plot(obj.rightHandData(i).thumb.x,obj.rightHandData(i).thumb.y);
                plot(obj.rightHandData(i).pointer.x,obj.rightHandData(i).pointer.y);
                plot(obj.rightHandData(i).middle.x,obj.rightHandData(i).middle.y);
                plot(obj.rightHandData(i).index.x,obj.rightHandData(i).index.y);
                plot(obj.rightHandData(i).pinky.x,obj.rightHandData(i).pinky.y);
                hold off;
                F(i) = getframe();
                writeVideo(v,F(i));
            end
            close(v)
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