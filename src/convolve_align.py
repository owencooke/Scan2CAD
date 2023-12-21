import os

import torch 
import torch.nn.functional as F
import numpy as np 
import cv2
from src.utils import check_url

def read_img(dir, name):
    img = cv2.imread(check_url(dir) + "/" + name)
    return img

def scale_img(img, SCALE_FACTOR):
    width = img.shape[1] // SCALE_FACTOR 
    height = img.shape[0] // SCALE_FACTOR
    img_scaled = cv2.resize(img, (width, height), interpolation = cv2.INTER_AREA)
    img = img[:, :, ::-1]
    img_scaled = img_scaled[:,:,::-1]
    return img_scaled
# "C:\Users\LimdaLaptop\Documents\SMART\images\NoAxisTif_0kg_Notch_FFcorr_nowhite\1.tif"
# shape [h, w, c]

def cos_sim(img_scaled, kernel_raw):
    with torch.no_grad():
        # preprocessing the data

        # 4 dimensional of (1, 3, 1, 1)
        broadcaster = np.ones((1, 3))[:, :, None, None]

        # original kernel_raw size: (44, 40, 3) (W,H,RGB)
        # new kernel_raw (1, 3, 44, 40) * broadcaster (1, 3, 1, 1) => 
        # kernel (1, 3, 44, 40)
        kernel = np.moveaxis(kernel_raw, -1, 0)[None, :, :, :] * broadcaster

        # img_scaled (W, H, RGB)
        # new img_scaled (RGB, W, H) => (1, RGB, W, H)
        input_img = torch.from_numpy(img_scaled.copy()).permute(2, 0, 1)[None, :, :, :].float()

        # convert to float 
        kernel_t = torch.from_numpy(kernel).float()

        # conv2d: (N, C/RGB, H, W) (N: in channel is 1 dimentional), does computation
        # across the image, other words, dot product between input_img and kernel
        uxv = F.conv2d(input_img, kernel_t, padding="same")

        # Getting scalar of the test image, requires convolution because we want value at all the spots
        uxu = input_img * input_img
        # convolute with (1, 3, W, H) of ones to direct multiplication, result in matrix
        uxu = F.conv2d(uxu, 
                        torch.ones(1, 3, kernel_raw.shape[0], kernel_raw.shape[1]),padding='same')
        uxu = torch.sqrt(uxu) 

        # getting scalar of kernel, does not need convolution since it is the same
        # all the time
        vxv = torch.from_numpy(kernel_raw)
        vxv = (vxv * vxv).sum()
        vxv = torch.sqrt(vxv) 

        # cosine similarity
        output =  uxv / (uxu * vxv)

    # convert back to original image format 
    feature_map = output[0].permute(1,2,0).detach().numpy()

    idx = np.argmax(feature_map.flatten())

    w = feature_map.shape[1]
    col = idx % w  
    row = (idx - col) // w

    return (col,row)

def align(dir, kernal_dir):
    SCALE_FACTOR = 8 # divice everything (image and kernel) by 8

    kernel_raw = np.load(kernal_dir)
    
    all_img = [x[:-4] for x in os.listdir(check_url(dir))]
    all_img = [int(x) for x in all_img]
    all_img = sorted(all_img)

    img = read_img(dir, "{}.tif".format(all_img[0]))
    scaled_img = scale_img(img, SCALE_FACTOR)
    _, prev_y = cos_sim(scaled_img, kernel_raw)
    translation = 0
    num_rows, num_cols = img.shape[:2]   
    os.mkdir(os.path.join(os.getcwd(), 'resultedImg'))

    for i in range(1, len(all_img)+1):
        img2 = read_img(dir, "{}.tif".format(all_img[i]))
        scaled_img = scale_img(img2, SCALE_FACTOR)
        x, y = cos_sim(scaled_img, kernel_raw)
        translation = prev_y - y

        translation_matrix = np.float32([ [1,0,0], [0,1,translation*SCALE_FACTOR] ])   
        img_translation = cv2.warpAffine(img2, translation_matrix, (num_cols, num_rows))
        
        cv2.imwrite("resultedImg/new_img{}.jpg".format(i), img_translation) 