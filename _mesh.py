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

    @Slot(QMatrix4x4)
    def transform(self,t_mat):
        points = np.column_stack((self.ord_verts, np.full(len(self.ord_verts), 1))) 
        self.ord_verts = np.dot(qmatrix4x4_to_np(t_mat), points.T).T[:,:3]
        self.update_data()

    def update_data(self):
        # Correct data type
        data = self.ord_verts.astype(np.float32)

        # Pass flat vertex data to byte stream
        self.setVertexData(data.flatten().tobytes())

        # Add attribute descriptors for data
        self.addAttribute(
            # Position (x,y,z)
            QQuick3DGeometry.Attribute.PositionSemantic, 0, QQuick3DGeometry.Attribute.F32Type
        )

        # Update model in GUI
        self.update()

    def load_data(self, file):
        self.clear()

        # Load new data from user input
        mesh = trimesh.load(file, force='mesh')

        # Find triangles extending from each vertex
        ord_verts = np.zeros((len(mesh.faces)*3, 3))
        for face_count, face in enumerate(mesh.faces):
            for vert_count, vert_idx in enumerate(face):
                ord_verts[face_count*3 + vert_count] = mesh.vertices[vert_idx]

        # Update the vertex data
        self.ord_verts = ord_verts
        self.update_data()
        
        self.loaded.emit(QVector3D(*mesh.centroid),
                        QVector3D(*mesh.extents)
        )