# External Python dependencies
import os
import sys
import time
import numpy as np
from trimesh.registration import mesh_other

# Pyside6 Imports for interfacing with Qt
from PySide6.QtGui import QIcon, QMatrix4x4
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Signal, Slot, QThreadPool

# Comparison/extraction imports
from src.extract_features import RepairExtractor
from src.utils import Thread, np_to_qmatrix4x4, qmatrix4x4_to_np, trimesh_from_url

# QML Custom Geometry imports
# NOTE: not used directly here, but must be imported for use in QML files
from src.qml_geometry.cloud import PointCloud
from src.qml_geometry.mesh import Mesh


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

    # Signals: (from Python to QML)
    # Corresponding signal handler in QML is "onSignalname". First letter
    # after "on" is capitalized where "signalname" is the same as vars below
    aligned = Signal(QMatrix4x4)
    threadComplete = Signal()

    # -----------------------------------------------------------------------#

    # Slots: (from QML to Python)
    # The backend functions ran after clicking buttons, etc.
    # Run in threadpool to avoid GUI freezing 
    @Slot()
    def clear_cache(self):
        self.engine.clearComponentCache()

    @Slot(result=str)
    def get_basedir(self):
        return self.basedir

    # Run the ICP alignment algorithm for aligning Scan to CAD
    @Slot(str, str, QMatrix4x4, QMatrix4x4, bool, int, int)
    def align_meshes(self, cad, scan, cad_mat, scan_mat, scale, samples, iters):
        # align_scan(self, cad, scan, cad_mat, scan_mat, scale, samples, iters)
        thread = Thread(self.align_scan, cad, scan, cad_mat, scan_mat, scale, samples, iters)
        self.threadpool.start(thread)

    @Slot(str, str, QMatrix4x4, QMatrix4x4, int, float)
    def repair(self, cad_file, scan_file, cad_mat, scan_mat, samples, thresh):
        thread = Thread(self.repair_mesh, cad_file, scan_file, cad_mat, scan_mat, samples, thresh)
        self.threadpool.start(thread)

    # -----------------------------------------------------------------------#

    # Backend functions (for mesh comparison)

    # Run ICP alignment algorithm between two meshes, output to GUI
    def align_scan(self, cad_url, scan_url, cad_mat, scan_mat, scale, samples, iters):
        # Load each file into trimesh
        cad = trimesh_from_url(cad_url, cad_mat)
        scan = trimesh_from_url(scan_url, scan_mat)

        # # # DEBUG
        # scan.visual.vertex_colors = trimesh.visual.random_color()
        # trimesh.Scene([cad, scan]).show()

        # Check inputs for errors, assign default if error
        #FIXME: fix this on QML side
        if samples <= 0:
            samples = 500
        if iters <= 0:
            iters = 50
            
        # Align scan mesh relative to the model mesh
        t_matrix, cost = mesh_other(scan, cad, samples, scale, icp_final=iters)

        # # DEBUG: show result in Trimesh viewer to verify with GUI result
        # scan.apply_transform(t_matrix)
        # scan.visual.vertex_colors = trimesh.visual.random_color()
        # trimesh.Scene([cad, scan]).show()
        
        # Return transform matrix needed to align ORIGINAL FILE
        t_matrix = np.matmul(t_matrix, qmatrix4x4_to_np(scan_mat))
        self.aligned.emit(np_to_qmatrix4x4(t_matrix))
        self.threadComplete.emit()

    def repair_mesh(self, cad_file, scan_file, cad_mat=QMatrix4x4(), 
                        scan_mat=QMatrix4x4(), samples=300, thresh=0.5, combine=True):
        # Load files into Trimesh objects
        start_time = time.time()
        cad = trimesh_from_url(cad_file, cad_mat)
        scan = trimesh_from_url(scan_file, scan_mat)
        # Extract repair volumes to folder
        driver = RepairExtractor(cad, scan, samples, thresh)
        driver.extract_repairs()
        driver.export_volumes("repair_tests", combine, "stl")
        if self != None:
            self.threadComplete.emit()
        print("--- %s seconds ---" % (time.time() - start_time))


if __name__ == "__main__":
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()
    basedir = os.path.dirname(__file__)

    # Set app icon
    try:
        from ctypes import windll  # Only exists on Windows.
        myappid = 'LIMDA.GUI.2022.v1.0'
        windll.shell32.SetCurrentProcessExplicitAppUserModelID(myappid)
    except ImportError:
        pass
    app.setWindowIcon(QIcon(os.path.join(basedir, 'assets/icons/limda_icon.png')))

    # Force Open-GL 3D backend for runtime point resizing
    os.environ["QSG_RHI_BACKEND"] = "opengl"

    # Connect Python backend to QML frontend
    backend = Backend(basedir, engine)
    engine.rootContext().setContextProperty("backend", backend)

    # Load main QML file and begin event loop
    engine.load(os.path.join(basedir, 'main.qml'))
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())
