import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Item {
    property alias source: image.source
    property var index: 0
    property var views: ["FRONT", "TOP", "LEFT",
                        "REAR", "BOTTOM", "RIGHT"]
    property var urls: ["", "", "", "", "", ""]

    function increment() {
        if (index < 5) {
            index += 1
        } else {
            index = 0
        }
    }
    function decrement() {
        if (index > 0) {
            index -= 1
        } else {
            index = 5
        }
    }
    function reload() {
        increment()
        decrement()
    }

    implicitHeight: 300
    implicitWidth: 300
    
    Rectangle {
        id: frame
        anchors { top: parent.top; left: parent.left; right: parent.right; 
                    bottom: fileLayout.top; bottomMargin: 16}
        color: root.bgColor
        border.color: root.textColor
        border.width: 2
        clip: true

        Image {
            id: image
            anchors.centerIn: parent
            // x: parent.x
            // y: parent.y
            height: parent.height * 0.9
            fillMode: Image.PreserveAspectFit
            source: urls[index]
            cache: false
        }

        // MouseArea {
        //     id: mouseArea
        //     anchors.fill: parent
        //     hoverEnabled: true
        //     onExited: console.log("leave")
        //     // Zoom in/out using mouse scroll wheel
        //     onWheel: function(event) {
        //         var zoomFactor = 1.15
        //         // Get current screen to scene coordinates
        //         var old_coords = [event.x, event.y]
        //         // Scale camera according to scroll dir
        //         if (event.angleDelta.y > 0) {
        //             scale = zoomFactor
        //         } else {
        //             scale = 1/zoomFactor
        //         }
        //         // Set minimum zoom (x/y symmetric)
        //         var zoomThreshold = 20
        //         if (image.height*scale > zoomThreshold) {
        //             image.height *= scale
        //             image.width *= scale
        //             // Re-adjust translation
        //             image.x -= old_coords[0]
        //             image.y -= old_coords[1]
        //         }
        //     }
        // }
    }

    Label {
        id: viewLabel
        anchors { horizontalCenter: parent.horizontalCenter;
                    bottom: frame.top; bottomMargin: 8 }
        text: views[index]
        color: root.textColor
        font.family: titleFont.font.family
        font.pointSize: 24
    }

    Button {
        anchors { left: frame.left; verticalCenter: viewLabel.verticalCenter }
        icon.source: "backend_resources/icons/square-caret-left-solid.svg"
        icon.color: root.textColor
        icon.width: 28
        icon.height: 28
        background: Rectangle { opacity: 0 }
        onClicked: decrement()
    }

    Button {
        anchors { right: frame.right; verticalCenter: viewLabel.verticalCenter }
        icon.source: "backend_resources/icons/square-caret-right-solid.svg"
        icon.color: root.textColor
        icon.width: 28
        icon.height: 28
        background: Rectangle { opacity: 0 }
        onClicked: increment()
    }

    RowLayout {
        id: fileLayout
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        spacing: 16
        Label {
            text: "FILENAME:"
            color: root.secondaryText
            font.family: titleFont.font.family
            font.pointSize: 14
        }
        // Model filename
        Label {
            text: "No image selected."
            color: root.secondaryText
            font.family: regFont.font.family
            font.pointSize: 12
        }

        // Upload Button
        Button {
            id: uploadButton
            icon.source: "backend_resources/icons/upload-solid.svg"
            icon.color: root.textColor
            icon.width: 28
            icon.height: 28
            background: Rectangle { opacity: 0 }
            onClicked: dialog.open()

            FileDialog {
                id: dialog
                title: "Select an Orthographic Projection Image"
                nameFilters: ["Images (*.png *.jpg *.jpeg *.bmp)"]
                onAccepted: {
                    urls[index] = selectedFile
                    reload()
                }
            }
        }
    }
}