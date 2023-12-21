import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick3D

import "../Controls" as Controls

Rectangle { 
    property Node target
    property bool scanFlag
    property string fileColor: root.secondaryText
    property string buttonColor: root.textColor

    function closeTools(prev_state) {
        // Close all tool containers
        colorContainer.visible = false
        rotateContainer.visible = false
        scaleContainer.visible = false
        return !prev_state
    }
    
    color: root.menuColor
    implicitHeight: 48
    width: 260

    RowLayout {
        id: textRow
        spacing: 8
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }

        // Filename from upload
        Label {
            id: fileLabel
            text: "No folder selected."
            color: fileColor
            font.family: regFont.font.family
            font.pointSize: 11
        }

        // File upload button
        Controls.IconButton {
            icon { source: icons.upload; 
                    width: 24; height: 24 }
            onClicked: dialog.open()

            FolderDialog {
                id: dialog
                title: "Select a folder with notched images"

                onAccepted: {
                    let fullpath = selectedFolder.toString()

                    fileLabel.text = getFilename(fullpath)
                    fileLabel.color = Qt.binding(function() { return root.secondaryText })

                    backend.align_all(fullpath)
                }
            }
        }
    }

    // Title
    Label {
        id: title
        anchors { left: parent.left; verticalCenter: parent.verticalCenter; margins: 8}
        text: "Select the Directory of Experiment Images (with notch)"
        color: root.textColor
        font.family: titleFont.font.family
        font.pointSize: 18
    }

    Label {
        id: instruction
        anchors { left: parent.left; top: textRow.bottom; margins: 10}
        text: "This feature assumes that the selected image folder consists of tif images titled with numbers only. \nThe output images are in a folder called resultedImg. \nIt will align images right after the directory of original images is selected."
        color: root.textColor
        font.family: titleFont.font.family
        font.pointSize: 14
    }
}