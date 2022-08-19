import numpy as np
from PySide6.QtCore import QRunnable
from PySide6.QtGui import QVector3D, QVector4D, QMatrix4x4, QMatrix3x3, QQuaternion
from trimesh.transformations import euler_from_matrix, quaternion_from_matrix, decompose_matrix

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

def split_t_matrix(np_mat):
    # Extract translation vector
    translation = QVector3D(*np_mat[:,3][0:3])

    # Calculate scale vector (length of first 3 columns)
    normals = []
    for i in range(3):
        normals.append(np.linalg.norm(np_mat[:,i]))
    scale = QVector3D(*normals)

    # Calculate 3x3 rotation matrix
    # rot_mat = QMatrix3x3()
    # for i in range(3):
    #     # Normalize each column's first 3 values and assign vector
    #     column = QVector3D(*np.divide(n[:,i][0:3], normals))
    #     # Add column to the rotation matrix
    #     rot_mat.setColumn(i, column)
    # rotation = QQuaternion.fromRotationMatrix(rot_mat)
    # Create 3x3 normalized rotation matrix
    rot_mat = np.zeros((3,3))
    for i in range(3):
        # Normalize each column's first 3 values
        rot_mat[:,i] = np.divide(np_mat[:,i][0:3], normals[i])
    # Convert rotation matrix to euler angles for GUI
    e_x = np.arctan2(rot_mat[1][2], rot_mat[2][2])
    e_y = np.arctan2(-rot_mat[0][2], np.sqrt(rot_mat[1][2]**2 + rot_mat[2][2]**2))
    e_z = np.arctan2(rot_mat[0][1], rot_mat[0][0])
    # Convert to degrees and store in QVector
    degrees = np.array([e_x, e_y, e_z]) * 180 / np.pi
    eulerRotation = QVector3D(*degrees)
    # #print(eulerRotation)
    # eulerRotation = QVector3D(*np.array(euler_from_matrix(rot_mat)) * 180 / np.pi)
    # quat = quaternion_from_matrix(rot_mat)
    # Output TSR results
    # print(translation)
    # #print(scale)
    # print(np_mat)
    # print(normals)
    # print(rot_mat)
    # #print(eulerRotation)
    # quat = QQuaternion.fromEulerAngles(eulerRotation)
    # q_mat = quat.toRotationMatrix()
    triscale, shear, angles, trans, persp = decompose_matrix(np_mat)
    print(triscale, np.array(angles) * 180 / np.pi, trans, sep='\n')

    return translation, scale, eulerRotation

# if __name__ == "__main__":
#     n = np.array([[1,2,3,4],[5,6,7,8],[9,10,11,12],[0,0,0,1],])
#     split_t_matrix(n)
