import os
from pathlib import Path
import sys
# Pyside6 Imports for Qt
from PySide6.QtGui import QIcon, QMatrix4x4, QVector3D
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Signal, Slot, QRunnable, QThreadPool
# Imports for Backend functions
import trimesh
import time
import numpy as np
import cv2

# Get base directory and set app ID
basedir = os.path.dirname(__file__)
try:
    from ctypes import windll  # Only exists on Windows.
    myappid = 'LIMDA.GUI.2022.v1.0'
    windll.shell32.SetCurrentProcessExplicitAppUserModelID(myappid)
except ImportError:
    pass

''' 
Purpose: for functions in the Backend class that can have a long
    run time. This class runs functions in a separate thread than the one
    running the main GUI, so that the GUI does not freeze on the user's end.
'''
class Thread(QRunnable):
    def __init__(self, function, *args, **kwargs):
        super(Thread, self).__init__()
        self.function = function
        self.args = args
        self.kwargs = kwargs

    def run(self):
        self.function(*self.args, **self.kwargs)

''' Class containing all of the Python backend functions for the GUI.
Contains the following types of attributes/methods:
    Signals: emits data from Python to QML, must be connected to on QML side
    Slots: a Python function called from QML using "backend.function()"
    Threads: backend functions with long runtime must be called as threads
'''
class Backend(QObject):
    def __init__(self):
        super().__init__()
        self.threadpool = QThreadPool()
        self.threadpool.setExpiryTimeout(1)
        
    # ------------------------------------------------------------------#
    # Signals: (from Python to QML)
    # Corresponding signal handler in QML is "onSignalname". First letter 
    # after "on" is capitalized where "signalname" is the same as variable defined below
    # ------------------------------------------------------------------#
    #FIXME: returning Python lists to QML was complicated, couldn't implement
    convertedMesh = Signal(str, bool, QVector3D, QVector3D)

    captureRotations = Signal(bool, bool)
    displayCrop = Signal()
    contourResult = Signal(float, float)

    displayAligned = Signal(QVector3D, float, float)
    hausdorffOutput = Signal(float, float)

    # ------------------------------------------------------------------#
    # Slots: (from QML to Python)
    # The backend functions ran after clicking buttons, etc.
    # *If function runtime is long, run in seperate thread 
    # ------------------------------------------------------------------#
    # Load model into the 3D viewer page of GUI
    @Slot(str, str, bool)
    def loadMesh(self, QMLpage, selectedFile, scanFlag):
        # Run mesh conversion in seperate thread to prevent freezing GUI
        thread = Thread(self.loadMeshThread, QMLpage, selectedFile, scanFlag)
        self.threadpool.start(thread)

    def loadMeshThread(self, QMLpage, selectedFile, scanFlag):
        # RuntimeLoader only compatible with .glb or .gltf 
        # Also used to obtain centroid and dimensions of models
        loaded = trimesh.load(selectedFile.split('file:///')[1], force='mesh')

        # ELIMINATE SMALL NON-CONNECTED COMPONENTS (errors from scan)
        try: 
            cc = trimesh.graph.connected_components(loaded.face_adjacency, min_len=5000)
            mask = np.zeros(len(loaded.faces), dtype=bool)
            mask[np.concatenate(cc)] = True
            loaded.update_faces(mask)
        except ValueError: # No unconnected components found (healthy scan or model)
            pass

        # Export model for loading in QML (only .glb or .gltf)
        if scanFlag:
            if QMLpage == "Align":
                convFile = "scan_align"
            else:
                convFile = "scan_model3D"
        else:
            if QMLpage == "Align":
                convFile = "cad_align"
            else:
                convFile = "cad_model3D"
        out = os.path.join(basedir, "backend_resources/converted_mesh/" + convFile + ".glb")
        trimesh.exchange.export.export_mesh(loaded, out, file_type="glb")

        # Obtain dimensional parameters/centroid, output results
        l = abs(loaded.bounds[0][0] - loaded.bounds[1][0])
        w = abs(loaded.bounds[0][1] - loaded.bounds[1][1])
        h = abs(loaded.bounds[0][2] - loaded.bounds[1][2])
        dim = QVector3D(l, w, h)

        centroid = QVector3D(loaded.centroid[0], loaded.centroid[1], loaded.centroid[2])

        # Output data to QML
        time.sleep(0.01)
        self.convertedMesh.emit(QMLpage, scanFlag, centroid, dim)

    @Slot(str, str, QMatrix4x4, QMatrix4x4, bool)
    def alignMeshes(self, cad, scan, cadMatrix, scanMatrix, scale):
        thread = Thread(self.alignMeshesThread, cad, scan, cadMatrix, scanMatrix, scale)
        self.threadpool.start(thread)

    def alignMeshesThread(self, cad, scan, cadMatrix, scanMatrix, scale):
        # Load each file into trimesh
        model = trimesh.load(cad.split('file:///')[1], force='mesh')
        scanned = trimesh.load(scan.split('file:///')[1], force='mesh')

        # Apply intial transformation matrices from GUI
        cadMatrix = np.array(cadMatrix.copyDataTo()).reshape(4,4)
        scanMatrix = np.array(scanMatrix.copyDataTo()).reshape(4,4)
        model.apply_transform(cadMatrix)
        scanned.apply_transform(scanMatrix)

        # ELIMINATE SMALL NON-CONNECTED COMPONENTS (errors from scan)
        try: 
            cc = trimesh.graph.connected_components(scanned.face_adjacency, min_len=5000)
            mask = np.zeros(len(scanned.faces), dtype=bool)
            mask[np.concatenate(cc)] = True
            scanned.update_faces(mask)
        except ValueError: # No unconnected components found (healthy scan or model)
            pass

        # Align scan mesh relative to the model mesh, save result to disk
        t_matrix, cost = trimesh.registration.mesh_other(scanned, model, scale=scale) # samples=2000,icp_first=10, icp_final=500)
        scanned.apply_transform(t_matrix)
        # scanned.visual.vertex_colors = trimesh.visual.random_color()
        # trimesh.Scene([model, scanned]).show()
        # Convert and export files to be loaded
        cad = os.path.join(basedir, "backend_resources/converted_mesh/cad_align.glb")
        scan = os.path.join(basedir,"backend_resources/converted_mesh/scan_align.glb")
        trimesh.exchange.export.export_mesh(model, cad, file_type="glb")
        trimesh.exchange.export.export_mesh(scanned, scan, file_type="glb")

        # Calculate joint centroid
        x = (model.centroid[0] + scanned.centroid[0]) / 2
        y = (model.centroid[1] + scanned.centroid[1]) / 2
        z = (model.centroid[2] + scanned.centroid[2]) / 2
        centroid = QVector3D(x,y,z)

        # FIXME: calculate Hausdorff distance here / define similarity
        coeff = 50
        percent = 100/(1 + coeff*cost) #(0.1-cost)*1000 # Approximating percentage function
        if percent < 0: percent = 0

        # Emit signal containing data to QML 
        self.displayAligned.emit(centroid, cost, percent)
    
    @Slot(bool, bool)
    def crop2D(self, cad, scan):
        file_list = []
        dir = os.path.join(basedir, 'backend_resources/captured_imgs/')
        if cad:
            file_list += [dir+"cad_front.png", dir+"cad_top.png", dir+"cad_left.png"]
        if scan: 
            file_list += [dir+"scan_front.png", dir+"scan_top.png", dir+"scan_left.png"]
        thread = Thread(self.cropFaces, basedir, file_list)
        self.threadpool.start(thread)

    def cropFaces(self, basedir, images):
        #FIXME: need to ensure that this function does not run before images exist
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
            # Crop largest contour and export
            crop = img[y-round(h/10):y+h+round(h/10),x-round(h/10):x+w+round(h/10)]
            cv2.imwrite(os.path.join(basedir,'backend_resources/cropped/'+ filename + '.png'), crop)
        self.displayCrop.emit()
    
    @Slot()
    def compareContours(self):
        thread = Thread(self.compareContoursThread)
        self.threadpool.start(thread)
    
    def compareContoursThread(self):
        otherdir = "C:/Users/owenc/Documents/LIMDAqtGUI/backend_resources/cropped/"
        images = [otherdir+'cad_front.png', otherdir+'scan_front.png']
        img0 = cv2.imread(images[0])
        img1 = cv2.imread(images[1])
        # Match image dimensions/aspect ratios
        # FIXME: standardize a height or width for every use
        dim0 = img0.shape
        dim1 = img1.shape
        if dim0[0] < dim1[0] and dim0[1] < dim1[1]:
            # apply dimensions from img0 to img1 
            img1 = cv2.resize(img1, dim0[:2][::-1], interpolation = cv2.INTER_AREA)
        else:
            img0 = cv2.resize(img0, dim1[:2][::-1], interpolation = cv2.INTER_AREA)

        # Get contours of both images
        mod = cv2.cvtColor(img0, cv2.COLOR_BGR2GRAY)
        mod = cv2.GaussianBlur(mod,(3,3),0)
        mod = cv2.Canny(mod, 10, 250)
        model_contour, hier = cv2.findContours(mod, cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)

        mod = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
        mod = cv2.GaussianBlur(mod,(3,3),0)
        mod = cv2.Canny(mod, 10, 250)
        part_contour, hier = cv2.findContours(mod, cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)

        # Attempt to match part's contours to the model's contours
        # Lowest distance from matchShapes() indicates highest similarity
        matches = {}
        low_size = 0.5
        high_size = 4
        dist_thresh = 0.1
        dist_range = dist_thresh*min(img0.shape[0], img0.shape[1])
        m_index = 0
        p_matched = []
        model_area = 0
        i = 0
        mask = np.zeros(img0.shape, dtype='uint8')
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
                if match_idx not in p_matched:
                    p_matched.append(match_idx)

            # Find biggest contour (largest outline of model)
            a = cv2.contourArea(m)
            if a > model_area:
                model_area = a
            m_index += 1
            #FIXME: DEBUGGING, for displaying the contours matched at each step
            try:
                # mask = np.zeros(img0.shape, dtype='uint8')
                cv2.drawContours(mask, m, -1, (255,255,255), 2)
                cv2.drawContours(mask, part_contour[match_idx], -1, (0,0,255), 2)
                cv2.imshow('0', img0)
                cv2.imshow('1', img1)
                cv2.imshow('mask', mask)
                cv2.waitKey()
                cv2.destroyAllWindows()  
                cv2.imwrite('testing/mask' + str(i) + '.png', mask)
                i += 1
            except TypeError:
                pass

        # Sweep initially unmatched part contours to determine if they should be matched
        # or considered to be defects/errors in the final metric
        for p_index in range(0, len(part_contour)):
            if p_index not in p_matched: 
                opdist = 1e10
                m_index = 1e10
                m_count = 0
                for m in model_contour:
                    # THRESHOLD: ONLY COMPARE THOSE SIMILAR IN POSITION/SIZE
                    dx = abs(m[0][0][0] - part_contour[p_index][0][0][0])
                    dy = abs(m[0][0][1] - part_contour[p_index][0][0][1])
                    if (dx < dist_range) and (dy < dist_range) and (high_size*m.size > part_contour[p_index].size > low_size*m.size):
                        dist = cv2.matchShapes(m, part_contour[p_index], cv2.CONTOURS_MATCH_I2, 0)
                        if dist < opdist:
                            opdist = dist
                            m_index = m_count
                    m_count += 1
                # Store as match only if it's optimal distance is low enough (high similarity)
                if m_index != 1e10 and opdist < 0.5:
                    matches[m_index] += [p_index, opdist]
                    p_matched.append(p_index)

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

        # Add error resulting from unmatched part contours
        e_dist = 99 # (~1% using the distance formula)
        err = 0
        for p_index in range(len(part_contour)):
            if p_index not in p_matched:
                # Error: size of contour relative to size of whole image
                err += (cv2.contourArea(part_contour[p_index]) / model_area) * e_dist
        # Add error (higher dist = less similarity)
        #dist += err
        print("Smaller distance means higher similarity: {:.5f}".format(dist))
        print("Percentage Given by 1/(1+dist): {:.3f}%".format(100/(1+dist)))
        self.contourResult.emit(dist, 100/(1+dist))


if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setWindowIcon(QIcon(os.path.join(basedir, 'backend_resources/icons/limda_icon.png')))
    engine = QQmlApplicationEngine()
    # Connect Python Backend class to QML files
    backend = Backend()
    engine.rootContext().setContextProperty("backend", backend)
    # Load main QML file and begin event loop
    engine.load(os.fspath(Path(__file__).resolve().parent / "main.qml"))
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())
