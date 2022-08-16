import QtQuick
import QtQuick3D
import QtQuick3D.Helpers

MouseArea {
    id: mouseArea
    property Node target
    property Camera camera
    property View3D scene
    property alias keysEnabled: wasd.keysEnabled
    
    hoverEnabled: true
    preventStealing: true

    // Zoom using mouse scroll wheel
    onWheel: function(event) {
        var zoomFactor = 1.15
        // Get current screen to scene coordinates
        var oldScene = scene.mapTo3DScene(Qt.vector3d(event.x, event.y, camera.z))
        // Scale camera according to wheel scroll direction
        if (event.angleDelta.y > 0) {
            scale = zoomFactor
        } else {
            scale = 1/zoomFactor
        }
        // Set minimum zoom (x/y symmetric)
        var zoomThreshold = 0.25
        if (camera.horizontalMagnification*scale > zoomThreshold) {
            camera.horizontalMagnification *= scale
            camera.verticalMagnification *= scale
            // Get new screen to scene coordinates
            var newScene = scene.mapTo3DScene(Qt.vector3d(event.x, event.y, camera.z))
            // Translate back to original position
            var change = newScene.minus(oldScene)
            camera.position.x -= change.x
            camera.position.y -= change.y
        }
    }

    // Mouse rotation and WASDRF movement
    WasdController {
        id: wasd
        controlledObject: target
        xInvert: true
        yInvert: false
    }
}