import numpy as np
from PySide6.QtCore import QRunnable
from PySide6.QtGui import QMatrix4x4
from trimesh import load
from trimesh.util import type_named, append_faces

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
    return QMatrix4x4(*np_mat.flatten())

def trimesh_from_url(fname, t_matrix=None):
    # Get rid of QML's "file:///" prefix for urls
    fname = check_url(fname)
    # Load mesh using trimesh.load
    mesh = load(fname, force='mesh')
    # Convert matrix and apply to mesh, if given
    if t_matrix is not None:
        t_matrix = qmatrix4x4_to_np(t_matrix)
        mesh.apply_transform(t_matrix)
    # Return mesh (and dimensions if specified)
    return mesh

# Modified from 
# https://github.com/mikedh/trimesh/blob/b9ef0a8a2434f89f41cca714a7100e78dcf1caeb/trimesh/util.py#L1526
def submesh(mesh,
            faces_sequence,
            repair=True,
            only_watertight=False,
            min_faces=None,
            append=False):
    """
    Return a subset of a mesh.
    Parameters
    ------------
    mesh : Trimesh
        Source mesh to take geometry from
    faces_sequence : sequence (p,) int
        Indexes of mesh.faces
    repair : bool
        Try to make submeshes watertight
    only_watertight : bool
        Only return submeshes which are watertight
    append : bool
        Return a single mesh which has the faces appended,
        if this flag is set, only_watertight is ignored
    Returns
    ---------
    if append : Trimesh object
    else        list of Trimesh objects
    """
    # evaluate generators so we can escape early
    faces_sequence = list(faces_sequence)

    if len(faces_sequence) == 0:
        return []

    # avoid nuking the cache on the original mesh
    original_faces = mesh.faces.view(np.ndarray)
    original_vertices = mesh.vertices.view(np.ndarray)

    faces = []
    vertices = []
    normals = []
    visuals = []

    # for reindexing faces
    mask = np.arange(len(original_vertices))

    for index in faces_sequence:
        # sanitize indices in case they are coming in as a set or tuple
        index = np.asanyarray(index)
        # if len(index) == 0:
        #     # regardless of type empty arrays are useless
        #     continue
        if index.dtype.kind == 'b':
            # if passed a bool with no true continue
            if not index.any():
                continue
            # if fewer faces than minimum
            if min_faces is not None and index.sum() < min_faces:
                continue
        elif min_faces is not None and len(index) < min_faces:
            continue

        current = original_faces[index]
        unique = np.unique(current.reshape(-1))

        # redefine face indices from zero
        mask[unique] = np.arange(len(unique))
        normals.append(mesh.face_normals[index])
        faces.append(mask[current])
        vertices.append(original_vertices[unique])
        visuals.append(mesh.visual.face_subset(index))

    if len(vertices) == 0:
        return np.array([])

    # we use type(mesh) rather than importing Trimesh from base
    # to avoid a circular import
    trimesh_type = type_named(mesh, 'Trimesh')
    if append:
        visual = None
        try:
            visuals = np.array(visuals)
            visual = visuals[0].concatenate(visuals[1:])
        except BaseException:
            pass
        # re-index faces and stack
        vertices, faces = append_faces(vertices, faces)
        appended = trimesh_type(
            vertices=vertices,
            faces=faces,
            face_normals=np.vstack(normals),
            visual=visual,
            process=False)
        return appended
