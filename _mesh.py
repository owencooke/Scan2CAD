import numpy as np
import trimesh
from PySide6.QtQml import QmlElement
from PySide6.QtQuick3D import QQuick3DGeometry
from PySide6.QtGui import QVector3D
from PySide6.QtCore import Property, Signal, Slot, QThreadPool
from backend_utils import Thread, check_url

QML_IMPORT_NAME = "Mesh"
QML_IMPORT_MAJOR_VERSION = 1

''' Custom mesh geometry for loading triangle meshes into
a QtQuick3D scene '''
@QmlElement
class Mesh(QQuick3DGeometry):
    loaded = Signal(QVector3D, QVector3D)

    def __init__(self):
        QQuick3DGeometry.__init__(self)
        self.setStride(1)
        self.threadpool = QThreadPool()
        self.threadpool.setExpiryTimeout(1)

    # Generate the depth map between Scan and CAD
    @Slot(str)
    def load_file(self, file):
        thread = Thread(self.update_data, check_url(file))
        self.threadpool.start(thread)

    def update_data(self, file):
        # Reset cloud to empty in GUI
        self.clear()
        self.update()

        # Load new data from user input
        mesh = trimesh.load(file, force='mesh')

        # Init custom geometry format
        FLOAT_SIZE = 4
        stride = 3
        self.setStride(stride * FLOAT_SIZE)

        # Find triangles extending from each vertex
        data = np.zeros((len(mesh.faces)*3, 3))
        for face_count, face in enumerate(mesh.faces):
            for vert_count, vert_idx in enumerate(face):
                data[face_count*3 + vert_count] = mesh.vertices[vert_idx]

        # Correct data type
        data = data.astype(np.float32)

        # Pass flat vertex data to byte stream
        self.setVertexData(data.flatten().tobytes())

        # Add attribute descriptors for data
        self.addAttribute(
            # Position (x,y,z)
            QQuick3DGeometry.Attribute.PositionSemantic, 0, QQuick3DGeometry.Attribute.F32Type
        )

        # Update model in GUI
        self.update()
        self.loaded.emit(QVector3D(*mesh.centroid),
                        QVector3D(*mesh.extents)
        )