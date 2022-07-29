import random
import numpy as np
import trimesh
from PySide6.QtGui import QVector3D
from PySide6.QtQml import QmlElement
from PySide6.QtQuick3D import QQuick3DGeometry

QML_IMPORT_NAME = "PointCloud"
QML_IMPORT_MAJOR_VERSION = 1

@QmlElement
class PointCloud(QQuick3DGeometry):
    def __init__(self, parent=None):
        QQuick3DGeometry.__init__(self, parent)
        self.model = trimesh.load('C:/Users/owenc/Documents/LIMDA/models/cube.stl', force='mesh')
        self.scanned = trimesh.load('C:/Users/owenc/Documents/LIMDA/aligned.glb', force='mesh')
        self.closest, self.colors = self.sort_sampled_vertices(self.model, self.scanned, 10000)
        self.updateData()

    def updateData(self):
        self.clear()
        FLOAT_SIZE = 4
        stride = 3
        self.setStride(stride * FLOAT_SIZE)
        self.setPrimitiveType(QQuick3DGeometry.PrimitiveType.Points)

        # Set points
        self.setVertexData(self.closest.astype('float32').tobytes())
        self.addAttribute(
            QQuick3DGeometry.Attribute.PositionSemantic, 0, QQuick3DGeometry.Attribute.F32Type
        )

        # # Set color for each point
        # self.setIndexData(self.colors.astype('uint32').tobytes())
        # self.addAttribute(
        #     QQuick3DGeometry.Attribute.ColorSemantic, 0, QQuick3DGeometry.Attribute.U32Type
        # )

    def key_points(self, m, count):
        """
        Return a combination of mesh vertices and surface samples
        with vertices chosen by likelihood to be important
        to registation.
        """
        if len(m.vertices) < (count / 2):
            return np.vstack((
                m.vertices,
                m.sample(count - len(m.vertices))))
        else:
            return m.sample(count)

    def getDepthColor(self, index, ambience):
        case = {
            1: (105, 179, 76, ambience),
            2: (172, 179, 52, ambience),
            3: (250, 183, 51, ambience),
            4: (255, 142, 21, ambience),
            5: (255, 78, 17, ambience),
            6: (255, 13, 13, ambience),
        }
        return case[index]

    def sort_sampled_vertices(self, cad, scan, samples=500):
        # Uniform sample scan's vertices/surface
        scan_pts = self.key_points(scan, samples)
        closest, distance, faces = cad.nearest.on_surface(scan_pts)
        # print(closest, distance, sep='\n')
        #CLosest is the closest point on a CAD triangle for each scan's point
        # Distance is the distance to the surface
        # Preallocate array for RGBA colors
        colors = np.zeros((samples, 4), np.uint8)
        # # Determine max and min dist's for thresholds
        max = np.max(distance)
        num_colors = 6
        thresh_level = max / num_colors

        for count, dist in enumerate(distance):
            for i in range(1, num_colors+1):
                if (dist < (thresh_level*i)):
                    colors[count] = np.array(self.getDepthColor(i, 255))
                    break
        
        return closest, colors
        # cad_cloud = trimesh.points.PointCloud(closest, colors)
        # trimesh.Scene([cad_cloud]).show()
        # trimesh.exchange.export.export_mesh(cad_cloud, "cloud.glb", file_type="glb", resolver=None)

if __name__ == "__main__":
    c = PointCloud()
