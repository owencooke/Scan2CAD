import numpy as np
import trimesh
from PySide6.QtQml import QmlElement
from PySide6.QtQuick3D import QQuick3DGeometry
from PySide6.QtGui import QVector3D, QMatrix4x4
from PySide6.QtCore import Property, Signal, Slot, QThreadPool
from backend_utils import Thread, check_url, qmatrix4x4_to_np

QML_IMPORT_NAME = "Mesh"
QML_IMPORT_MAJOR_VERSION = 1

''' Custom mesh geometry for loading triangle meshes into
a QtQuick3D scene '''
@QmlElement
class Mesh(QQuick3DGeometry):
    loaded = Signal(QVector3D, QVector3D)
    centroidCorrect = Signal(QVector3D)

    def __init__(self):
        QQuick3DGeometry.__init__(self)
        FLOAT_SIZE = 4
        stride = 3
        self.setStride(stride * FLOAT_SIZE)

        self.threadpool = QThreadPool()
        self.threadpool.setExpiryTimeout(1)

    # Generate the depth map between Scan and CAD
    @Slot(str)
    def load_file(self, file):
        thread = Thread(self.load_data, check_url(file))
        self.threadpool.start(thread)

    @Slot(QMatrix4x4, QMatrix4x4)
    def transform(self,init_mat, t_mat):
        self.mesh.apply_transform(qmatrix4x4_to_np(init_mat))
        self.mesh.apply_transform(qmatrix4x4_to_np(t_mat))
       
        self.vertices = self.mesh.vertices
        self.update_data()

    def update_data(self):
        # Get all face-vertex combos
        ord_verts = self.vertices[self.faces]

        # Pass vertex data to byte stream
        self.setVertexData(ord_verts.astype(np.float32).tobytes())

        # Add attribute descriptors for data
        self.addAttribute(
            # Position (x,y,z)
            QQuick3DGeometry.Attribute.PositionSemantic, 0, QQuick3DGeometry.Attribute.F32Type
        )

        # Update model in GUI
        self.update()

    def load_data(self, file):
        self.clear()
        self.update()

        # Load new data from user input
        mesh = trimesh.load(file, force='mesh')
        self.vertices = mesh.vertices
        self.faces = mesh.faces

        # Update the vertex data
        self.update_data()
        
        self.centroid = mesh.centroid
        self.extents = mesh.extents

        self.loaded.emit(QVector3D(*mesh.centroid),
                        QVector3D(*mesh.extents)
        )

        self.mesh = mesh