% Read in image into an array.
[rgbImage storedColorMap] = imread('keyboard.jpg'); 
[rows columns numberOfColorBands] = size(rgbImage); 
% If it's monochrome (indexed), convert it to color. 
% Check to see if it's an 8-bit image needed later for scaling).
if strcmpi(class(rgbImage), 'uint8')
	% Flag for 256 gray levels.
	eightBit = true;
else
	eightBit = false;
end
if numberOfColorBands == 1
	if isempty(storedColorMap)
		% Just a simple gray level image, not indexed with a stored color map.
		% Create a 3D true color image where we copy the monochrome image into all 3 (R, G, & B) color planes.
		rgbImage = cat(3, rgbImage, rgbImage, rgbImage);
	else
		% It's an indexed image.
		rgbImage = ind2rgb(rgbImage, storedColorMap);
		% ind2rgb() will convert it to double and normalize it to the range 0-1.
		% Convert back to uint8 in the range 0-255, if needed.
		if eightBit
			rgbImage = uint8(255 * rgbImage);
		end
	end
end 

% Display the original image.
subplot(2, 2, 1);
imshow(rgbImage);
set(gcf, 'Position', get(0,'Screensize')); % Enlarge figure to full screen.
set(gcf,'name','Demo by ImageAnalyst','numbertitle','off') 
drawnow; % Make it display immediately. 
if numberOfColorBands > 1 
	title('Original Color Image', 'FontSize', fontSize); 
	grayImage = rgbImage(:,:,1);
else 
	caption = sprintf('Original Indexed Image\n(converted to true color with its stored colormap)');
	title(caption, 'FontSize', fontSize);
	grayImage = rgbImage;
end
% Display it.
subplot(2, 2, 2);
imshow(grayImage, []);
title('Grayscale Image', 'FontSize', fontSize);

% Binarize the image.
binaryImage = grayImage < 100;
% Display it.
subplot(2, 2, 3);
imshow(binaryImage, []);
title('Binary Image', 'FontSize', fontSize);
% Remove small objects.
binaryImage = bwareaopen(binaryImage, 300);
% Display it.
subplot(2, 2, 4);
imshow(binaryImage, []);
title('Cleaned Binary Image', 'FontSize', fontSize);

[labeledImage numberOfObjcts] = bwlabel(binaryImage);
blobMeasurements = regionprops(labeledImage,'Perimeter','Area'); 

circularities = [blobMeasurements.Perimeter.^2] ./ (4 * pi * [blobMeasurements.Area])

% Say what they are
for blobNumber = 1 : numberOfObjcts
	if circularities(blobNumber) < 1.19
		message = sprintf('The circularity of object #%d is %.3f, so the object is a circle',...
			blobNumber, circularities(blobNumber));
	elseif circularities(blobNumber) < 1.53
		message = sprintf('The circularity of object #%d is %.3f, so the object is a square',...
			blobNumber, circularities(blobNumber));
	else
		message = sprintf('The circularity of object #%d is %.3f, so the object is a triangle',...
			blobNumber, circularities(blobNumber));
	end
	uiwait(msgbox(message));
end