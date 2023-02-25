import numpy as np
from PySide6.QtQml import QmlElement
from PySide6.QtCore import Slot, QIntList
from PySide6.QtQuick3D import QQuick3DGeometry
from src.utils import trimesh_from_url, submesh, check_url
import trimesh

QML_IMPORT_NAME = "Extracted"
QML_IMPORT_MAJOR_VERSION = 1

FLOAT_SIZE = 4 # bytes --> float32
STRIDE = 3 # pieces of vertex information 

''' Custom geometry that can be loaded into a Qt Quick 3D scene.
The geometry supports two triangular meshes (one for additive and
one for subtractive featues)'''
@QmlElement
class Extracted(QQuick3DGeometry):
    def __init__(self):
        QQuick3DGeometry.__init__(self)
        self.setStride(STRIDE * FLOAT_SIZE)

    @Slot(str, QIntList)
    def load_data(self, fin, face_indices):
        self.clear()
        self.update()

        # Load new data from user input
        mesh = trimesh_from_url(fin)

        # Calculate resulting submesh
        self.mesh = submesh(mesh, list(face_indices), append=True)
        self.mesh.fix_normals()
        trimesh.repair.fix_inversion(self.mesh)

        # Update QML vertex data (must be ordered by TRIANGLE)
        verts = mesh.vertices[mesh.faces[list(face_indices)]]
        data = np.asarray(verts, dtype=np.float32)
        self.setVertexData(data.tobytes())

        self.addAttribute(
            # Position coordinate (x,y,z)
            QQuick3DGeometry.Attribute.PositionSemantic, 0, QQuick3DGeometry.Attribute.F32Type
        )

        # Update model in GUI
        self.update()
        
    @Slot(str)
    def export(self, fout):
        fout = check_url(fout)
        trimesh.exchange.export.export_mesh(self.mesh, fout)