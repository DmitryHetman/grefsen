/****************************************************************************
**
** Copyright (C) 2015 The Qt Company Ltd.
** Contact: http://www.qt-project.org/legal
**
** This file is free software; you can redistribute it and/or
** modify it under the terms of the GNU Lesser General Public
** License version 3 as published by the Free Software Foundation
** and appearing in the file LICENSE included in the packaging
** of this file.
**
** This code is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
** GNU Lesser General Public License for more details.
**
****************************************************************************/

import QtQuick 2.6
import QtWayland.Compositor 1.0
import QtGraphicalEffects 1.0
import com.theqtcompany.wlcompositor 1.0

StackableItem {
    id: rootChrome
    property alias surface: surfaceItem.surface
    //property alias valid: surfaceItem.valid
    //property alias explicitlyHidden: surfaceItem.explicitlyHidden
    property alias shellSurface: surfaceItem.shellSurface
    property bool decorationVisible: false

    property alias destroyAnimation : destroyAnimationImpl

    property int marginWidth : surfaceItem.isFullscreen ? 0 : (surfaceItem.isPopup ? 1 : 6)
    property int titlebarHeight : surfaceItem.isPopup || surfaceItem.isFullscreen ? 0 : 25

    height: surfaceItem.height + marginWidth + titlebarHeight
    width: surfaceItem.width + 2 * marginWidth
    visible: surfaceItem.valid

    Rectangle {
        id: decoration
        anchors.fill: parent
        border.width: 1
        radius: marginWidth
        border.color: (resizeArea.pressed || resizeArea.containsMouse) ? "#ffc02020" :"#305070a0"
        color: "#50ffffff"
        visible: rootChrome.decorationVisible && !surfaceItem.isFullscreen

        MouseArea {
            id: resizeArea
            anchors.fill: parent
            hoverEnabled: true
            //cursorShape: Qt.SizeFDiagCursor
            property int pressX
            property int pressY
            property int startW
            property int startH
            property bool pressed: false

            //bitfield: top, left, bottom, right
            property int edges
            onPressed: {
                pressed = true
                edges = 0
                pressX = mouse.x; pressY = mouse.y
                startW = rootChrome.width; startH = rootChrome.height
                if (mouse.y > rootChrome.height - titlebarHeight)
                    edges |= 4 //bottom edge
                if (mouse.x > rootChrome.width - titlebarHeight)
                    edges |= 8 //right edge
            }
            onReleased: pressed = false
            onMouseXChanged: {
                if (pressed) {
                    var w = startW
                    var h = startH
                    if (edges & 8)
                        w += mouse.x - pressX
                    if (edges & 4)
                        h += mouse.y - pressY
                    rootChrome.requestSize(w, h)
                    console.log("resize " + rootChrome + " " + rootChrome.x + ", ", rootChrome.y)
                }
            }
        }

        Item {
            id: titlebar
            anchors.margins: marginWidth
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: titlebarHeight - marginWidth
            visible: !surfaceItem.isPopup

            LinearGradient {
                anchors.fill: parent
                start: Qt.point(0, 0)
                end: Qt.point(0, height)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#50ffffff" }
                    GradientStop { position: 1.0; color: "#e0ffffff" }
                }
            }

            Text {
                color: "gray"
                text: surfaceItem.shellSurface ? surfaceItem.shellSurface.title : ""
                anchors.margins: marginWidth

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            MouseArea {
                id: moveArea
                anchors.fill: parent
                drag.target: rootChrome
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton |Qt.RightButton
                onPressed: {
                    if (mouse.button === Qt.LeftButton) {
                        rootChrome.raise()
                    } else if (mouse.button === Qt.RightButton) {
                        //console.log("right button")
                        // TODO add menu
                    } else if (mouse.button === Qt.MiddleButton) {
                        rootChrome.lower()
                    }
                }
                //cursorShape: Qt.OpenHandCursor
            }

            MouseArea {
                id: closeButton
                visible: !surfaceItem.isTransient
                height: 20
                width: 25
                anchors.margins: marginWidth
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onClicked: shellSurface.surface.client.close()
                hoverEnabled: true
                RectangularGlow {
                    id: effect
                    anchors.fill: closeIcon
                    anchors.margins: 2
                    glowRadius: 5
                    cornerRadius: glowRadius
                    spread: 0.4
                    color: "red"
                    opacity: parent.containsMouse ? 0.5 : 0
                }
                Text {
                    id: closeIcon
                    anchors.centerIn: parent
                    font.pixelSize: parent.height
                    font.family: "FontAwesome"
                    text: "\uf00d"
                }
            }
        }
    }
    function requestSize(w, h) {
        //console.log("request size " + w + ", " + h)
        surfaceItem.shellSurface.sendConfigure(Qt.size(w - 2 * marginWidth, h - titlebarHeight - marginWidth), WlShellSurface.DefaultEdge)
    }

    SequentialAnimation {
        id: destroyAnimationImpl
        ParallelAnimation {
            NumberAnimation { target: scaleTransform; property: "yScale"; to: 2/height; duration: 150 }
            NumberAnimation { target: scaleTransform; property: "xScale"; to: 0.4; duration: 150 }
        }
        NumberAnimation { target: scaleTransform; property: "xScale"; to: 0; duration: 150 }
        ScriptAction { script: { rootChrome.destroy(); } }
    }

    ParallelAnimation {
        id: createAnimationImpl
        NumberAnimation { target: scaleTransform; property: "yScale"; from: 0; to: 1; duration: 150 }
        NumberAnimation { target: scaleTransform; property: "xScale"; from: 0; to: 1; duration: 150 }
    }

    SequentialAnimation {
        id: receivedFocusAnimation
        ParallelAnimation {
            NumberAnimation { target: scaleTransform; property: "yScale"; to: 1.02; duration: 100; easing.type: Easing.OutQuad }
            NumberAnimation { target: scaleTransform; property: "xScale"; to: 1.02; duration: 100; easing.type: Easing.OutQuad }
        }
        ParallelAnimation {
            NumberAnimation { target: scaleTransform; property: "yScale"; to: 1; duration: 100; easing.type: Easing.InOutQuad }
            NumberAnimation { target: scaleTransform; property: "xScale"; to: 1; duration: 100; easing.type: Easing.InOutQuad }
        }
    }

    transform: [
        Scale {
            id:scaleTransform
            origin.x: rootChrome.width / 2
            origin.y: rootChrome.height / 2

        }
    ]

    function findItemForSurface(surface) {
        var result = undefined
        var n = defaultOutput.surfaceArea.children.length
        var i = 0
        for (i = 0; i < n; i++) {
            var item = defaultOutput.surfaceArea.children[i]
            if (item.surface === surface) {
                result = item;
                break;
            }
        }
        return result
    }

    function findPositionForWindow() {
        var screenW = defaultOutput.surfaceArea.width
        var screenH = defaultOutput.surfaceArea.height

        var topLeftTaken = false;
        var n = defaultOutput.surfaceArea.children.length
        var i = 0
        for (i = 0; i < n; i++) {
            var item = defaultOutput.surfaceArea.children[i]
            if (item.width > 10 && item.x < 5 && item.y < 5) {
                topLeftTaken = true
                break;
            }
        }
        if (topLeftTaken) {
            rootChrome.x = Math.random() * screenW
            rootChrome.y = Math.random() * screenH
        }
    }

    function adjustPositionForWindow(xp, yp, w, h) {
        var screenW = defaultOutput.surfaceArea.width
        var screenH = defaultOutput.surfaceArea.height

        var x = Math.min(xp, screenW - w)
        var y = Math.min(yp, screenH - h)

        return Qt.point(x, y)
    }

    ShellSurfaceItem {
        id: surfaceItem
        property bool valid: false
        property bool isPopup: false
        property bool isTransient: false
        property bool isFullscreen: false

        opacity: moveArea.drag.active ? 0.5 : 1.0

        x: marginWidth
        y: titlebarHeight


        function moveRelativeToSurface(surface, relativePosition) {
            var item = findItemForSurface(surface)
            if (item !== undefined) {
                rootChrome.x = relativePosition.x + item.x
                rootChrome.y = relativePosition.y + item.y  + item.titlebarHeight
            }
        }

        Connections {
            target: shellSurface
            ignoreUnknownSignals: true

            onActivatedChanged: { // xdg_shell only
                if (shellSurface.activated)
                    receivedFocusAnimation.start();
            }
            onSetPopup: {
                surfaceItem.isPopup = true
                decoration.visible = false
                surfaceItem.moveRelativeToSurface(parentSurface, relativeToParent)
            }
            onSetTransient: {
                surfaceItem.isTransient = true
                surfaceItem.moveRelativeToSurface(parentSurface, relativeToParent)
            }
            onSetFullScreen: {
                surfaceItem.isFullscreen = true
                rootChrome.x = 0
                rootChrome.y = 0
            }
        }

        onSurfaceDestroyed: {
            view.bufferLock = true;
            destroyAnimationImpl.start();
        }

        onWidthChanged: {
            valid =  !surface.cursorSurface && surface.size.width > 0 && surface.size.height > 0
        }

        onValidChanged: if (valid) {
            if (isFullscreen) {
                rootChrome.requestSize(defaultOutput.surfaceArea.width, defaultOutput.surfaceArea.height)
            } else {
                if (!isTransient) {
                    var w = surface.size.width
                    var h = surface.size.height
                    var pos = adjustPositionForWindow(rootChrome.x, rootChrome.y, w, h)
                    rootChrome.x = pos.x
                    rootChrome.y = pos.y
                }
                createAnimationImpl.start()
            }
        }
    }
}
