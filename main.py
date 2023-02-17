import os
import sys
# Pyside6 Imports for Qt
from PySide6.QtGui import QIcon, QMatrix4x4
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Signal, Slot, QThreadPool
# Import backend method bodies and Classes
from _align3D import align_scan, repair_mesh
from _depth_map import PointCloud
from _mesh import Mesh
from backend_utils import Thread


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

    # ------------------------------------------------------------------#
    # Signals: (from Python to QML)
    # Corresponding signal handler in QML is "onSignalname". First letter
    # after "on" is capitalized where "signalname" is the same as vars below
    aligned = Signal(QMatrix4x4)
    threadComplete = Signal()

    # ------------------------------------------------------------------#
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
        thread = Thread(align_scan, self, cad, scan, cad_mat, scan_mat, scale, samples, iters)
        self.threadpool.start(thread)

    @Slot(str, str, QMatrix4x4, QMatrix4x4, int, float)
    def repair(self, cad_file, scan_file, cad_mat, scan_mat, samples, thresh):
        thread = Thread(repair_mesh, self, cad_file, scan_file, cad_mat, scan_mat, samples, thresh)
        self.threadpool.start(thread)


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
    app.setWindowIcon(QIcon(os.path.join(basedir, 'backend_resources/icons/limda_icon.png')))

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
