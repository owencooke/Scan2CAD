import cv2
import os
import time
""" Takes a list of image filepath strings as an input argument.
The GUI crops the 2D perspective face images stored in Resources/model_faces,
obtained from the model loaded in by the user after running the program """
def cropFaces(basedir, images):
    time.sleep(2)
    for file in images:
        splitPath = file.split('/') # [1].split('.')[0]
        filename = splitPath[len(splitPath)-1].split('.')[0]
        # Load and convert to Grayscale
        img = cv2.imread(file)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        # Remove noise and apply Canny edge detection
        gray = cv2.GaussianBlur(gray,(3,3),0)
        edge = cv2.Canny(gray, 10, 250)
        # Get contours
        contours, hier = cv2.findContours(edge.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        # Find biggest contour (to crop/focus on model)
        area = 0
        for c in contours:
            c_area = cv2.contourArea(c)
            if c_area > area:
                x,y,w,h = cv2.boundingRect(c)     
        crop = img[y-round(h/10):y+h+round(h/10),x-round(h/10):x+w+round(h/10)]
        cv2.imshow('0', crop)
        cv2.waitKey()
        cv2.destroyAllWindows()  
        cv2.imwrite(os.path.join(basedir,'backend_resources/cropped/'+ filename + '.png'), crop)

# Debugging:
if __name__ == "__main__":
    f = "backend_resources/model_faces/"
    cropFaces([f+"front.png", f+"top.png", f+"left.png"])