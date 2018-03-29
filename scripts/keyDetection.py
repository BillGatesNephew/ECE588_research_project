import cv2
import numpy as np 
from math import sqrt

KEY_MAP = [
    # First Row
    "`", "1", "2", "3", "4","5","6","7","8","9","0","-","=", "DELETE",
    # Second Row
    "TAB", "Q", "W","E","R","T","Y","U","I","O","P","[","]","\\",
    # Third Row
    "CAPS_LOCK", "A", "S","D","F","G","H","J","K","L",";","'","RETURN",
    # Fourth ROW
    "SHIFT_LEFT","Z","X","C","V","B","N","M",",",".","/","SHIFT_RIGHT",
    "FN","CTRL","ALT","CMD","SPACE","CMD","ALT","ARROWS"
]

# Read in the Image
f1 = 'key4.JPG'
originalImage = cv2.imread(f1)
resizedImage = cv2.resize(originalImage, (0,0), fx=0.4, fy=0.4) 

imageKeyArea = 4000

# Convert to Grayscale and apply thresholding
grayImage = cv2.cvtColor(resizedImage, cv2.COLOR_BGR2GRAY)
_, binaryImage = cv2.threshold(grayImage, 127, 255, cv2.THRESH_BINARY_INV)

## Detect Squares in Image ##
# Helper Functions
def angle_cos(p0, p1, p2):
    d1, d2 = (p0-p1).astype('float'), (p2-p1).astype('float')
    return abs( np.dot(d1, d2) / np.sqrt( np.dot(d1, d1)*np.dot(d2, d2) ) )

def calculate_distance(center1, center2):
    xDiff = center1[0] - center2[0]
    yDiff = center1[1] - center2[1]
    return sqrt(xDiff*xDiff + yDiff*yDiff)
# Square Detection
img = cv2.GaussianBlur(binaryImage, (5, 5), 0)
squares = []
centerPositions = []
distanceThreshold = 50
for gray in cv2.split(img):
    for thrs in range(0, 255, 26):
        if thrs == 0:
            bin = cv2.Canny(gray, 0, 50, apertureSize=5)
            bin = cv2.dilate(bin, None)
        else:
            _retval, bin = cv2.threshold(gray, thrs, 255, cv2.THRESH_BINARY)
        bin, contours, _hierarchy = cv2.findContours(bin, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
        for cnt in contours:
            cnt_len = cv2.arcLength(cnt, True)
            cnt = cv2.approxPolyDP(cnt, 0.02*cnt_len, True)
            if len(cnt) == 4 and cv2.contourArea(cnt) > imageKeyArea and cv2.isContourConvex(cnt):
                cnt = cnt.reshape(-1, 2)
                max_cos = np.max([angle_cos( cnt[i], cnt[(i+1) % 4], cnt[(i+2) % 4] ) for i in range(4)])
                # Check to make sure a similar contour hasn't been added
                moment = cv2.moments(cnt)
                center = [int(moment["m10"] / moment["m00"]), int(moment["m01"] / moment["m00"])]
                addToLists = 1
                for centerPosition in centerPositions:
                    distance = calculate_distance(centerPosition, center)
                    if distance < distanceThreshold:
                        addToLists = 0
                if addToLists:
                    squares.append(cnt)
                    centerPositions.append(center)

## Organize the Center Positions ##
def sort_keys_x(square):
    moment = cv2.moments(square)
    return int(moment["m10"] / moment["m00"])

def sort_keys_y(square):
    moment = cv2.moments(square)
    return int(moment["m01"] / moment["m00"])


# Divides positions into keys on each row
squares.sort(key=sort_keys_y, reverse=False)
firstRowSquares = squares[0:14]
secondRowSquares = squares[14:28]
thirdRowSquares = squares[28:41]
fourthRowSquares = squares[41:53]
fifthRowSquares = squares[53:61]

# Sorts the keys on each individual row
firstRowSquares.sort(key=sort_keys_x, reverse=False)
secondRowSquares.sort(key=sort_keys_x, reverse=False)
thirdRowSquares.sort(key=sort_keys_x, reverse=False)
fourthRowSquares.sort(key=sort_keys_x, reverse=False)
fifthRowSquares.sort(key=sort_keys_x, reverse=False)

# Combine results together
squares = firstRowSquares + secondRowSquares + thirdRowSquares + fourthRowSquares + fifthRowSquares

## Draw The Keys with Labels ##
fontSize = 0.6
fontFamily = cv2.FONT_HERSHEY_SIMPLEX
fontThickness = 2
for key in range(0, len(squares)):
    square = squares[key]
    # Calculate Key Centers
    moment = cv2.moments(square)
    centerPosition = [int(moment["m10"] / moment["m00"]), int(moment["m01"] / moment["m00"])]
    # Caclulate Text Position
    textSize, _ = cv2.getTextSize(KEY_MAP[key],fontFamily, fontSize,fontThickness)
    textXposition = int(centerPosition[0] - textSize[0] / 2)
    textYposition = int(centerPosition[1] + textSize[1] / 2)
    # Draw Squares and Text on Image
    cv2.drawContours(resizedImage, [square], -1, (0,255,0), 2)
    cv2.putText(resizedImage, KEY_MAP[key], (textXposition, textYposition), fontFamily, fontSize, (0, 0, 255), fontThickness, cv2.LINE_AA)

# Show Final Result
cv2.imshow('final', resizedImage)
if cv2.waitKey(0) & 0xff == 27:
    cv2.destroyAllWindows()

