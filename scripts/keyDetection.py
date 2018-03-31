import cv2
import numpy as np 
from math import sqrt

##############################
## Constants and Parameters ##
#########################################################################

## Constants
# Map Defining Characters of Keys Detected
KEY_MAP = [
    # First Row
    "`", "1", "2", "3", "4","5","6","7","8","9","0","-","=", "DELETE",
    # Second Row
    "TAB", "Q", "W","E","R","T","Y","U","I","O","P","[","]","\\",
    # Third Row
    "CAPS_LOCK", "A", "S","D","F","G","H","J","K","L",";","'","RETURN",
    # Fourth Row
    "SHIFT","Z","X","C","V","B","N","M",",",".","/","SHIFT",
    # Fifth Row
    "FN","CTRL","ALT","CMD","SPACE","CMD","ALT","ARROWS"
]

## General Parameters
# Name of video being processed
videoName = 'typing_vid.mp4'
# Threshold for how far a square can be off a baseline to be on a different row
rowBaselineThreshold = 30

## Contour Detection Parameters
# Maximum valid size needed for a detected contour to be a key
maxImageKeyArea = 7000  
# Minimum valid size needed for a detected contour to be a key
minImageKeyArea = 900   
# Distance between centers of keys to be considered separate contours
distanceThreshold = 10  

## Text Label Parameters
fontSize = 0.5
fontFamily = cv2.FONT_HERSHEY_SIMPLEX
fontThickness = 2

######################
## Helper Functions ##
#########################################################################

# Rotates the passed in image by the specified angle. Does not crop the 
# original image, which is the problem with the normal OpenCV rotation.
def rotate_image(image, angle):
    # Creates Rotation Matrix and Extracts Components
    height, width, _ = image.shape
    (centerX, centerY) = (width // 2, height // 2)
    rotationMatrix = cv2.getRotationMatrix2D((centerX, centerY), -angle, 1.0)
    cosineComponent = np.abs(rotationMatrix[0,0])
    sineComponent = np.abs(rotationMatrix[0,1])
    # Create New Dimensions for Rotated Image
    newWidth = int((height * sineComponent) + (width * cosineComponent))
    newHeight = int((height * cosineComponent) + (width * sineComponent))
    # Adjust Rotation Matrix for New Dimensions 
    rotationMatrix[0, 2] += (newWidth / 2) - centerX
    rotationMatrix[1, 2] += (newHeight / 2) - centerY
    # Perform Rotation
    return cv2.warpAffine(image, rotationMatrix, (newWidth, newHeight))

# Calculates the distance between two points.
def calculate_distance(center1, center2):
    xDiff, yDiff= center1[0] - center2[0], center1[1] - center2[1]
    return sqrt(xDiff*xDiff + yDiff*yDiff)

# Calculates the X-coordinate representing the center of a square contour
def center_x_position(square):
    moment = cv2.moments(square)
    return int(moment["m10"] / moment["m00"])

# Calculates the Y-coordinate representing the center of a square contour
def center_y_position(square):
    moment = cv2.moments(square)
    return int(moment["m01"] / moment["m00"])

######################################
## Actual Keyboard Detection Script ##
#########################################################################

## Load and Adjust Initial Video Frame ##
# Load in frame
cap = cv2.VideoCapture(videoName)
_,frame = cap.read()
# Rotate to proper orientation
rotatedFrame = rotate_image(frame, 90)
# Resize image to mainly contain only the keyboard
rows,cols,_ = rotatedFrame.shape
rowShift = (rows * 2) // 3
resizedImage = rotatedFrame[rowShift : rows]
# Convert to image to grayscale and apply binary thresholding
grayImage = cv2.cvtColor(resizedImage, cv2.COLOR_BGR2GRAY)
_, binaryImage = cv2.threshold(grayImage, 127, 255, cv2.THRESH_BINARY_INV)

## Detect Squares in Image ##
# Apply canny edge detection, and dilate results
cannyImage = cv2.Canny(binaryImage, 0, 50, apertureSize=5)
dilatedCannyImage = cv2.dilate(cannyImage, None)
# Find contours within the dilated image
_, contours, _ = cv2.findContours(dilatedCannyImage, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
# Run square detection algorithm
squares = []
centerPositions = []
for cnt in contours:
    # Approximate a polynomial for contour
    cnt_len = 0.02*cv2.arcLength(cnt, True)
    cnt = cv2.approxPolyDP(cnt, cnt_len, True)
    cntArea = cv2.contourArea(cnt)
    # Determine whether to keep contour or not
    if len(cnt) == 4 and cntArea > minImageKeyArea and cntArea < maxImageKeyArea and cv2.isContourConvex(cnt):
        cnt = cnt.reshape(-1, 2)
        center = (center_x_position(cnt), center_y_position(cnt))
        # Check to make sure a similar contour hasn't been added
        addToLists = 1
        for (index, centerPosition) in enumerate(centerPositions):
            distance = calculate_distance(centerPosition, center)
            oldArea = cv2.contourArea(squares[index])
            # Replace old square with larger square if possible
            if distance < distanceThreshold and cntArea > oldArea:
                squares.pop(index)
                centerPositions.pop(index)
            elif distance < distanceThreshold:
                addToLists = 0
        if addToLists:
            # Shift down for original image and then append to list
            for corner in cnt:
                corner[1] += rowShift
            squares.append(cnt)
            centerPositions.append(center)

## Divide Keys Detected into Rows ##
# Sort by square center Y-coordinate to get keys ordered into "pseudo-rows" 
squares.sort(key=center_y_position, reverse=False)
# Divide square centered around common baseline into rows representing the keyboard
rows = [[]]
currentRow = 0
currentRowBaseY = center_y_position(squares[0])
for square in squares:
    currSquareY = center_y_position(square)
    if np.abs(currSquareY - currentRowBaseY) > rowBaselineThreshold:
        currentRowBaseY = currSquareY
        rows.append([])
        currentRow = currentRow + 1
    rows[currentRow].append(square)
    rows[currentRow].sort(key=center_x_position, reverse=False)
# Combine rows back together in proper order
squares = rows[0] + rows[1] + rows[2] + rows[3] + rows[4]
if len(rows[0]) != 14:
    squares.reverse()

## Draw The Keys with Labels and Print Areas ##
for key in range(0, len(squares)):
    square = squares[key]
    # Calculate Key Centers
    center = (center_x_position(square), center_y_position(square))
    # Print Key Location
    print("'" + KEY_MAP[key] + "'" + " is at (" + str(center[0]) + ", " + str(center[1]) + ")")
    # Caclulate Text Position
    textSize, _ = cv2.getTextSize(KEY_MAP[key],fontFamily, fontSize,fontThickness)
    textXposition = int(center[0] - textSize[0] / 2)
    textYposition = int(center[1] + textSize[1] / 2)
    # Draw Squares and Text on Image
    cv2.drawContours(rotatedFrame, [square], -1, (0,255,0), 2)
    cv2.putText(rotatedFrame, KEY_MAP[key], (textXposition, textYposition), fontFamily, fontSize, (0, 0, 255), fontThickness, cv2.LINE_AA)

## Show Final Image Result ##
cv2.imshow('Original with labeled keys', rotatedFrame)
if cv2.waitKey(0) & 0xff == 27:
    cv2.destroyAllWindows()

