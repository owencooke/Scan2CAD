import QtQuick
import QtQuick3D
import QtQuick3D.Helpers

MouseArea {
    id: mouseArea
    property Node target
    property Camera camera
    property View3D scene
    property bool held: false
    
    hoverEnabled: true
    preventStealing: true

    // CONTROL 1: Zoom in/out using mouse scroll wheel
    /////////////////////////////////////////////////////////////////////////////
    onWheel: function(event) {
        var zoomFactor = 1.15
        // Get current screen to scene coordinates
        var oldScene = scene.mapTo3DScene(Qt.vector3d(event.x, event.y, camera.z))
        // Scale camera according to scroll dir
        if (event.angleDelta.y > 0) {
            scale = zoomFactor
        } else {
            scale = 1/zoomFactor
        }
        // Set minimum zoom (x/y symmetric)
        var zoomThreshold = 0.25
        if (camera.zoomX*scale > zoomThreshold) {
            camera.zoomX *= scale
            camera.zoomY *= scale
            // Get new screen to scene coordinates
            var newScene = scene.mapTo3DScene(Qt.vector3d(event.x, event.y, camera.z))
            // Translate back to original position
            var change = newScene.minus(oldScene)
            camera.position.x -= change.x
            camera.position.y -= change.y
        }
    }

    onPressed: function(mouse) {
        held = true
        while (held) {
            console.log("pressed")
        }
    }

    // CONTROL 2: rotation of model using mouse dragging
    // (can also support WASDRF movement if keysEnabled set to "true")
    /////////////////////////////////////////////////////////////////
    WasdController {
        controlledObject: target
        //keysEnabled: false
        //speed: 150
        xInvert: true
        yInvert: false
    }
}