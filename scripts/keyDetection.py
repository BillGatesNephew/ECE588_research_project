import cv2
import sys 
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
    "SHFT1","Z","X","C","V","B","N","M",",",".","/","SHFT2",
    # Fifth Row
    "FN","CTRL","ALT1","CMD1","SPACE","CMD2","ALT2","ARROWS"
]


## General Parameters
# Name of default video 
defaultVideoName = 'typing_vid.mp4'
# Threshold for how far a square can be off a baseline to be on a different row
rowBaselineThreshold = 20
# Number of final frame windows to show
frameNumber = 4
# Outlier distance threshold
outlier_distance_thresh = 1.1

## Contour Detection Parameters
# Maximum valid size needed for a detected contour to be a key
maxImageKeyArea = 13000  
# Minimum valid size needed for a detected contour to be a key
#minImageKeyArea = 1150
minImageKeyArea = 1000
# Distance between centers of keys to be considered separate contours
distanceThreshold = 10
# Maximum distance between countours in separate frames to be considered the same contour
key_movement_thresh = 5

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

# Calculates the center of the passed in square contour
def get_center(square):
    return (center_x_position(square), center_y_position(square))

# Calculates the area of the contour
def area(square):
    return cv2.contourArea(square)

# Returns the corners for a given contour in the following order:
# [top left, top right, bottom left, bottom right]
def extract_corners(square):
    # Sort by Y-coordinates
    square = sorted(square, key=lambda corner: corner[1], reverse=False)
    # Determine Top Left and Top Right
    if square[0][0] < square[1][0]:
        tl = square[0]
        tr = square[1]
    else:
        tl = square[1]
        tr = square[0]
    # Determine Bottom Left and Bottom Right
    if square[2][0] < square[3][0]:
        bl = square[2]
        br = square[3]
    else:
        bl = square[3]
        br = square[2]
    return [tl, tr, bl, br]


######################################
## Actual Keyboard Detection Script ##
#########################################################################


