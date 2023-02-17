import QtQuick
import QtQuick3D
import QtQuick3D.Helpers

View3D {
    id: view3D
    property Node target: mesh
    property string nodeColor
    property bool activateGrid
    property vector3d meshRotation

    camera: OrthographicCamera {
        id: camera
        clipNear: -9999
        horizontalMagnification: 5
        verticalMagnification: 5
    }

    DirectionalLight{}

    // Node storing model loaded by user
    DynamicNode {
        id: mesh
        color: nodeColor
        eulerRotation: meshRotation
    }

    // Scene rendering options
    environment: SceneEnvironment {
        id: env
        antialiasingMode: SceneEnvironment.MSAA
        antialiasingQuality: SceneEnvironment.VeryHigh
        backgroundMode: SceneEnvironment.Color
        clearColor: root.bgColor 
    }

    // Mouse control tool
    MeshController {
        id: mouse
        scene: view3D
        camera: camera
        target: mesh
        anchors.fill: parent
        keysEnabled: false
    }

    // Gridlines
    AxisHelper {
        id: axes
        enableXZGrid: false // Model kept in XY plane
        enableXYGrid: !activateGrid
        enableAxisLines: !activateGrid
        gridColor: root.secondaryText
        scale: Qt.vector3d(1/5, 1/5, 1/5)
    }
}