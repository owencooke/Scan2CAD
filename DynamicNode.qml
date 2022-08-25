
import QtQuick3D.AssetUtils

RuntimeLoader {
    id: mesh

    property vector3d init_dims: Qt.vector3d(0,0,0)
    property vector3d dimensions: Qt.vector3d(0,0,0)

    // Reset all Node properties to their "default", NOT including source
    function resetNode() {
        mesh.scale = Qt.vector3d(1, 1, 1)
        mesh.eulerRotation = Qt.vector3d(0, 0, 0)
        mesh.position = Qt.vector3d(0, 0, 0)
        mesh.visible = true
        mesh.dimensions = mesh.init_dims
    }
    // Initialize Node properties upon loading from external file
    function setNodeProperties(fname, centroid, dim) {
        mesh.source = "backend_resources/_converted_mesh/" + fname + ".glb"
        mesh.pivot = centroid
        mesh.dimensions = mesh.init_dims = dim
    }
}