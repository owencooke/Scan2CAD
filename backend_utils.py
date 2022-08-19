import numpy as np
from PySide6.QtCore import QRunnable

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
def qmatrix4x4_to_np(qmat):
    # Reset scale from GUI default 
    qmat.scale(1/5)
    return np.array(qmat.copyDataTo()).reshape(4,4)
