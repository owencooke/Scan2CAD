import numpy as np
from PySide6.QtCore import QRunnable
from PySide6.QtGui import QVector4D, QMatrix4x4
from trimesh.transformations import quaternion_from_matrix # decompose_matrix

''' For functions in the Backend class that can have a long
run time. This class runs functions in a separate Python thread than the one
running the main GUI, so that the GUI does not freeze. '''
class Thread(QRunnable):
    def __init__(self, function, *args, **kwargs):
        super(Thread, self).__init__()
        self.function = function
        self.args = args
        self.kwargs = kwargs

    def run(self):
        self.function(*self.args, **self.kwargs)

''' END OF THREAD CLASS'''


# Get rid of QML's "file:///" prefix for urls
def check_url(file):
    s_list = file.split('file:///')
    return s_list[-1]

# Convert GUI matrix from QMatrix4x4 type to a numpy array
def qmatrix4x4_to_np(q_mat):
    return np.array(q_mat.copyDataTo()).reshape(4,4)

# Convert numpy array to GUI's QMatrix4x4 type
def np_to_qmatrix4x4(np_mat):
    q_mat = QMatrix4x4()
    for i in range(4):
        # Unpack numpy row into a 4D vector
        row = QVector4D(*np_mat[i])
        # Set 4D vector to QMatrix row
        q_mat.setRow(i, row)
    return q_mat

# Converts rotation matrix into its ZXY euler angles
def euler_from_rotation(r):
    ''' Pseudo code obtained from:
    David Eberly, Geometric Tools, Redmond WA 98052
    https://www.geometrictools.com/Documentation/EulerAngles.pdf '''

    if r[2,1] < 1:
        if r[2,1] > -1:
            e_x = np.arcsin(r[2,1])
            e_z = np.arctan2(-r[0,1], r[1,1])
            e_y = np.arctan2(-r[2,0], r[2,2])
        else:
            e_x = -np.pi/2
            e_z = -np.arctan2(r[0,2], r[0,0])
            e_y = 0
    else:
        e_x = np.pi/2
        e_z = np.arctan2(r[0,2], r[0,0])
        e_y = 0
    
    return (np.array([e_x, e_y, e_z])) * 180 / np.pi

# Decompose a 4x4 transformation matrix into its scale
def scale_from_matrix(mat):
    scale = []
    for i in range(3):
        scale.append(np.linalg.norm(mat[:3, i]))
    return np.array(scale)

# Decompose a 4x4 transformation matrix into scale, translation, rotation
def split_t_matrix(mat):
    # Extract translation vector
    translation = mat[:3, 3].copy()
    mat[:3, 3] = 0

    # Scale vector is the normal of first 3 columns
    scale = []
    for i in range(3):
        scale.append(np.linalg.norm(mat[:3, i]))
        # Normalize columns to eliminate scale from rotation
        mat[:, i] = np.divide(mat[:, i], scale[i])

    # Get rotation quaternion
    rotation = quaternion_from_matrix(mat, isprecise=True)

    return scale, rotation, translation
