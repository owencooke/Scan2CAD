import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    implicitHeight: 600
    implicitWidth: 200

    // Upper label
    Label {
        id: overLabel
        anchors { top: parent.top; margins: 16;
                    horizontalCenter: parent.horizontalCenter }
        text: "Over-Extrusion"
        color: root.textColor
        font.family: regFont.font.family
        font.pointSize: 10
    }

    // Lower label
    Label {
        id: underLabel
        anchors { bottom: parent.bottom; margins: 16;
                    horizontalCenter: parent.horizontalCenter }
        text: "Under-Extrusion"
        color: root.textColor
        font.family: regFont.font.family
        font.pointSize: 10
    }

    // Rainbow gradient for color-distance association
    Rectangle {
        id: depthGradient
        anchors { right: parent.right; margins: 8
                    top: overLabel.bottom; bottom: underLabel.top }
        width: parent.width / 4
        radius: width / 4
    
        gradient: Gradient {
            GradientStop { position: 0; color: "red" }
            GradientStop { position: 0.167; color: "orange" }
            GradientStop { position: 0.333; color: "yellow" }
            GradientStop { position: 0.5; color: "green" }
            GradientStop { position: 0.667; color: "cyan" }
            GradientStop { position: 0.833; color: "blue" }
            GradientStop { position: 1; color: "indigo" }
        }

        // Middle line indicator
        Rectangle {
            height: 3
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
        }

        // Unit labels
        Label {
            anchors { top: parent.top; margins: 6;
                        horizontalCenter: parent.horizontalCenter }
            text: "(mm)"
            color: root.textColor
            font.family: regFont.font.family
            font.pointSize: 8
        }

        Label {
            anchors { bottom: parent.bottom; margins: 6;
                        horizontalCenter: parent.horizontalCenter }
            text: "(mm)"
            color: root.textColor
            font.family: regFont.font.family
            font.pointSize: 8
        }
    }

    // Column of thresholds from calculated distances
    ColumnLayout {
        anchors {right: depthGradient.left; left: parent.left; rightMargin: 8
                    top: depthGradient.top; bottom: depthGradient.bottom; leftMargin: 8 }

        Repeater {
            // List of floats calculated in _depth_map.py
            model: try {cloudClass.thresh_model} catch(TypeError) {}
            Label {
                Layout.alignment: Qt.AlignRight
                text: cloudClass.thresh_model[index].toPrecision(3)
                color: root.textColor
                font.family: regFont.font.family
                font.pointSize: 10
            }
        }
    }
}