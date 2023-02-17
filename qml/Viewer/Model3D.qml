import QtQuick
import QtQuick.Controls

Item {
    // Left layout for 3D scene and menu
    SplitView {
        id: cadLayout
        orientation: Qt.Vertical
        anchors { top: parent.top; left: parent.left;
                    right: middleBorder.left; bottom: parent.bottom }
        handle: Rectangle {
            id: handleDelegate
            implicitHeight: 2
            color: SplitHandle.pressed ? "#81e889"
                    : (SplitHandle.hovered ? Qt.lighter("#c2f4c6", 1.1) : "#9e9d9d")
            containmentMask: Item {
                width: cadLayout.width
                height: 10
            }
        }

        // Left 3D scene
        Scene3D {
            id: cadScene
            SplitView.preferredHeight: parent.height * (3/4)
            SplitView.minimumHeight: parent.height * (5/12)
            nodeColor: cadControls.targetColor
            activateGrid: cadControls.gridChecked
        }

        // Left 3D menu
        InfoControls3D {
            id: cadControls
            SplitView.fillHeight: false
            SplitView.preferredHeight: 200
            target: cadScene.target
            scan: false
        }
    }

    // Border between the two scenes
    Rectangle {
        id: middleBorder
        anchors { top: parent.top; bottom: parent.bottom;
                    horizontalCenter: parent.horizontalCenter }
        implicitWidth: 10
        color: root.menuColor
    }

    // Right layout for 3D scene and menu
    SplitView {
        id: scanLayout
        orientation: Qt.Vertical
        anchors { top: parent.top; right: parent.right
                    left: middleBorder.right; bottom: parent.bottom }
        handle: Rectangle {
            id: handleDelegate
            implicitHeight: 2
            color: SplitHandle.pressed ? "#81e889"
                    : (SplitHandle.hovered ? Qt.lighter("#c2f4c6", 1.1) : "#9e9d9d")
            containmentMask: Item {
                width: scanLayout.width
                height: 10
            }
        }

        // Right 3D Scene
        Scene3D {
            id: scanScene
            SplitView.preferredHeight: parent.height * (3/4)
            SplitView.minimumHeight: parent.height / 2
            nodeColor: scanControls.targetColor
            activateGrid: scanControls.gridChecked
        }

        // Right 3D menu
        InfoControls3D {
            id: scanControls
            SplitView.fillHeight: false
            SplitView.preferredHeight: 200
            target: scanScene.target
            scan: true
        }
    }
}