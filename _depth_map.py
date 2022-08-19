import numpy as np
import trimesh
from PySide6.QtQml import QmlElement
from PySide6.QtQuick3D import QQuick3DGeometry
from PySide6.QtGui import QMatrix4x4
from PySide6.QtCore import Property, Signal, Slot, QThreadPool
from backend_utils import Thread, check_url, qmatrix4x4_to_np

QML_IMPORT_NAME = "DepthMap"
QML_IMPORT_MAJOR_VERSION = 1

RGBA = {
    # Blue to green (under-extruded)
    -6: (30, 38, 145, 255),
    -5: (39, 80, 174, 255),
    -4: (44, 108, 194, 255),
    -3: (53, 150, 223, 255),
    -2: (63, 202, 204, 255),
    -1: (42, 191, 144, 255),
    # Green: Highly Similar (dist ~0)
    0: (19, 78, 19, 255),
    # Green to red (over-extruded)
    1: (105, 179, 76, 255),
    2: (172, 179, 52, 255),
    3: (250, 183, 51, 255),
    4: (255, 142, 21, 255),
    5: (255, 78, 17, 255),
    6: (255, 13, 13, 255),
}

COLORS_PER = int(np.floor(len(RGBA)/2))

''' Custom geometry that can be loaded into a Qt Quick 3D scene.
The geometry is a point cloud that uses colored points to represent
the distance/similarity between two 3D model files. '''
@QmlElement
class PointCloud(QQuick3DGeometry):
    def __init__(self):
        QQuick3DGeometry.__init__(self)
        self.setStride(1)
        self._thresh_model = []
        self.threadpool = QThreadPool()
        self.threadpool.setExpiryTimeout(1)

    threshChanged = Signal()
    cloudCalculated = Signal()

    @Property("QVariantList", notify=threshChanged)
    def thresh_model(self):
        return self._thresh_model

    def update_thresh(self, l):
        self._thresh_model = l
        self.threshChanged.emit()
    
    # Generate the depth map between Scan and CAD
    @Slot(str, QMatrix4x4, str, QMatrix4x4, int, float, float, float)
    def calc_depth(self, cad_file, cad_mat, scan_file, scan_mat, samples, mtch, min, max):
        # Run in thread due to potential for long runtime
        thread = Thread(self.get_points, check_url(cad_file), cad_mat,
                            check_url(scan_file), scan_mat, samples, mtch, min, max)
        self.threadpool.start(thread)

    def get_points(self, cad_file, cad_mat, scan_file, scan_mat, samples, mtch, min, max):
        # Reset cloud to empty in GUI
        self.clear()
        self.update()

        # Load new data from user input
        cad = trimesh.load(cad_file, force='mesh')
        scan = trimesh.load(scan_file, force='mesh')

        # Apply transformation matrices from GUI 
        # trimesh.Scene([cad, scan]).show()
        cad_mat = qmatrix4x4_to_np(cad_mat)
        scan_mat = qmatrix4x4_to_np(scan_mat)
        cad.apply_transform(cad_mat)
        scan.apply_transform(scan_mat)
        # trimesh.Scene([cad, scan]).show()

        # Run vertex comparison algorithm
        pts, colors = self.sort_sampled_vertices(cad, scan, samples, mtch, min, max)

        # # Set centroid to origin and adjust points to centralize final display
        # for i in range (3):
        #     np.subtract(pts[:,i], scan.centroid[i], out=pts[:,i])

        # Init custom geometry format
        FLOAT_SIZE = 4
        stride = 7
        self.setStride(stride * FLOAT_SIZE)
        self.setPrimitiveType(QQuick3DGeometry.PrimitiveType.Points)

        # Combine all vertex information into a single array (1 index per vertex, w/ all info)
        data = np.concatenate((pts, colors), axis=1, dtype='float32')

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
        self.cloudCalculated.emit()

    def sort_sampled_vertices(self, cad, scan, samples, match_thresh, min, max):
        colors = np.zeros((samples, 4), dtype='float32')
        # Sample scan's vertices and surface points
        scan_pts = self.key_points(scan, samples)
        # Find nearest distance from CAD to each scan point sampled
        d = cad.nearest.signed_distance(scan_pts) * -1
        # Determine thresholds for over/under extrusion
        if np.isnan(min):
            neg_thresh = np.min(d) / COLORS_PER
        else: 
            # Under extrusion values are negative
            neg_thresh = -abs(min) / COLORS_PER
        if np.isnan(max):
            pos_thresh = np.max(d) / COLORS_PER
        else:
            pos_thresh = max / COLORS_PER
        # Color each point based on which thresh its dist is in
        for count, dist in enumerate(d):
            # Arb. threshold for "similar"
            if abs(dist) < match_thresh:
                colors[count] = self.get_depth_color(0)
            else: 
                for i in range(1, COLORS_PER+2):
                    # Find closest threshold
                    if neg_thresh*i <= dist and dist <= pos_thresh*i:
                        colors[count] = self.get_depth_color(np.copysign(i-1, dist))
                        break
                # Ensure a color was assigned (ambience should be > 0)
                if colors[count][3] == 0:
                    colors[count] = self.get_depth_color(np.copysign(COLORS_PER, dist))
                
        # Update new threshold values for depth scale
        thresh_list = list(float(pos_thresh*i) for i in range(COLORS_PER, -1, -1))
        thresh_list += list(float(neg_thresh*i) for i in range(1, COLORS_PER + 1))
        self.update_thresh(thresh_list)
        # Return sampled points and their respective colors
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
        