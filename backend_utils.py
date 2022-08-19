import numpy as np
from PySide6.QtCore import QRunnable
from PySide6.QtGui import QVector3D, QVector4D, QMatrix4x4, QMatrix3x3, QQuaternion

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
