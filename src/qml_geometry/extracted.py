import numpy as np
from PySide6.QtQml import QmlElement
from PySide6.QtCore import Slot, QIntList
from PySide6.QtQuick3D import QQuick3DGeometry
from src.utils import trimesh_from_url, submesh
from trimesh.util import concatenate

QML_IMPORT_NAME = "Extracted"
QML_IMPORT_MAJOR_VERSION = 1

''' Custom geometry that can be loaded into a Qt Quick 3D scene.
The geometry supports two triangular meshes (one for additive and
one for subtractive featues)'''
@QmlElement
class Extracted(QQuick3DGeometry):
    def __init__(self):
        QQuick3DGeometry.__init__(self)
        FLOAT_SIZE = 4 # bytes --> float32
        stride = 3 # 3 pieces of information (x,y,z)
        self.setStride(stride * FLOAT_SIZE)

    @Slot(str, QIntList, QIntList)
    def load_data(self, fin, over_faces, under_faces):
        self.clear()
        self.update()

        # Load new data from user input
        mesh = trimesh_from_url(fin)
        over = submesh(mesh, list(over_faces), append=True)
        under = submesh(mesh, list(under_faces), append=True)
        mesh = concatenate(over, under)

        self.vertices = mesh.vertices
        self.faces = mesh.faces

        # Update the vertex data
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
