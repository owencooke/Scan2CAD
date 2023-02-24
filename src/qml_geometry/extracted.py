import numpy as np
from PySide6.QtQml import QmlElement
from PySide6.QtCore import Slot, QIntList
from PySide6.QtQuick3D import QQuick3DGeometry
from src.utils import trimesh_from_url, submesh
from trimesh.util import concatenate

QML_IMPORT_NAME = "Extracted"
QML_IMPORT_MAJOR_VERSION = 1

FLOAT_SIZE = 4 # bytes --> float32

''' Custom geometry that can be loaded into a Qt Quick 3D scene.
The geometry supports two triangular meshes (one for additive and
one for subtractive featues)'''
@QmlElement
class Extracted(QQuick3DGeometry):
    def __init__(self):
        QQuick3DGeometry.__init__(self)
        stride = 10 # 3 pieces of information (x,y,z)
        self.setStride(stride * FLOAT_SIZE)

    @Slot(str, QIntList, QIntList)
    def load_data(self, fin, over_faces, under_faces):
        self.clear()
        self.update()

        # Load new data from user input
        mesh = trimesh_from_url(fin)
        # over = submesh(mesh, list(over_faces), append=True)
        # under = submesh(mesh, list(under_faces), append=True)
        # mesh = concatenate(over, under)

        # self.vertices = mesh.vertices
        # self.faces = mesh.faces

        # # Get all face-vertex combos
        # verts = self.vertices[self.faces]

        over_color = np.array((255, 13, 13, 255))
        under_color = np.array((30, 38, 145, 255))

        over_data = get_sub_verts(mesh, over_faces, over_color)
        under_data = get_sub_verts(mesh, under_faces, under_color)

        # Pass data to byte stream
        data = np.concatenate((over_data, under_data), dtype=np.float32)
        self.setVertexData(data.tobytes())

        # Add attribute descriptors for data
        self.addAttribute(
            # Position coordinate (x,y,z)
            QQuick3DGeometry.Attribute.PositionSemantic, 0, QQuick3DGeometry.Attribute.F32Type
        )

        self.addAttribute(
            # Color (r,g,b,a)
            QQuick3DGeometry.Attribute.ColorSemantic, 3*FLOAT_SIZE, QQuick3DGeometry.Attribute.F32Type
        )

        self.addAttribute(
            # Normal vector (x,y,z)
            QQuick3DGeometry.Attribute.NormalSemantic, 7*FLOAT_SIZE, QQuick3DGeometry.Attribute.F32Type
        )

        # Update model in GUI
        self.update()


def get_sub_verts(mesh, face_indices, color):
    verts = mesh.vertices[mesh.faces[list(face_indices)]]
    normals = mesh.vertex_normals[mesh.faces[list(face_indices)]]
    verts = np.reshape(verts, (-1, 3))
    normals = np.reshape(normals, (-1, 3))
    colors = np.full((len(verts), len(color)), color)
    return np.concatenate((verts, colors, normals), axis=1, dtype=np.float32)
        