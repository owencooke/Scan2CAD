import numpy as np
import trimesh
from math import copysign
from PySide6.QtQml import QmlElement
from PySide6.QtQuick3D import QQuick3DGeometry
from PySide6.QtCore import QObject, Slot, Property, Signal, QPointFList, QAbstractListModel
from PySide6.QtGui import QLinearGradient, QColor

QML_IMPORT_NAME = "DepthMap"
QML_IMPORT_MAJOR_VERSION = 1

RGBA = {
    # Purple to green
    #6: (57, 30, 148, 255),
    # 6: (29, 39, 145, 255),
    # 5: (0, 55, 165, 255),
    # 4: (33, 84, 238, 255),
    # 3: (55, 150, 223, 255),
    # 2: (71, 210, 204, 255),
    # 1: (42, 245, 152, 255),
    6: (30, 38, 145, 255),
    5: (39, 80, 174, 255),
    4: (44, 108, 194, 255),
    3: (53, 150, 223, 255),
    2: (63, 202, 204, 255), #(35, 109, 110, 255),
    1: (42, 191, 144, 255), #(29, 97, 77, 255),
    # Green: Highly Similar (dist ~0)
    0: (19, 78, 19, 255),
    # Green to red (over-extruded)
    -1: (105, 179, 76, 255),
    -2: (172, 179, 52, 255),
    -3: (250, 183, 51, 255),
    -4: (255, 142, 21, 255),
    -5: (255, 78, 17, 255),
    -6: (255, 13, 13, 255),
}
NUM_COLORS = len(RGBA)

''' Custom geometry that can be loaded into a Qt Quick 3D scene.
The geometry is a point cloud that uses colored points to represent
the distance/similarity between two 3D model files. '''
@QmlElement
class PointCloud(QQuick3DGeometry):
    def __init__(self):
        QQuick3DGeometry.__init__(self)
        self.setStride(1)
        self._thresh_model = [1E-16, 2.4]

    threshChanged = Signal()

    @Property("QVariantList", notify=threshChanged) #"QVariantList"
    def thresh_model(self):
        return self._thresh_model

    def update_thresh(self, l):
        self._thresh_model = l
        self.threshChanged.emit()

    def get_points(self, cad_file, scan_file, samples=10000):
        # Load new data from user input
        self.cad = trimesh.load(cad_file, force='mesh')
        self.scan = trimesh.load(scan_file, force='mesh')

        # Run vertex comparison algorithm
        self.closest, self.colors = self.sort_sampled_vertices(self.cad, self.scan, samples)

        # Init custom geometry format
        FLOAT_SIZE = 4
        stride = 7
        self.setStride(stride * FLOAT_SIZE)
        self.setPrimitiveType(QQuick3DGeometry.PrimitiveType.Points)

        # Combine all vertex information into a single array (1 index per vertex, w/ all info)
        data = np.concatenate((self.closest, self.colors), axis=1, dtype='float32')
        # Pass vertex data to byte stream
        self.setVertexData(data.tobytes())

        # Add attribute descriptors for data
        self.addAttribute(
            # Position (x,y,z)
            QQuick3DGeometry.Attribute.PositionSemantic, 0, QQuick3DGeometry.Attribute.F32Type
        )
        self.addAttribute(
            # Color (r,g,b,a)
            QQuick3DGeometry.Attribute.ColorSemantic, 3*FLOAT_SIZE, QQuick3DGeometry.Attribute.F32Type
        )

        # Update model in GUI
        self.update()

    def sort_sampled_vertices(self, cad, scan, samples):
        # Sample scan's vertices and surface points
        scan_pts = self.key_points(scan, samples)
        # Find nearest distance from CAD to each scan point sampled
        d = cad.nearest.signed_distance(scan_pts)
        colors = np.zeros((samples, 4), dtype='float32')
        min = np.min(d)
        thresh = (np.max(d) - min) / NUM_COLORS
        for count, dist in enumerate(d):
            for i in range(0, round(NUM_COLORS/2)+1):
                # Find closest threshold
                bound = thresh*(i+1/2)
                if (-bound <= dist and dist <= bound):
                    colors[count] = self.get_depth_color(copysign(i, dist))
                    break
            # Ensure a color was assigned (ambience should be > 0)
            if colors[count][3] == 0:
                colors[count] = self.get_depth_color(copysign(i, dist))
                
        # Return the closest CAD points, as well as their threshold colors 
        thresh_list = list(float(min + i*thresh) for i in range(0, NUM_COLORS))
        self.update_thresh(thresh_list)
        return scan_pts, colors

    # from Trimesh's registration.py module
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

    # Getter for constant global colors
    def get_depth_color(self, index):
        return tuple(i/255 for i in RGBA[index])
        