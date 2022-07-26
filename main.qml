import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    property alias index: stack.currentIndex
    width: 1280
    height: 720
    color: root.bgColor
    visible: true
    title: qsTr("LIMDA")
    // Application formatting properties
    // Colors
    property string theme: "dark"
    property string textColor: "white"
    property string secondaryText: "#9e9d9d"
    property string menuColor: "#303030"
    property string bgColor: "#252525"
    property string selectedColor: "#7BCCDF"
    // Fonts, loaded from local file
    FontLoader { id: regFont; source: "backend_resources/fonts/Inter-Regular.otf" }
    FontLoader { id: titleFont; source: "backend_resources/fonts/Inter-Black.otf" }

    function getFilename(filepath) {
        var dirs = filepath.split("/")
        return dirs[dirs.length-1]
        // var with_ext = dirs[dirs.length-1]
        // dirs = with_ext.split(".")
        // return dirs[dirs.length-2]
    }

    function roundDecimal(value, dec_digits) {
        var multiplier = 10 ** dec_digits
        return (Math.round(value * multiplier) / multiplier).toFixed(dec_digits)
    }

    // Page layout for application
    StackLayout {
        id: stack
        anchors.fill: parent
        anchors.leftMargin: 48
        // PAGES placed below (same name as respective QML file)
        HomePage {} // index = 0
        Model3D {} // index = 1 ...
        CompareImages2D { id: compare2D } 
        //Edit {}
        Align {}
        Settings {} // leave settings as last index
    }

    // Menu navigation button (always on top of pages)
    Button {
        id: menuButton
        icon { source: "backend_resources/icons/bars.svg";
                color: root.textColor; height: 32; width: 32 }
        background: Rectangle {
            implicitWidth: 48
            implicitHeight: 48
            color: root.menuColor
        }

        onClicked: menuNav.open()
    }

    Rectangle {
        id: leftMenu
        color: root.menuColor
        implicitWidth: 48
        anchors.top: menuButton.bottom
        anchors.left: parent.left
        anchors.bottom: parent.bottom

        GridLayout {
            id: gridMenu
            columns: 1
            rowSpacing: 0
            anchors.horizontalCenter: parent.horizontalCenter
            // Buttons for the different pages laid out in a column
            // Customized button defined in MenuButton.qml: assign text, page index (0,1,2...), and icon source below
            MenuButton { tipText: "Homepage"; pageIndex: 0; iconURL: "backend_resources/icons/house.svg"}
            MenuButton { tipText: "3D Viewer"; pageIndex: 1; iconURL: "backend_resources/icons/cube-solid.svg" }
            MenuButton { tipText: "2D Projection Comparison"; pageIndex: 2; iconURL: "backend_resources/icons/camera-retro-solid.svg" }
            MenuButton { tipText: "3D Comparison"; pageIndex: 3; iconURL: "backend_resources/icons/cubes-solid.svg" }
            // MenuButton { tipText: "Testing"; pageIndex: 4; iconURL: "backend_resources/icons/diagram-project-solid.svg" }
        }

        MenuButton { 
            anchors.bottom: parent.bottom
            tipText: "Settings"
            pageIndex: stack.count - 1
            iconURL: "backend_resources/icons/gear-solid.svg"
        }
            
    }

    Drawer {
        id: menuNav
        clip: true
        modal: true
        //width: 0.25 * parent.width
        implicitWidth: 300
        height: parent.height
        //height: parent.height - menuButton.background.implicitHeight
        //y: menuButton.background.implicitHeight
        background: Rectangle { color: root.menuColor }

        Flickable {
            // Enables scrolling for menu
            id: flickable
            clip: true
            anchors.fill: parent
            //anchors.topMargin: 20
            contentHeight: grid.height
            contentWidth: grid.width

            ScrollIndicator.vertical: ScrollIndicator {
                id: scrollBar
                parent: flickable.parent
                active: true
                anchors.top: flickable.top
                anchors.right: flickable.right
                anchors.bottom: flickable.bottom
            }

            Item {
                // Purpose: to center gridlayout in the menuNav window
                id: wrapper
                width: menuNav.width - scrollBar.width
                height: 3000 // Should be larger than grid s.t. grid is fully scrollable
                anchors.horizontalCenter: parent.horizontalCenter

                GridLayout {
                    id: grid
                    anchors.left: parent.left
                    anchors.right: parent.right
                    columns: 1
                    rowSpacing: 0
                    // Buttons for the different pages laid out in a column
                    Button { 
                        icon {
                            source: "backend_resources/icons/bars.svg"; 
                            color: root.textColor; height: 32; width: 32 
                        }
                        background: Rectangle { 
                            implicitWidth: 48
                            implicitHeight: 48
                            color: root.menuColor 
                        }
                        onClicked: menuNav.close()
                    }
                    // Customized button defined in MenuButton.qml: assign text, page index (0,1,2...), and icon source below
                    MenuButton { text: "Homepage"; pageIndex: 0; iconURL: "backend_resources/icons/house.svg"}
                    MenuButton { text: "3D Viewer"; pageIndex: 1; iconURL: "backend_resources/icons/cube-solid.svg" }
                    MenuButton { text: "2D Projection Comparison"; pageIndex: 2; iconURL: "backend_resources/icons/camera-retro-solid.svg" }
                    MenuButton { text: "3D Comparison"; pageIndex: 3; iconURL: "backend_resources/icons/cubes-solid.svg" }
                    MenuButton { text: "Coming Soon"; pageIndex: 0; iconURL: "backend_resources/icons/diagram-project-solid.svg" }
                    MenuButton { text: "Coming Soon"; pageIndex: 0; iconURL: "backend_resources/icons/diagram-project-solid.svg" }
                    MenuButton { text: "Coming Soon"; pageIndex: 0; iconURL: "backend_resources/icons/diagram-project-solid.svg" }
                    MenuButton { text: "Coming Soon"; pageIndex: 0; iconURL: "backend_resources/icons/diagram-project-solid.svg" }
                    MenuButton { text: "Coming Soon"; pageIndex: 0; iconURL: "backend_resources/icons/diagram-project-solid.svg" }
                    MenuButton { text: "Coming Soon"; pageIndex: 0; iconURL: "backend_resources/icons/diagram-project-solid.svg" }
                    MenuButton { text: "Coming Soon"; pageIndex: 0; iconURL: "backend_resources/icons/diagram-project-solid.svg" }
                    MenuButton { text: "Coming Soon"; pageIndex: 0; iconURL: "backend_resources/icons/diagram-project-solid.svg" }
                    MenuButton { text: "Coming Soon"; pageIndex: 0; iconURL: "backend_resources/icons/diagram-project-solid.svg" }
                    MenuButton { text: "Coming Soon"; pageIndex: 0; iconURL: "backend_resources/icons/diagram-project-solid.svg" }
                    MenuButton { text: "Coming Soon"; pageIndex: 0; iconURL: "backend_resources/icons/diagram-project-solid.svg" }
                    MenuButton { text: "Coming Soon"; pageIndex: 0; iconURL: "backend_resources/icons/diagram-project-solid.svg" }
                    MenuButton { text: "Coming Soon"; pageIndex: 0; iconURL: "backend_resources/icons/diagram-project-solid.svg" }
                }
            }
        }
    }
}
