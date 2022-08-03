import numpy as np
import trimesh
from PySide6.QtQml import QmlElement
from PySide6.QtQuick3D import QQuick3DGeometry

QML_IMPORT_NAME = "PointCloud"
QML_IMPORT_MAJOR_VERSION = 1

@QmlElement
class PointCloud(QQuick3DGeometry):
    def __init__(self):
        QQuick3DGeometry.__init__(self)
        self.setStride(1)
        
    def checkURL(self, file):
        s_list = file.split('file:///')
        return s_list[len(s_list) - 1]

    def getPoints(self, cad_file, scan_file, samples=10000):
        # Clear old data
        self.clear()
        print('running')
        # Load new data from user input
        self.cad = trimesh.load(self.checkURL(cad_file), force='mesh')
        self.scan = trimesh.load(self.checkURL(scan_file), force='mesh')

        # Run vertex comparison algorithm
        # Returns closest points on CAD and threshold colors
        self.closest, self.colors = self.sort_sampled_vertices(self.cad, self.scan, samples)

        # Init custom geometry format
        FLOAT_SIZE = 4
        stride = 7
        self.setStride(stride * FLOAT_SIZE)
        self.setPrimitiveType(QQuick3DGeometry.PrimitiveType.Points)

        # Combine all vertex information into a single array (1 index per vertex, w/ all info)
        data = np.concatenate((self.closest, self.colors), axis=1, dtype='float32')

        # Pass data to byte stream
        self.setVertexData(data.tobytes())

        # Add attribute descriptors for data
        ## Position (x,y,z)
        self.addAttribute(
            QQuick3DGeometry.Attribute.PositionSemantic, 0, QQuick3DGeometry.Attribute.F32Type
        )
        ## Color (r,g,b,a)
        self.addAttribute(
            QQuick3DGeometry.Attribute.ColorSemantic, 3*FLOAT_SIZE, QQuick3DGeometry.Attribute.F32Type
        )

        self.update()
        print('done')

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
        # RGB dictionary for dist thresholds
        case = {
            # for each threshold, assign (r,g,b,a)
            1: (19, 78, 19, ambience),
            2: (105, 179, 76, ambience),
            3: (172, 179, 52, ambience),
            4: (250, 183, 51, ambience),
            5: (255, 142, 21, ambience),
            6: (255, 78, 17, ambience),
            7: (255, 13, 13, ambience),
        }
        return tuple(i/255 for i in case[index])

    def sort_sampled_vertices(self, cad, scan, samples):
        # Uniform sample scan's vertices/surface
        scan_pts = self.key_points(scan, samples)
        closest, distance, _ = cad.nearest.on_surface(scan_pts)
        # Preallocate array for RGBA colors
        colors = np.zeros((samples, 4), dtype='float32')
        # Determine thresholds for assigning colors to points
        max = np.max(distance)
        num_colors = 7
        thresh_level = max / num_colors

        for count, dist in enumerate(distance):
            for i in range(1, num_colors+1):
                if (dist < (thresh_level*i)):
                    colors[count] = np.array(self.getDepthColor(i, 255), dtype='float32')
                    break
        
        return closest, colors