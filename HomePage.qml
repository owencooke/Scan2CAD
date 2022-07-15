import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.AssetUtils

Item {
    id: pageHome

    Rectangle {
        id: menuBar
        color: "#90de9d"//root.menuColor
        implicitHeight: 48
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        Rectangle {
            id: menuButtonPlaceholder
            implicitWidth: 48
            implicitHeight: 48
            opacity: 0
        }
    }

    // 3D Rotating LIMDA logo for background
    Rectangle {
        id: background3D
        color: root.bgColor
        anchors.top: menuBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        View3D {
            id: view3D
            anchors.fill: parent
            environment: sceneEnvironment

            DirectionalLight {
                id: directionalLight
                color: "white"
                brightness: 15
            }

            OrthographicCamera {
                id: camera
                clipNear: -9999
                z: 2500
                y: -150
            }

            RuntimeLoader {
                id: logo3D
                property double scaleToWindow: pageHome.width/650
                source: "backend_resources/icons/limda_logo.glb"
                scale:  Qt.vector3d(scaleToWindow, scaleToWindow, scaleToWindow)
                pivot: Qt.vector3d(200,0,0) // "Origin", effectively
                rotation: Quaternion.fromAxisAndAngle(Qt.vector3d(1, 0, 0), 90)
                position: Qt.vector3d(-40,0,0)
            }

            Timer {
                id: logoRotator
                interval: 20; running: true; repeat: true; triggeredOnStart: true
                property double rotAmount: 0.1
                property double currentRot: 0
                onTriggered: {
                    if (Math.round(currentRot) == 22) {
                        rotAmount = -0.1
                    } else if (Math.round(currentRot) == -22) {
                        rotAmount = 0.1
                    }
                    logo3D.rotate(rotAmount, Qt.vector3d(0,0,1), Node.LocalSpace)
                    currentRot += rotAmount
                }
            }

            WasdController {
                controlledObject: logo3D
            }

            SceneEnvironment {
                id: sceneEnvironment
                antialiasingMode: SceneEnvironment.MSAA
                antialiasingQuality: SceneEnvironment.Medium
            }
        }
    }
}