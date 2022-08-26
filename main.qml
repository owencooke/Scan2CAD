import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    property alias index: stack.currentIndex

    // Theme and Colors
    property string theme: "dark"
    property string textColor: "white"
    property string secondaryText: "#9e9d9d"
    property string menuColor: "#303030"
    property string bgColor: "#252525"

    // Fonts
    FontLoader { id: regFont; source: "backend_resources/fonts/Inter-Regular.otf" }
    FontLoader { id: titleFont; source: "backend_resources/fonts/Inter-Black.otf" }

    // Takes a filepath from FileDialog as input; returns just the file name and ext
    function getFilename(filepath) {
        var dirs = filepath.split("/")
        return dirs[dirs.length-1]
    }

    // Rounds input value to the specified number of digits (dec_digits)
    function roundDecimal(value, dec_digits) {
        var multiplier = 10 ** dec_digits
        var result = (Math.round(value * multiplier) / multiplier).toFixed(dec_digits)
        var result_string = result.toString()
        while (result_string.slice(-1) == '0') {
            result_string = result_string.slice(0, result_string.length - 1)
        }
        if (result_string.slice(-1) == '.') {
            result_string = result_string.slice(0, result_string.length - 1)
        }
        return result_string
    }

    // Default window properties
    width: 1280
    height: 720
    visible: true
    color: root.bgColor
    title: "LIMDA GUI 1.0.0"

    // Page Layout
    StackLayout {
        id: stack
        anchors { fill: parent; leftMargin: 48 }

        // QML pages (index=0,1,2...)
        HomePage {}
        Model3D {}
        CompareImages2D { id: compare2D } 
        //LiveEdit {}
        Align {}
        // Always leave settings as last index (bottom icon)
        Settings {}
    }

    // Quick access sidebar menu for popular page's icons
    Rectangle {
        anchors { top: parent.top; left: parent.left; bottom: parent.bottom }
        implicitWidth: 48
        color: root.menuColor

        ColumnLayout {
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
            spacing: 0

            // Navigation menu button
            MenuButton { iconURL: "backend_resources/icons/bars.svg"; icon.height: 32; 
                                icon.width: 32; pageIndex: -1; onClicked: menuNav.open() }
            // Customized menu icons: assign text, page index (0,1,2...), and icon source below
            MenuButton { tipText: "Homepage"; pageIndex: 0;
                            iconURL: "backend_resources/icons/house.svg" }
            MenuButton { tipText: "3D Viewer"; pageIndex: 1; 
                            iconURL: "backend_resources/icons/cube-solid.svg" }
            MenuButton { tipText: "2D Projection Comparison"; pageIndex: 2; 
                            iconURL: "backend_resources/icons/camera-retro-solid.svg" }
            MenuButton { tipText: "3D Comparison"; pageIndex: 3;
                            iconURL: "backend_resources/icons/cubes-solid.svg" }
        }
        // Settings button placed at bottom
        MenuButton {
            anchors.bottom: parent.bottom
            tipText: "Settings"
            pageIndex: stack.count - 1
            iconURL: "backend_resources/icons/gear-solid.svg"
        }
    }

    // Expandable and scrollable navigation menu
    Drawer {
        id: menuNav
        clip: true
        modal: true
        width: navColumn.width + navColumn.anchors.leftMargin
        height: parent.height
        background: Rectangle { color: root.menuColor }

        Flickable {
            id: flickable
            anchors.fill: parent
            clip: true
            contentHeight: navColumn.height
            contentWidth: navColumn.width
            flickableDirection: Flickable.VerticalFlick

            ScrollIndicator.vertical: ScrollIndicator {
                parent: flickable.parent
                anchors { top: flickable.top; right: flickable.right;
                            bottom: flickable.bottom }
                active: true
            }

            ColumnLayout {
                id: navColumn
                anchors { top: parent.top; left: parent.left; leftMargin: 2 }
                spacing: 0

                // Navigation menu button
                MenuButton { 
                    text: root.title
                    font.family: titleFont.font.family
                    icon { height: 32; width: 32; source: "backend_resources/icons/bars.svg" }
                    pageIndex: -1; 
                    onClicked: menuNav.close() 
                }
                // Customized button defined in MenuButton.qml: assign text, page index (0,1,2...), and icon source below
                MenuButton { text: "Homepage"; pageIndex: 0; iconURL: "backend_resources/icons/house.svg"}
                MenuButton { text: "3D Viewer"; pageIndex: 1; iconURL: "backend_resources/icons/cube-solid.svg" }
                MenuButton { text: "2D Projection Comparison"; pageIndex: 2; iconURL: "backend_resources/icons/camera-retro-solid.svg" }
                MenuButton { text: "3D Comparison"; pageIndex: 3; iconURL: "backend_resources/icons/cubes-solid.svg" }
                // For demo-ing scrollable menu
                Repeater {
                    model: 15
                    MenuButton { text: "Coming Soon"; pageIndex: 0; iconURL: "backend_resources/icons/diagram-project-solid.svg" }
                }
            }
        }
    }
}
