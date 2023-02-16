import time
import trimesh
import numpy as np
from PySide6.QtGui import QMatrix4x4
from backend_utils import qmatrix4x4_to_np, trimesh_from_url, np_to_qmatrix4x4
from _repair_volume import RepairExtractor


# Determine output file type/destination
def outFilename(page, scan):
    case = {
        "Model3D": ["cad_model3D", "scan_model3D"],
        "Align": ["cad_align", "scan_align"],
    }
    return case[page][scan]

# Eliminates pieces that have less than a min # of connected components
def tidyUpMesh(mesh, min_len=5000):
    try: 
        cc = trimesh.graph.connected_components(mesh.face_adjacency, min_len)
        mask = np.zeros(len(mesh.faces), dtype=bool)
        mask[np.concatenate(cc)] = True
        mesh.update_faces(mask)
    # No unconnected components found
    except (ValueError, AttributeError):
        pass
    return mesh

# Run ICP alignment algorithm between two meshes, output to GUI
def align_scan(self, cad_url, scan_url, cad_mat, scan_mat, scale, samples, iters):
    # Load each file into trimesh
    cad = trimesh_from_url(cad_url, cad_mat)
    scan = trimesh_from_url(scan_url, scan_mat)

    # # # DEBUG
    # scan.visual.vertex_colors = trimesh.visual.random_color()
    # trimesh.Scene([cad, scan]).show()

    # Check inputs for errors, assign default if error
    if samples <= 0:
        samples = 500
    if iters <= 0:
        iters = 50
        
    # Align scan mesh relative to the model mesh
    t_matrix, cost = trimesh.registration.mesh_other(scan, cad, samples, scale, icp_final=iters)

    # # DEBUG: show result in Trimesh viewer to verify with GUI result
    # scan.apply_transform(t_matrix)
    # scan.visual.vertex_colors = trimesh.visual.random_color()
    # trimesh.Scene([cad, scan]).show()
    
    self.aligned.emit(np_to_qmatrix4x4(t_matrix))

def repair_mesh(self, cad_file, scan_file, cad_mat=QMatrix4x4(), 
                    scan_mat=QMatrix4x4(), samples=100000, thresh=0.5, combine=True):
    # Load files into Trimesh objects
    start_time = time.time()
    cad = trimesh_from_url(cad_file, cad_mat)
    scan = trimesh_from_url(scan_file, scan_mat)
    # Extract repair volumes to folder
    driver = RepairExtractor(cad, scan, samples, thresh)
    driver.extract_repairs()
    driver.export_volumes("test", combine, "stl")
    if self != None:
        self.volumes.emit()
    print("--- %s seconds ---" % (time.time() - start_time))


# Pre-aligned test (no GUI needed) using the case study from the ICRAI paper
if __name__ == "__main__":
    cad = QMatrix4x4(1, 0, 0, -12.5, 0, 1, 0, -12.710657119750977, 0, 0, 1, 12.730606079101562, 0, 0, 0, 1)
    scan = QMatrix4x4(1, 0, 0, 0.20166169106960297, 0, 1, 0, 0.19201700389385223, 0, 0, 1, -12.594476699829102, 0, 0, 0, 1)
    repair_mesh(None, "C:/Users/owenc/Documents/LIMDA/models/cube.stl",
                    "C:/Users/owenc/Documents/LIMDA/models/cube-modified.stl", cad, scan)
    
    # Matrixes to align the two models
    # cad = QMatrix4x4(1, 0, 0, -1.9073486328125e-06, 0, 5.960464477539063e-08, 0.9999999403953552, -13.12500286102295, 0, -0.9999999403953552, 5.960464477539063e-08, -7.823111900506774e-07, 0, 0, 0, 1) 
    # scan = QMatrix4x4(-0.9998733997344971, -0.00261781201697886, 0.015707235783338547, -0.4721300005912781, -0.0026181351859122515, 0.999996542930603, 0, 3.654583692550659, -0.01570718362927437, -4.112366514164023e-05, -0.999876856803894, 0.9400255084037781, 0, 0, 0, 1)
    # repair_mesh(None, "C:/Users/owenc/Documents/LIMDA/ICRAI_results/ideal.stl",
    #                  "C:/Users/owenc/Documents/LIMDA/ICRAI_results/scan.stl", cad, scan, samples=300)