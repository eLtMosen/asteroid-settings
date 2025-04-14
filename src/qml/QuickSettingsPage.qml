/*
 * Copyright (C) 2025 Timo Könnecke <github.com/eLtMosen>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9
import org.asteroid.controls 1.0
import Nemo.Configuration 1.0

Item {
    id: settingsPage

    // ConfigurationValue for slots
    ConfigurationValue { id: topSlot1; key: "/desktop/asteroid/quicksettings/top/slot1"; defaultValue: "lockButton" }
    ConfigurationValue { id: topSlot2; key: "/desktop/asteroid/quicksettings/top/slot2"; defaultValue: "settingsButton" }
    ConfigurationValue { id: topSlot3; key: "/desktop/asteroid/quicksettings/top/slot3"; defaultValue: "" }
    ConfigurationValue { id: mainSlot1; key: "/desktop/asteroid/quicksettings/main/slot1"; defaultValue: "brightnessToggle" }
    ConfigurationValue { id: mainSlot2; key: "/desktop/asteroid/quicksettings/main/slot2"; defaultValue: "bluetoothToggle" }
    ConfigurationValue { id: mainSlot3; key: "/desktop/asteroid/quicksettings/main/slot3"; defaultValue: "hapticsToggle" }
    ConfigurationValue { id: mainSlot4; key: "/desktop/asteroid/quicksettings/main/slot4"; defaultValue: "wifiToggle" }
    ConfigurationValue { id: mainSlot5; key: "/desktop/asteroid/quicksettings/main/slot5"; defaultValue: "soundToggle" }
    ConfigurationValue { id: mainSlot6; key: "/desktop/asteroid/quicksettings/main/slot6"; defaultValue: "cinemaToggle" }

    // Toggle definitions
    property var toggleOptions: [
        { id: "lockButton", name: qsTrId("id-toggle-lock"), icon: "ios-unlock" },
        { id: "settingsButton", name: qsTrId("id-toggle-settings"), icon: "ios-settings" },
        { id: "brightnessToggle", name: qsTrId("id-toggle-brightness"), icon: "ios-sunny" },
        { id: "bluetoothToggle", name: qsTrId("id-toggle-bluetooth"), icon: "ios-bluetooth" },
        { id: "hapticsToggle", name: qsTrId("id-toggle-haptics"), icon: "ios-watch-vibrating" },
        { id: "wifiToggle", name: qsTrId("id-toggle-wifi"), icon: "ios-wifi-outline" },
        { id: "soundToggle", name: qsTrId("id-toggle-sound"), icon: "ios-sound-indicator-high" },
        { id: "cinemaToggle", name: qsTrId("id-toggle-cinema"), icon: "ios-film-outline" }
    ]

    property string rowHeight: Dims.h(16)
    property int draggedItemIndex: -1  // The index of the item being dragged
    property int targetIndex: -1       // The target index where item will be dropped

    // Helper functions to replace Array.find
    function findToggle(toggleId) {
        for (var i = 0; i < toggleOptions.length; i++) {
            if (toggleOptions[i].id === toggleId) {
                return toggleOptions[i];
            }
        }
        return null;
    }

    function getToggleName(toggleId) {
        var toggle = findToggle(toggleId);
        return toggle ? toggle.name : qsTrId("id-empty-slot");
    }

    function getToggleIcon(toggleId) {
        var toggle = findToggle(toggleId);
        return toggle ? toggle.icon : "";
    }

    // Keep original data for reordering
    property var originalData: []

    function storeOriginalData() {
        originalData = [];
        for (var i = 0; i < slotModel.count; i++) {
            originalData.push({
                toggleId: slotModel.get(i).toggleId,
                listView: slotModel.get(i).listView,
                slot: slotModel.get(i).slot
            });
        }
    }

    PageHeader {
        id: title
        //% "Quick Settings"
        text: qsTrId("id-quicksettings")
    }

    ListModel {
        id: slotModel
        Component.onCompleted: {
            append([
                { toggleId: topSlot1.value, listView: "top", slot: topSlot1 },
                { toggleId: topSlot2.value, listView: "top", slot: topSlot2 },
                { toggleId: topSlot3.value, listView: "top", slot: topSlot3 },
                { toggleId: mainSlot1.value, listView: "main", slot: mainSlot1 },
                { toggleId: mainSlot2.value, listView: "main", slot: mainSlot2 },
                { toggleId: mainSlot3.value, listView: "main", slot: mainSlot3 },
                { toggleId: mainSlot4.value, listView: "main", slot: mainSlot4 },
                { toggleId: mainSlot5.value, listView: "main", slot: mainSlot5 },
                { toggleId: mainSlot6.value, listView: "main", slot: mainSlot6 }
            ]);
            storeOriginalData();
        }
    }

    Column {
        anchors.fill: parent

        Item { width: parent.width; height: Dims.l(20) }

        ListView {
            id: slotList
            width: parent.width
            anchors {
                top: parent.top
                topMargin: Dims.l(20)
                bottom: parent.bottom
            }
            clip: true
            interactive: draggedItemIndex === -1 // Only allow scrolling when not dragging
            model: slotModel

            // Auto-scroll when dragging near edges
            Timer {
                id: scrollTimer
                interval: 16
                repeat: true
                running: draggedItemIndex !== -1

                onTriggered: {
                    if (dragProxy.y < slotList.height * 0.2) {
                        // Scroll up
                        slotList.contentY = Math.max(0, slotList.contentY - 5);
                    } else if (dragProxy.y > slotList.height * 0.8) {
                        // Scroll down
                        slotList.contentY = Math.min(
                            slotList.contentHeight - slotList.height,
                            slotList.contentY + 5
                        );
                    }

                    // Continuously check which item is under the drag proxy
                    if (draggedItemIndex !== -1) {
                        var dragCenterY = dragProxy.y + dragProxy.height / 2;
                        for (var i = 0; i < slotList.count; i++) {
                            var item = slotList.itemAt(0, slotList.contentY + dragCenterY);
                            if (item) {
                                var newTargetIndex = item.visualIndex;
                                if (newTargetIndex !== targetIndex && newTargetIndex !== -1) {
                                    targetIndex = newTargetIndex;
                                    // Move items in the UI
                                    moveItems();
                                }
                                break;
                            }
                        }
                    }
                }
            }

            // Global function to animate position changes of ListView items
            displaced: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: 120
                    easing.type: Easing.InOutQuad
                }
            }

            delegate: Item {
                id: delegateItem
                width: parent.width
                height: rowHeight
                property int visualIndex: index
                property bool isDragging: index === draggedItemIndex

                // Measure content width dynamically
                Text {
                    id: labelMeasure
                    text: getToggleName(toggleId)
                    font.pixelSize: Dims.l(8)
                    visible: false // Hidden, used for sizing
                }

                Rectangle {
                    id: slotRect
                    height: rowHeight - Dims.l(2)
                    width: Dims.w(14) + (Dims.w(8) * 2) + labelMeasure.width // icon + doubled padding + label
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#222222"
                    opacity: 0.4 // Only background
                    radius: height / 2 // Pill-shaped
                    visible: !isDragging
                }

                // Content above background
                Row {
                    anchors.centerIn: slotRect
                    spacing: Dims.w(2)

                    Rectangle {
                        width: Dims.w(14)
                        height: Dims.w(14)
                        radius: width / 2
                        color: "#222222"
                        opacity: 0.7 // Toggled QuickSettingsToggle alpha

                        Icon {
                            id: toggleIcon
                            name: getToggleIcon(toggleId)
                            width: Dims.w(10)
                            height: Dims.w(10)
                            anchors.centerIn: parent
                            color: "#ffffff"
                            visible: toggleId !== ""
                        }
                    }

                    Label {
                        text: getToggleName(toggleId)
                        font.pixelSize: Dims.l(8)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Timer {
                    id: longPressTimer
                    interval: 400  // Hold for 400ms to start dragging
                    repeat: false
                    running: false

                    onTriggered: {
                        // Start drag after the timer expires
                        dragArea.startDrag();
                    }
                }

                MouseArea {
                    id: dragArea
                    anchors.fill: parent

                    property point startPos: Qt.point(0, 0)
                    property bool dragging: false

                    function startDrag() {
                        if (!dragging) {
                            dragging = true;
                            draggedItemIndex = index;
                            targetIndex = index;

                            // Store original item positions for potential restoration
                            storeOriginalData();

                            // Position the drag proxy
                            dragProxy.x = slotRect.x;
                            dragProxy.y = delegateItem.mapToItem(slotList, 0, 0).y;
                            dragProxy.width = slotRect.width;
                            dragProxy.height = slotRect.height;
                            dragProxy.text = getToggleName(toggleId);
                            dragProxy.icon = getToggleIcon(toggleId);
                            dragProxy.visible = true;
                        }
                    }

                    onPressed: {
                        startPos = Qt.point(mouse.x, mouse.y);
                        longPressTimer.start();
                    }

                    onPositionChanged: {
                        if (dragging) {
                            // Update position of drag proxy
                            var pos = mapToItem(slotList, mouse.x, mouse.y);
                            dragProxy.y = pos.y - dragProxy.height/2;
                        } else if (Math.abs(mouse.x - startPos.x) > 10 || Math.abs(mouse.y - startPos.y) > 10) {
                            // If moved significantly without starting drag, cancel the long press timer
                            longPressTimer.stop();
                        }
                    }

                    onReleased: {
                        longPressTimer.stop();

                        if (dragging) {
                            dragging = false;

                            // Finalize the move and update configuration
                            if (targetIndex !== -1 && draggedItemIndex !== targetIndex) {
                                finalizeMove();
                            }

                            dragProxy.visible = false;
                            draggedItemIndex = -1;
                            targetIndex = -1;
                        }
                    }

                    onCanceled: {
                        longPressTimer.stop();
                        if (dragging) {
                            dragging = false;
                            dragProxy.visible = false;

                            // Restore the original positions
                            restoreOriginalOrder();

                            draggedItemIndex = -1;
                            targetIndex = -1;
                        }
                    }
                }
            }

            // Drag visual proxy (follows the finger)
            Rectangle {
                id: dragProxy
                visible: false
                z: 10
                color: "#AA222222"
                border.width: Dims.l(1)
                border.color: "#222222"
                radius: height / 2
                height: rowHeight
                property string text: ""
                property string icon: ""

                Row {
                    anchors.centerIn: parent
                    spacing: Dims.w(2)

                    Rectangle {
                        width: Dims.w(14)
                        height: Dims.w(14)
                        radius: width / 2
                        color: "#222222"

                        Icon {
                            name: dragProxy.icon
                            width: Dims.w(10)
                            height: Dims.w(10)
                            anchors.centerIn: parent
                            color: "#ffffff"
                            visible: dragProxy.icon !== ""
                        }
                    }

                    Label {
                        text: dragProxy.text
                        font.pixelSize: Dims.l(8)
                        color: "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    // Function to visually move items during drag
    function moveItems() {
        if (draggedItemIndex === -1 || targetIndex === -1 || draggedItemIndex === targetIndex) {
            return;
        }

        // Move item in the model (for visual display and storage)
        slotModel.move(draggedItemIndex, targetIndex, 1);

        // Update ConfigurationValue immediately
        var slots = [topSlot1, topSlot2, topSlot3, mainSlot1, mainSlot2, mainSlot3, mainSlot4, mainSlot5, mainSlot6];
        for (var i = 0; i < slotModel.count; i++) {
            var item = slotModel.get(i);
            slots[i].value = item.toggleId;
        }

        // Clear duplicates (keep first occurrence)
        var topIds = [];
        var mainIds = [];
        for (i = 0; i < slotModel.count; i++) {
            var id = slotModel.get(i).toggleId;
            if (i < 3) {
                if (id && topIds.includes(id)) {
                    slotModel.setProperty(i, "toggleId", "");
                    slots[i].value = "";
                } else {
                    topIds.push(id);
                }
            } else {
                if (id && mainIds.includes(id)) {
                    slotModel.setProperty(i, "toggleId", "");
                    slots[i].value = "";
                } else {
                    mainIds.push(id);
                }
            }
        }

        // Update draggedItemIndex to new position
        draggedItemIndex = targetIndex;

        // Store new state as original data
        storeOriginalData();
    }

    // Function to finalize the move
    function finalizeMove() {
        // No additional storage needed; moveItems handles it
    }

    // Function to restore original order if drag is cancelled
    function restoreOriginalOrder() {
        // Clear the model and repopulate with original data
        slotModel.clear();
        for (var i = 0; i < originalData.length; i++) {
            slotModel.append(originalData[i]);
        }
    }
}
