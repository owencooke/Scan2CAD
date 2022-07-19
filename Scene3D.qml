import QtQuick
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.AssetUtils

View3D {
    id: view3D
    property Node target: mesh
    property string nodeColor
    property bool activateGrid
    property vector3d meshRotation

    // Rotating mesh to each side view and capturing image of the scene
    function capture2D(fname) {
        // Disable gridlines and adjust color for high contrast
        axes.enableXYGrid = false
        axes.enableAxisLines = false
        light.targetColor = root.textColor
        //mesh.eulerRotation = Qt.vector3d(0,0,0)
        // Image grabs happen asynchronously; must be structured like this
        // in order for image rotations to update
        // Front
        view3D.grabToImage(function(result) {
            result.saveToFile("backend_resources/captured_imgs/" + fname + "_front.png")
            // Top
            mesh.eulerRotation.x += 90
            view3D.grabToImage(function(result) {
                result.saveToFile("backend_resources/captured_imgs/" + fname + "_top.png")
                // Bottom 
                mesh.eulerRotation.x += 180
                view3D.grabToImage(function(result) {
                    result.saveToFile("backend_resources/captured_imgs/" + fname + "_bottom.png")
                    // Left
                    mesh.eulerRotation.x -= 270
                    mesh.eulerRotation.y += 90
                    view3D.grabToImage(function(result) {
                        result.saveToFile("backend_resources/captured_imgs/" + fname + "_left.png")
                        // Rear
                        mesh.eulerRotation.y += 90
                        view3D.grabToImage(function(result) {
                            result.saveToFile("backend_resources/captured_imgs/" + fname + "_rear.png")
                            // Right
                            mesh.eulerRotation.y += 90
                            view3D.grabToImage(function(result) {
                                result.saveToFile("backend_resources/captured_imgs/" + fname + "_right.png")
                                // Give gridline/color control back to user
                                axes.enableXYGrid = Qt.binding(function() { return !activateGrid })
                                axes.enableAxisLines = Qt.binding(function() { return !activateGrid })
                                light.targetColor = Qt.binding(function() { return nodeColor })
                                mesh.eulerRotation.y -= 270
                            })
                        })
                    })
                })
            })
        })
    }
    //---------------------------------------------------//
    // VISUALS: for creating the 3D scene                //
    //---------------------------------------------------//
    camera: OrthographicCamera {
        id: camera
        property double zoomX: 1
        property double zoomY: 1
        clipNear: -9999
        pivot: target.pivot
        horizontalMagnification: zoomX
        verticalMagnification: zoomY
    }

    MeshLighting {
        id: light
        target: mesh
        targetColor: nodeColor
        camera: camera
    }

    RuntimeLoader {
        id: mesh
        //source: (scan) ? root.scanSource : root.cadSource
        property vector3d dimensions
        eulerRotation: meshRotation
        scale:  Qt.vector3d(5,5,5)
    }

    environment: SceneEnvironment {
        id: env
        antialiasingMode: SceneEnvironment.MSAA
        antialiasingQuality: SceneEnvironment.VeryHigh
        backgroundMode: SceneEnvironment.Color
        clearColor: root.bgColor 
    }

    //------------------------------------------------------//
    // CONTROLS: giving the user control over the model     //
    //------------------------------------------------------//
    MeshController {
        scene: view3D
        camera: camera
        target: mesh
        anchors.fill: parent
        
        onReleased: {mesh.eulerRotation = Qt.binding(function() { return meshRotation }); console.log('released')}
    }

    // Timer {
    //     interval: 1000; running: true; repeat: true
    //     onTriggered: {
    //         //mesh.eulerRotation = Qt.binding(function() { return meshRotation })
    //         console.log("Node pos:", mesh.position)
    //         console.log("Cam pos:", camera.position)
    //         console.log("Cam zoom:", camera.zoomX, camera.zoomY)
    //         console.log()
    //         console.log()
    //     }
    // }

    AxisHelper {
        id: axes
        enableXZGrid: false // Model kept in XY plane
        enableXYGrid: !activateGrid
        enableAxisLines: !activateGrid
        gridColor: root.secondaryText
    }
}