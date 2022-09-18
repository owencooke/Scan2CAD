import trimesh
import numpy as np
from trimesh.util import type_named, append_faces
from _triangles_intersect import faces_intersect

# class ErrorSubsets():
#     def __init__(self):
#         self.scan_groups = {}
#         self.cad_groups = {}

#     def add_subset(self, scan_faces, cad_faces):
#         if len(self.scan_groups) == 0:
#             self.scan_groups[0] = scan_faces
#             self.cad_groups[0] = cad_faces
#         else:





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
        for key, shared in trimesh.graph.face_adjacency(mesh=mesh):
            if key in cc_hash:
                cc_hash[key].append(shared)
            else:
                cc_hash[key] = [shared]
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
        under = self.mesh_faces(under_faces)
        over = self.mesh_faces(over_faces)
        return over, under

    def mesh_faces(self, init_faces):
        # Recurse thru all faces connected to detected errors
        cad_crossed = []
        faces = []
        for f in init_faces:
            if f not in faces:
                faces, cad_subset = self.model_intersect(f, faces, cad_crossed)
        
        # find CAD faces that enclose the scan repair volume
        print(cad_crossed)
        if not cad_crossed:
            # List empty, can't submesh
            out = self.submesh(self.scan, faces, append=True)
        else: 
            # Concatenate both submeshes
            scan_sub = self.submesh(self.scan, faces, append=True)
            cad_sub = self.submesh(self.cad, cad_crossed, append=True)
            out = trimesh.util.concatenate([cad_sub, scan_sub])
        out.fill_holes()
        out.fix_normals()
        return out

    def model_intersect(self, idx, faces, cad_crossed):
        if idx not in faces:
            faces.append(idx)
        # _, dist, cad_face = trimesh.proximity.closest_point(self.cad, 
        #                                 np.array([self.scan.triangles_center[idx],]))
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
        # # Base condition, find approx CAD intersection
        # if dist[0] <= 1e-2:
        #     if cad_face[0] not in cad_crossed:
        #         cad_crossed.append(cad_face[0])
        #     return faces, cad_crossed
        # else: 
            # Search all of its connected components not already in list
        try: 
            for f in self.scan_connected[idx]:
                if f not in faces:
                    faces, cad_crossed = self.model_intersect(f, faces, cad_crossed)
                return faces, cad_crossed
        except KeyError:
            return faces, cad_crossed

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
