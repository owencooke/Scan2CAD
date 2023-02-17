import os
import time
import cv2
import numpy as np
from src.utils import check_url

# Crop auto-captured images from 3D viewer and display
def crop_faces(self, theme, cad, scan, images):
    for file in images:
        splitPath = file.split('/')
        filename = splitPath[-1].split('.')[0]
        # Load and convert to Grayscale
        img = cv2.imread(file)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        # Threshold image to apply transparent background
        if theme == "dark":
            _, alpha = cv2.threshold(gray, 37, 255, cv2.THRESH_BINARY)
        else:
            invert = 255-gray
            _, alpha = cv2.threshold(invert, 232, 255, cv2.THRESH_BINARY)
        img = cv2.cvtColor(img, cv2.COLOR_BGR2BGRA)
        img[:, :, 3] = alpha
        # Remove noise and apply Canny edge detection
        gray = cv2.GaussianBlur(gray,(3,3),0)
        edge = cv2.Canny(gray, 10, 250)
        # Find largest contour (outline of shape)
        contours, _ = cv2.findContours(edge, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        largest = sorted(contours, key=cv2.contourArea)[-1]
        # Crop image and export
        x,y,w,h = cv2.boundingRect(largest)
        crop = img[y-round(h/10):y+h+round(h/10),x-round(h/10):x+w+round(h/10)]
        cv2.imwrite(os.path.join(self.basedir,'assets/_cropped/'+ filename + '.png'), crop)

    self.displayCrop.emit(cad, scan)

# Iteratively match contours between two part images
def match_contours(self, cad_img, scan_img):
    # Load images
    cad_img = os.path.join(self.basedir, check_url(cad_img))
    scan_img = os.path.join(self.basedir, check_url(scan_img))
    img0 = cv2.imread(cad_img)
    img1 = cv2.imread(scan_img)

    dim0 = img0.shape
    dim1 = img1.shape
    if dim0[0] < dim1[0] and dim0[1] < dim1[1]:
        img1 = cv2.resize(img1, dim0[:2][::-1], interpolation = cv2.INTER_AREA)
    else:
        img0 = cv2.resize(img0, dim1[:2][::-1], interpolation = cv2.INTER_AREA)

    # Get contours of both images
    mod = cv2.cvtColor(img0, cv2.COLOR_BGR2GRAY)
    mod = cv2.GaussianBlur(mod,(3,3),0)
    mod = cv2.Canny(mod, 10, 250)
    model_contour, _ = cv2.findContours(mod, cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)

    mod = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
    mod = cv2.GaussianBlur(mod,(3,3),0)
    mod = cv2.Canny(mod, 10, 250)
    part_contour, _ = cv2.findContours(mod, cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)

    # Set parameter values for algorithm
    low_size = 0.5
    high_size = 4
    dist_thresh = 0.1
    dist_range = dist_thresh*min(img0.shape[0], img0.shape[1])
    # Attempt to match part's contours to the model's contours
    # Lowest distance from matchShapes() indicates highest similarity
    matches = {}
    m_index = 0
    d = os.path.join(self.basedir,'assets/_contours/')
    for m in model_contour:
        opdist = 100
        match_idx = 1e10
        p_index = 0
        for p in part_contour:
            # THRESHOLD: ONLY COMPARE THOSE SIMILAR IN POSITION/SIZE
            dx = abs(m[0][0][0] - p[0][0][0])
            dy = abs(m[0][0][1] - p[0][0][1])
            if (dx < dist_range) and (dy < dist_range) and (high_size*m.size > p.size > low_size*m.size):
                dist = cv2.matchShapes(m, p, cv2.CONTOURS_MATCH_I2, 0)
                if dist < opdist:
                    opdist = dist
                    match_idx = p_index
            p_index += 1
        # Store match indices and their optimized distance
        if match_idx != 1e10: # opdist < 3:
            matches[m_index] = [match_idx, opdist]

        # Output contours with transparent bg
        try:
            mask = np.zeros((img0.shape[0], img0.shape[1], 4), img0.dtype)  
            cv2.drawContours(mask, m, -1, (255,255,255,255), 2)
            cv2.drawContours(mask, part_contour[match_idx], -1, (0,0,255,255), 2)
            cv2.imwrite(d + 'mask' + str(m_index) + '.png', mask)
        except TypeError:
            pass
        m_index += 1

    # Calculate average distance of all the quality matches
    dist = 0
    num_dists = 0
    for m_list in matches.values():
        for d in range(1, len(m_list), 2):
            # Apply relative area weighting to the distance
            dist += m_list[d]
            num_dists += 1
    try: dist /= num_dists
    except ZeroDivisionError: dist = 1e10 # Arb. large, no matches

    for c in matches.keys():
        self.iterateContour.emit(c, 100/(1+matches[c][1]))
        time.sleep(0.5)
    self.contourResult.emit(dist, 100/(1+dist))