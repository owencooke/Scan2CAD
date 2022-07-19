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

    Connections {
        target: backend
        function onIterateContour(idx, percent) {
            var img = "backend_resources/contours/mask" + idx + ".png"
            contour.source = img
            console.log(percent+"%")
        }
    }

    implicitHeight: 300
    implicitWidth: 300
    
    Rectangle {
        id: frame
        anchors { top: viewLabel.bottom; left: parent.left; right: parent.right; 
                    bottom: fileLayout.top; bottomMargin: 16}
        color: root.bgColor
        border.color: root.textColor
        border.width: 2
        clip: true

        Image {
            id: image
            anchors.fill: parent
            anchors.margins: 16
            // anchors.centerIn: parent
            // x: 0; y: 0
            height: parent.height * 0.8
            fillMode: Image.PreserveAspectFit
            source: urls[index]
            cache: false
        }
        Image {
            id: contour
            anchors.fill: parent
            anchors.margins: 16
            // anchors.centerIn: parent
            // x: 0; y: 0
            height: parent.height * 0.8
            fillMode: Image.PreserveAspectFit
            cache: false
        }

        // MouseArea {
        //     id: mouseArea
        //     anchors.fill: parent
        //     hoverEnabled: true
        //     // Zoom in/out using mouse scroll wheel
        //     onWheel: function(mouse) {
        //         var zoomFactor = 1.15
        //         // Save prior coordinates
        //         var old_coords = mapToItem(image, mouse.x, mouse.y)
        //         // Scale camera according to scroll dir
        //         if (mouse.angleDelta.y > 0) {
        //             scale = zoomFactor
        //         } else {
        //             scale = 1/zoomFactor
        //         }
        //         // Set minimum zoom (x/y symmetric)
        //         var zoomThreshold = 50
        //         if (image.height*scale > zoomThreshold) {
        //             image.height *= scale
        //             image.width *= scale
        //             // Find new coordinates
        //             var new_coords = mapToItem(image, mouse.x, mouse.y)
        //             var dx = new_coords.x - old_coords.x
        //             var dy = new_coords.y - old_coords.y
        //             // Apply translation to point
        //             image.x += dx
        //             image.y += dy
        //             console.log("old:", old_coords)
        //             console.log("new:", new_coords)
        //             console.log("deltax", dx, "deltay", dy)
        //             console.log()
        //         }
        //     }
        // }
    }

    Label {
        id: viewLabel
        anchors { horizontalCenter: parent.horizontalCenter;
                    top: parent.top; bottomMargin: 8 }
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