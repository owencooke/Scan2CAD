import os
from pathlib import Path
import sys
# Pyside6 Imports for Qt
from PySide6.QtGui import QIcon, QMatrix4x4, QVector3D
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Signal, Slot, QRunnable, QThreadPool, QThread
# Import backend method bodies and Classes
from _compare2D import crop_faces, match_contours
from _align3D import load3D, align_scan
from _depth_map import PointCloud


''' For functions in the Backend class that can have a long
run time. This class runs functions in a separate Python thread than the one
running the main GUI, so that the GUI does not freeze. '''
class Thread(QRunnable):
    def __init__(self, function, *args, **kwargs):
        super(Thread, self).__init__()
        self.function = function
        self.args = args
        self.kwargs = kwargs

    def run(self):
        self.function(*self.args, **self.kwargs)

class Worker(QObject):
    def __init__(self, function, *args, **kwargs):
        super(Worker, self).__init__()
        self.function = function
        self.args = args
        self.kwargs = kwargs

    finished = Signal()

    def run(self):
        self.function(*self.args, **self.kwargs)
        self.finished.emit()

''' Class containing all of the Python backend functions for the GUI.
Contains the following types of attributes/methods:
    Signals: emits data from Python to QML, must be connected to on QML side
    Slots: a Python function called from QML using "backend.function()". '''
class Backend(QObject):
    def __init__(self, basedir, engine):
        super().__init__()
        self.basedir = basedir
        self.engine = engine
        self.threadpool = QThreadPool()
        self.threadpool.setExpiryTimeout(1)

    # Get rid of QML's "file:///" prefix for urls
    def check_url(self, file):
        s_list = file.split('file:///')
        return s_list[-1]

    # ------------------------------------------------------------------#
    # Signals: (from Python to QML)
    # Corresponding signal handler in QML is "onSignalname". First letter
    # after "on" is capitalized where "signalname" is the same as vars below
    # ------------------------------------------------------------------#
    convertedMesh = Signal(str, bool, QVector3D, QVector3D)

    displayCrop = Signal()
    iterateContour = Signal(int, float)
    contourResult = Signal(float, float)

    displayAligned = Signal(QVector3D, float, float)

    # ------------------------------------------------------------------#
    # Slots: (from QML to Python)
    # The backend functions ran after clicking buttons, etc.
    # Run in threadpool to avoid GUI freezing 
    # ------------------------------------------------------------------#
    @Slot()
    def clear_cache(self):
        self.engine.clearComponentCache()

    # @Slot()
    # def cancel_loading(self):
    #     self.thread.requestInterruption()

    # Load model into the 3D viewer or Align page of GUI
    @Slot(str, str, bool)
    def load_mesh(self, QMLpage, file, scanFlag):
        thread = Thread(load3D, self, QMLpage, file, scanFlag)
        self.threadpool.start(thread)
        # self.thread = QThread()
        # self.worker = Worker(load3D, self, QMLpage, file, scanFlag)
        # self.worker.moveToThread(self.thread)
        # self.worker.finished.connect(self.thread.quit)
        # self.thread.started.connect(self.worker.run)
        # self.thread.start()

    # Run the ICP alignment algorithm for aligning Scan to CAD
    @Slot(str, str, QMatrix4x4, QMatrix4x4, bool, int, int)
    def align_meshes(self, cad, scan, cadMatrix, scanMatrix, scale, samples, iters):
        thread = Thread(align_scan, self, cad, scan, cadMatrix, scanMatrix, scale, samples, iters)
        self.threadpool.start(thread)
    
    # Generate the depth map between Scan and CAD
    @Slot(PointCloud, str, str, int, float, float, float)
    def depth_map(self, cloud, cad_file, scan_file, samples, mtch, min, max):
        # Reset cloud to empty in GUI
        cloud.clear()
        cloud.update()
        # Calculate new depth map and display
        thread = Thread(cloud.get_points, self.check_url(cad_file),
                            self.check_url(scan_file), samples, mtch, min, max)
        self.threadpool.start(thread)

    # Automatic image capture and display of the 6 sides of 3D model
    @Slot(str, bool, bool)
    def crop2D(self, theme, cad, scan):
        file_list = []
        dir = os.path.join(self.basedir, 'backend_resources/captured_imgs/')
        # Determine which files are to be cropped
        if cad:
            file_list += [dir+"cad_front.png", dir+"cad_top.png", dir+"cad_left.png",
                            dir+"cad_rear.png", dir+"cad_bottom.png", dir+"cad_right.png"]
        if scan: 
            file_list += [dir+"scan_front.png", dir+"scan_top.png", dir+"scan_left.png",
                            dir+"scan_rear.png", dir+"scan_bottom.png", dir+"scan_right.png"]
        thread = Thread(crop_faces, self, theme, file_list)
        self.threadpool.start(thread)

    # Compare two images based on their detected contours
    @Slot(str, str)
    def compare_contours(self, cad_img, scan_img):
        thread = Thread(match_contours, self, cad_img, scan_img)
        self.threadpool.start(thread)


if __name__ == "__main__":
    # Init
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()
    basedir = os.path.dirname(__file__)

    # Set app icon and environment variables
    try:
        from ctypes import windll  # Only exists on Windows.
        myappid = 'LIMDA.GUI.2022.v1.0'
        windll.shell32.SetCurrentProcessExplicitAppUserModelID(myappid)
    except ImportError:
        pass
    app.setWindowIcon(QIcon(os.path.join(basedir, 'backend_resources/icons/limda_icon.png')))
    os.environ["QSG_RHI_BACKEND"] = "opengl"

    # Connect Python Backend class to QML frontend
    backend = Backend(basedir, engine)
    engine.rootContext().setContextProperty("backend", backend)

    # Load main QML file and begin event loop
    engine.load(os.fspath(Path(__file__).resolve().parent / "main.qml"))
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())
