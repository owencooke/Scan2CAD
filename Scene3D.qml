import QtQuick
import QtQuick3D
import QtQuick3D.Helpers

View3D {
    id: view3D
    property Node target: mesh
    property string nodeColor
    property bool activateGrid
    property vector3d meshRotation

    // Rotate mesh to each orthographic view and capture image of the scene
    function capture2D(fname) {
        // Disable gridlines and adjust color for high image contrast
        axes.enableXYGrid = false
        axes.enableAxisLines = false
        mesh.color = root.textColor
        var dir = backend.get_basedir() + "/backend_resources/_captured_imgs/"
        
        // Front
        view3D.grabToImage(function(result) {
            result.saveToFile(dir + fname + "_front.png")
            // Top
            mesh.eulerRotation.x += 90
            view3D.grabToImage(function(result) {
                result.saveToFile(dir + fname + "_top.png")
                // Bottom 
                mesh.eulerRotation.x += 180
                view3D.grabToImage(function(result) {
                    result.saveToFile(dir + fname + "_bottom.png")
                    // Left
                    mesh.eulerRotation.x -= 270
                    mesh.eulerRotation.y += 90
                    view3D.grabToImage(function(result) {
                        result.saveToFile(dir + fname + "_left.png")
                        // Rear
                        mesh.eulerRotation.y += 90
                        view3D.grabToImage(function(result) {
                            result.saveToFile(dir + fname + "_rear.png")
                            // Right
                            mesh.eulerRotation.y += 90
                            view3D.grabToImage(function(result) {
                                result.saveToFile(dir + fname + "_right.png")
                                // Give gridline/color control back to user
                                axes.enableXYGrid = Qt.binding(function() { return !activateGrid })
                                axes.enableAxisLines = Qt.binding(function() { return !activateGrid })
                                mesh.color = Qt.binding(function() { return nodeColor })
                                mesh.eulerRotation.y -= 270
                                // Call backend function to crop the images
                                if (fname == "cad") {
                                    backend.crop2D(root.theme, true, false)
                                } else {
                                    backend.crop2D(root.theme, false, true)
                                }
                            })
                        })
                    })
                })
            })
        })
    }

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