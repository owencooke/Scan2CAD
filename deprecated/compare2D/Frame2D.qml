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
    property bool scan
    
    // Functions for cycling through list of images
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
        // Display detected contours to user for comparison
        function onIterateContour(idx, percent) {
            var img = "assets/_contours/mask" + idx + ".png"
            contour.source = img
            console.log(percent+"%")
        }
        // Reset contour source
        function onContourResult(dist, percent) {
            contour.source = ''
        }
    }

    implicitHeight: 300
    implicitWidth: 300
    
    // Picture frame
    Rectangle {
        id: frame
        anchors { top: viewLabel.bottom; left: parent.left; right: parent.right; 
                    bottom: buttonLayout.top; bottomMargin: 8}
        color: root.menuColor
        clip: true

        // Image of 3D part
        Image {
            id: image
            anchors.fill: parent
            anchors.margins: 16
            height: parent.height * 0.8
            fillMode: Image.PreserveAspectFit
            source: urls[index]
            cache: false
        }

        // Contour image with transparent bg
        Image {
            id: contour
            anchors.fill: parent
            anchors.margins: 16
            height: parent.height * 0.8
            fillMode: Image.PreserveAspectFit
            cache: false
        }
    }

    // Title (view perspective)
    Label {
        id: viewLabel
        anchors { horizontalCenter: parent.horizontalCenter;
                    top: parent.top; bottomMargin: 8 }
        text: views[index]
        color: root.textColor
        font.family: titleFont.font.family
        font.pointSize: 24
    }

    // Arrows for flipping through images
    IconButton {
        anchors { left: frame.left; verticalCenter: viewLabel.verticalCenter }
        icon.source: "assets/icons/square-caret-left-solid.svg"
        onClicked: decrement()
    }

    IconButton {
        anchors { right: frame.right; verticalCenter: viewLabel.verticalCenter }
        iconURL: "assets/icons/square-caret-right-solid.svg"
        onClicked: increment()
    }

    RowLayout {
        id: buttonLayout
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom 
        spacing: 24

        // Capture from 3D viewer 
        IconButton {
            text: "GET FROM 3D VIEWER"
            tipText: "Get from 3D viewer"
            iconURL: "assets/icons/cube-solid.svg"
            display: (frame.width > 350) ? AbstractButton.TextBesideIcon : AbstractButton.IconOnly

            onClicked: {
                root.index = 1
                compare2D.captureRotations(!scan, scan)
            }
        }

        // Upload images manually
        IconButton {
            id: uploadButton
            text: "UPLOAD MANUALLY"
            tipText: "Upload manually"
            iconURL: "assets/icons/upload-solid.svg"
            display: (frame.width > 350) ? AbstractButton.TextBesideIcon : AbstractButton.IconOnly

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