def get_key_contours(frame):
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
    dilatedCannyImage = cv2.dilate(cannyImage, None, iterations=2)
    #dilatedCannyImage = cannyImage
    # Find contours within the dilated image
    cv2.imshow('binary', dilatedCannyImage)
    _, contours, _ = cv2.findContours(dilatedCannyImage, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
    # Run square detection algorithm
    squares = []
    centerPositions = []
    for cnt in contours:
        # Approximate a polynomial for contour
        cnt_len = 0.03*cv2.arcLength(cnt, True)
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
    
    squares.sort(key=area, reverse=False)
    while len(squares) > 61:
        squares.remove(squares[0])
    ## Remove Keys Not Near Others Using Outlier Method ##
    # Sort squares by Y-coordinate 
    squares.sort(key=center_y_position, reverse=False)
    # Determine interquartile range
    upperQuartile = center_y_position(squares[int(len(squares) * 0.75)])
    lowerQuartile = center_y_position(squares[int(len(squares) * 0.25)])
    iqr = upperQuartile - lowerQuartile
    # Determine outlier thresholds
    lower_outlier_thresh = lowerQuartile - outlier_distance_thresh * iqr
    upper_outlier_thresh = upperQuartile + outlier_distance_thresh * iqr
    # Find Outliers and remove them
    squares_without_outliers = []
    for square in squares:
        yPos = center_y_position(square)
        if yPos < upper_outlier_thresh and yPos > lower_outlier_thresh:
            squares_without_outliers.append(square)
    squares = squares_without_outliers

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
    squares = []
    for row in rows:
        squares += row
    #squares = rows[0] + rows[1] + rows[2] + rows[3] + rows[4]
    if len(rows[0]) != 14:
        squares.reverse()
    return squares


def draw_squares(frame, curr_key_map, key_hidden, hide_keys):
    rotatedFrame = rotate_image(frame, 90)
    #if len(curr_key_map) < 61:
    #    return rotatedFrame
    keys_shown = 61
    ## Draw The Keys with Labels and Create Location Map ##
    for key in curr_key_map:
        if key_hidden[key]:
            keys_shown -= 1
        if hide_keys and key_hidden[key]:
            continue 
        square = curr_key_map[key]
        # Calculate Key Centers
        center = get_center(square)
        # Caclulate Text Position
        textSize, _ = cv2.getTextSize(key, fontFamily, fontSize, fontThickness)
        text_center = (int(center[0] - textSize[0] / 2), int(center[1] + textSize[1] / 2))
        # Draw Squares and Text on Image
        cv2.drawContours(rotatedFrame, [square], -1, (0,255,0), 2)
        if len(curr_key_map) == 61:
            cv2.putText(rotatedFrame, key, text_center, fontFamily, fontSize, (0, 0, 255), fontThickness, cv2.LINE_AA)
    # Write number of keys found
    height, width, _ = rotatedFrame.shape
    text_center = (width // 20, height // 20 )
    textSize, _ = cv2.getTextSize("Keys Detected: " + str(keys_shown), fontFamily, 2*fontSize, fontThickness)
    cv2.putText(rotatedFrame, "Keys Detected: " + str(keys_shown), text_center, fontFamily, 2*fontSize, (0, 255, 0), fontThickness, cv2.LINE_AA)
    return rotatedFrame


def adjusted_key_map(curr_key_map, curr_frame_squares):
    new_key_map = {}
    key_hidden = {}
    ## Initial Case of Empty key_map ##
    if len(curr_key_map) < 61:
        for i in range(0, len(curr_frame_squares)):
            new_key_map[KEY_MAP[i]] = curr_frame_squares[i]
            key_hidden[KEY_MAP[i]] = False
        return new_key_map, key_hidden 
    if len(curr_key_map) == 0:
        return curr_key_map, None 

    # Iterate over every keyboard key
    not_found_keys = []
    found_contours = []
    for key in curr_key_map:
        key_hidden[key] = False
        curr_key_center = get_center(curr_key_map[key])
        new_contour = None
        new_contour_d = 100000
        # Find the contour in the current frame that is closest
        # to the current contour being used for a given key and 
        # has a distance below a certain threshold 
        for square in curr_frame_squares:
            square_center = get_center(square)
            d = calculate_distance(curr_key_center, square_center)
            if d < key_movement_thresh and d < new_contour_d:
                new_contour = square 
                new_contour_d = d
        # If the new contour is found then set it in the new key map,
        # and use its offset to adjust keys that weren't found
        if new_contour is not None:
            new_key_map[key] = new_contour
            found_contours.append(new_contour)
        else:
            not_found_keys.append(key)
            key_hidden[key] = True
            
    # Adjust positions of keys that weren't found
    found_contours.sort(key=center_y_position, reverse=False)
    for lost_key in not_found_keys:
        curr_lost_contour = curr_key_map[lost_key]
        curr_lost_contour_y = center_y_position(curr_key_map[lost_key])
        average_baseline = curr_lost_contour_y
        similar_row_count = 1
        for found_contour in found_contours:
            found_contour_y = center_y_position(found_contour)
            d = np.abs(curr_lost_contour_y - found_contour_y)
            if d < 10: 
                average_baseline += found_contour_y
                similar_row_count += 1
        average_baseline = average_baseline / similar_row_count
        
        y_diff = average_baseline - curr_lost_contour_y

        lost_center = get_center(curr_lost_contour)
        closest_distance = 100000
        x_diff = 0
        y_diff_1 = 0
        for new_key in new_key_map:
            if new_key in not_found_keys:
                continue
            new_center = get_center(new_key_map[new_key])
            d = calculate_distance(lost_center, new_center)
            if d < closest_distance and d < 300 :
                closest_distance = d
                old_center = get_center(curr_key_map[new_key])
                (x_diff, y_diff_1) = (new_center[0] - old_center[0], new_center[1] - old_center[1])

        if similar_row_count <= 4:
            y_diff = y_diff_1
        for i in range(0,4):
            curr_lost_contour[i][0] = curr_lost_contour[i][0] + x_diff
            curr_lost_contour[i][1] = curr_lost_contour[i][1] + y_diff
        found_contours.append(curr_lost_contour)
        new_key_map[lost_key] = curr_lost_contour
    return new_key_map, key_hidden

def print_key_map(key_map):
    print("       Key |   Top Left   |   Top Right  |  Bottom Left | Bottom Right")
    print("-----------------------------------------------------------------------------")
    for key in key_map:
        corners = extract_corners(key_map[key])
        top_left = corners[0]
        top_right = corners[1]
        bottom_left = corners[2]
        bottom_right = corners[3]
        format_tuple = (key, top_left[0], top_left[1], top_right[0], top_right[1], bottom_left[0], bottom_left[1], bottom_right[0], bottom_right[1])
        print(" %9s | [%4d %4d] | [%4d %4d] | [%4d %4d] | [%4d %4d]" % format_tuple)
        
def create_file(frame_number, key_map):
    frame_text = str(frame_number)
    if frame_number < 10:
        frame_text = "0" + frame_text
    if frame_number < 100:
        frame_text = "0" + frame_text
    if frame_number < 1000: 
        frame_text = "0" + frame_text
    new_file = open("../data/key_locations/frame_"+ frame_text +".txt", "w+");
    new_file.write("       Key |   Top Left   |   Top Right  |  Bottom Left | Bottom Right\n")
    new_file.write("-----------------------------------------------------------------------------\n")
    for key in key_map:
        corners = extract_corners(key_map[key])
        top_left = corners[0]
        top_right = corners[1]
        bottom_left = corners[2]
        bottom_right = corners[3]
        format_tuple = (key, top_left[0], top_left[1], top_right[0], top_right[1], bottom_left[0], bottom_left[1], bottom_right[0], bottom_right[1])
        new_file.write(" %9s | [%4d %4d] | [%4d %4d] | [%4d %4d] | [%4d %4d]\n" % format_tuple)
    new_file.close()

## Load and Adjust Initial Video Frame ##
# Get command line args for videoname
if len(sys.argv) < 2:
    videoName = defaultVideoName
else: 
    videoName = sys.argv[1]

# Load in video
cap = cv2.VideoCapture(videoName)

# Play with detected keys
curr_key_map = {}
map_printed = False
curr_frame = 0
while(True):

    more_frames_left, frame = cap.read()
    if not more_frames_left:
        break  
    
    if not map_printed and len(curr_key_map) == 61:
       # print_key_map(curr_key_map)
        map_printed = True

    curr_frame_squares = get_key_contours(frame)
    curr_key_map,key_hidden = adjusted_key_map(curr_key_map, curr_frame_squares)
    imageWithSquares = draw_squares(frame, curr_key_map, key_hidden, False)
    rows,cols,_ = imageWithSquares.shape
    rowShift = (rows * 2) // 3
    imageWithSquares = imageWithSquares[rowShift : rows]
    cv2.imshow('frame', imageWithSquares)

    create_file(curr_frame, curr_key_map)
    curr_frame = curr_frame + 1

    if cv2.waitKey(1) & 0xFF == 27:
        break

cap.release()
cv2.destroyAllWindows()





'''
    What is typed in what video:
        vid_1 - for the bst there is in the house there is no one else there
        vid_2 - For the dog in the hen house there is nothing more relazing than a bone at the end of the day especially for the dog.
        vid_3 - good blues and jazz
        vid_4 - the good dog
        vid_5 - Hello World
        vid_6 - the dog biscuit 
        (unsure) vid_7 - the dg took his

        vid_8 - sappiro is a legend 
        vid_9 - sappiro is a good teachear 
        vid_10 - the food was awesome 
        vid_11 - the biscuit was good
        vid_12 - the ferry was home
        vid_13 - the dog tree 
        vid_14 - the cat took




        for the good



        for the good

            for the good 





'''