import QtQuick
import QtQuick3D

/*!
    \qmltype MeshLighting
    \brief Lighting intended for 3D object files loaded at Runtime by the user.

    Module for lighting a Node in a View3D scene.
    Implements three DirectionalLight's that change their axial rotation
    depending on the rotation of the orthographic camera. 
    This ensures that the 3 sides visible to the user are well-lit, while
    the other sides remain shadowed to depict object depth.

    \inqmlmodule LIMDA

    \section1 Setting the color of a loaded object
    To set the color of a loaded object, set target to the 
    id of the Node object and set targetColor to the desired color of light. 

    \qml
    MeshLighting {
        target: node
        targetColor: "cyan"
        camera: myCamera
    }
    \endqml
*/

Node {
    /*! Node to apply lighting to. */
    required property Node target
    /*! Color of the light. */
    required property string targetColor
    /*! Camera being used in the 3D scene. */
    required property Node camera

    property real intensity: 5

    readonly property vector3d lightRotation: getOctant(zeroTo360(camera.eulerRotation.x), 
                                                    zeroTo360(camera.eulerRotation.y))
    function zeroTo360(val) {
        return ((val % 360) + 360) % 360
    }

    function getOctant(rotX, rotY) {
        // Change light rotations depending on current octant rotation of the camera
        var lights = Qt.vector3d(270, 90, 180)

        // "RIGHTSIDE UP" cases
        if (rotX > 0 && rotX < 90) {
            // Oct3
            if (rotY > 270 && rotY < 360) {
                lights = Qt.vector3d(90, 270, 180)
            }
            // Oct4
            else if (rotY > 0 && rotY < 90) {
                lights = Qt.vector3d(270, 270, 180)
            }
            // Oct7
            else if (rotY > 180 && rotY < 270) {
                lights = Qt.vector3d(90, 270, 0)
            }
            // Oct8
            else if (rotY > 90 && rotY < 180) {
                lights = Qt.vector3d(270, 270, 0)
            }
        } else if (rotX > 270 && rotX < 360) {
            // Oct1
            if (rotY > 0 && rotY < 90) {
                lights = Qt.vector3d(270, 90, 180)
            }
            // Oct2
            else if (rotY > 270 && rotY < 360) {
                lights = Qt.vector3d(90, 90, 180)
            }
            // Oct5
            else if (rotY > 90 && rotY < 180) {
                lights = Qt.vector3d(270, 90, 0)
            }
            // Oct6
            else if (rotY > 180 && rotY < 270) {
                lights = Qt.vector3d(90, 90, 0)
            }
        // "UPSIDE DOWN" cases
        } else if (rotX > 90 && rotX < 180) {
            // Oct1
            if (rotY > 180 && rotY < 270) {
                lights = Qt.vector3d(270, 270, 180)
            }
            // Oct2
            else if (rotY > 90 && rotY < 180) {
                lights = Qt.vector3d(90, 270, 180)
            }
            // Oct5
            else if (rotY > 270 && rotY < 360) {
                lights = Qt.vector3d(270, 270, 0)
            }
            // Oct6
            else if (rotY > 0 && rotY < 90) {
                lights = Qt.vector3d(90, 270, 0)
            }
        } else if (rotX > 180 && rotX < 270) {
            // Oct3
            if (rotY > 90 && rotY < 180) {
                lights = Qt.vector3d(90, 90, 180)
            }
            // Oct4
            else if (rotY > 0 && rotY < 90) {
                lights = Qt.vector3d(90, 90, 0)
            }
            // Oct7
            else if (rotY > 270 && rotY < 360) {
                lights = Qt.vector3d(270, 90, 0)
            }
            // Oct8
            else if (rotY > 180 && rotY < 270) {
                lights = Qt.vector3d(270, 90, 180)
            }
        }
        return lights
    }

    DirectionalLight {
        id: zLight
        scope: target
        color: targetColor
        brightness: intensity
        eulerRotation.x: lightRotation.z
    }
    DirectionalLight {
        id: yLight
        scope: target
        color: targetColor
        brightness: intensity
        eulerRotation.x: lightRotation.y
    }
    DirectionalLight {
        id: xLight
        scope: target
        color: targetColor
        brightness: intensity
        eulerRotation.y: lightRotation.x
    }
}