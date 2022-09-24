import trimesh
import numpy as np
import os
from trimesh.util import type_named, append_faces
from _triangles_intersect import faces_intersect

class ErrorSubsets():
    def __init__(self):
        self.scan_set = []
        self.cad_set = []
        self.scan_last = 0
        self.cad_last = 0

    def __iter__(self):
        return zip(self.scan_set, self.cad_set)

    def add_subset(self, scan_faces, cad_faces):
        if len(self.scan_set) == 0:
            # Add face lists
            self.scan_set.append(scan_faces)
            self.cad_set.append(cad_faces)
            # Keep track of length 
            self.scan_last = len(scan_faces)
            self.cad_last = len(cad_faces)
        else:
            # New scan subset
            sub = scan_faces[self.scan_last:]
            self.scan_set.append(sub)
            self.scan_last += len(sub)
            # New cad subset
            self.cad_set.append(cad_faces)


class RepairExtractor():
    def __init__(self, cad, scan, samples, thresh):
        self.cad = cad
        self.scan = scan
        self.samples = samples
        self.thresh = thresh
        self.scan_connected = self.hash_connected_faces(scan)
        self.cad_connected = self.hash_connected_faces(cad)

    # Create connected face hash maps
    def hash_connected_faces(self, mesh):
        cc_hash = {}
        # Iterate through (n,2) array of adjacent faces
        for i, j in trimesh.graph.face_adjacency(mesh=mesh):
            # Add both faces to the others' list
            if i in cc_hash:
                cc_hash[i].append(j)
            else:
                cc_hash[i] = [j]
            if j in cc_hash:
                cc_hash[j].append(i)
            else:
                cc_hash[j] = [i]
        return cc_hash

    def extract_repairs(self):
        # Sample points
        sample_points, faces = self.scan.sample(self.samples, return_index=True)
        dists = self.cad.nearest.signed_distance(sample_points)
        over_faces = []
        under_faces = []
        # Classify points as errors if |d| > thresh
        for idx, d in enumerate(dists):
            if d > self.thresh:
                # Under extruded, store face index
                under_faces.append(faces[idx])
            elif d < -self.thresh: 
                # Over extruded, store face index
                over_faces.append(faces[idx])

        # Create additive/subtractive repair meshes
        self.under_meshes = self.mesh_faces(under_faces)
        self.over_meshes = self.mesh_faces(over_faces)
        
    def mesh_faces(self, init_faces):
        # Recurse thru all faces connected to detected errors
        faces = []
        volume = ErrorSubsets()
        for f in init_faces:
            if f not in faces:
                faces, cad_crossed = self.model_intersect(f, faces, [])
                volume.add_subset(faces, cad_crossed)
    
        # find CAD faces that enclose the scan repair volume
        print(cad_crossed)

        # Iterate through each volume subset
        meshes = []
        for s, c in volume:
            if not c:
                # No CAD faces, can't submesh CAD model
                out = self.submesh(self.scan, faces, append=True)
            else: 
                # Concatenate both submeshes
                scan_sub = self.submesh(self.scan, s, append=True)
                cad_sub = self.submesh(self.cad, c, append=True)
                out = trimesh.util.concatenate([cad_sub, scan_sub])
            #out.fill_holes()
            out.fix_normals()
            meshes.append(out)
        return meshes

    def model_intersect(self, idx, faces, cad_crossed):
        if idx not in faces:
            faces.append(idx)
        close_faces = trimesh.proximity.nearby_faces(self.cad, 
                                            np.array([self.scan.triangles_center[idx],]))[0]
        for f in close_faces:
            cad_vertices = self.cad.vertices[self.cad.faces[f], :]
            scan_vertices = self.scan.vertices[self.scan.faces[idx], :]
            if faces_intersect(cad_vertices, scan_vertices):
                # Faces intersect, store CAD
                if f not in cad_crossed:
                    cad_crossed.append(f)
                return faces, cad_crossed
        
        for f in self.scan_connected[idx]:
            if f not in faces:
                faces, cad_crossed = self.model_intersect(f, faces, cad_crossed)
        
        return faces, cad_crossed
    
    def export_volumes(self, dest_folder):
        # Export under-extruded volumes to dest folder
        for idx, under in enumerate(self.under_meshes):
            under.visual.vertex_colors = np.array((30, 38, 145, 255))
            out = os.path.join(dest_folder, 'under' + str(idx) + '.glb')
            trimesh.exchange.export.export_mesh(under, out, file_type="glb")
        # Export over-extruded volumes to dest folder
        for idx, over in enumerate(self.over_meshes):
            over.visual.vertex_colors = np.array((255, 13, 13, 255))
            out = os.path.join(dest_folder, 'over' + str(idx) + '.glb')
            trimesh.exchange.export.export_mesh(over, out, file_type="glb")

        # Debugging instant display
        trimesh.Scene(self.under_meshes + self.over_meshes).show()

    # Modified from 
    # https://github.com/mikedh/trimesh/blob/b9ef0a8a2434f89f41cca714a7100e78dcf1caeb/trimesh/base.py#L2676
    def submesh(self, mesh,
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
