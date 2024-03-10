/*
    Copyright 2018 - 2019 Benjamin Vedder	benjamin@vedder.se

    This file is part of VESC Tool.

    VESC Tool is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    VESC Tool is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    */

import QtQuick 2.7
import QtQuick.Controls 2.10
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.3 as Dl

import Vedder.vesc.vescinterface 1.0
import Vedder.vesc.commands 1.0
import Vedder.vesc.configparams 1.0
import Vedder.vesc.utility 1.0

Item {
    id: appPageItem
    property Commands mCommands: VescIf.commands()
    property bool isHorizontal: width > height

    ParamEditors {
        id: editors
    }

    Dialog {
        id: ppmMap
        title: "PPM Mapping"
        standardButtons: Dialog.Close
        modal: true
        focus: true

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        width: parent.width - 20
        closePolicy: Popup.CloseOnEscape
        x: 10
        y: (parent.height - height) / 2
        parent: ApplicationWindow.overlay

        PpmMap {
            anchors.fill: parent
        }
    }

    Dialog {
        id: adcMap
        title: "ADC Mapping"
        standardButtons: Dialog.Close
        modal: true
        focus: true

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        width: parent.width - 20
        closePolicy: Popup.CloseOnEscape
        x: 10
        y: parent.height / 2 - height / 2
        parent: ApplicationWindow.overlay

        AdcMap {
            anchors.fill: parent
        }
    }

    Dialog {
        id: nrfPair
        title: "NRF Pairing"
        standardButtons: Dialog.Close
        modal: true
        focus: true

        Overlay.modal: Rectangle {
            color: "#AA000000"
        }

        width: parent.width - 20
        closePolicy: Popup.CloseOnEscape
        x: 10
        y: parent.height / 2 - height / 2
        parent: ApplicationWindow.overlay

        NrfPair {
            anchors.fill: parent
        }
    }

    onIsHorizontalChanged: {
        updateEditors()
    }

    function addSeparator(text) {
        var e = editors.createSeparator(scrollCol, text)
        e.Layout.columnSpan = isHorizontal ? 2 : 1
    }

    function destroyEditors() {
        for(var i = scrollCol.children.length;i > 0;i--) {
            scrollCol.children[i - 1].destroy(1) // Only works with delay on android, seems to be a bug
        }
    }

    function createEditorApp(param) {
        var e = editors.createEditorApp(scrollCol, param)
        e.Layout.preferredWidth = 500
        e.Layout.fillsWidth = true
    }

    function updateEditors() {
        destroyEditors()

        var params = VescIf.appConfig().getParamsFromSubgroup(pageBox.currentText, tabBox.currentText)

        for (var i = 0;i < params.length;i++) {
            if (params[i].startsWith("::sep::")) {
                addSeparator(params[i].substr(7))
            } else {
                createEditorApp(params[i])
            }
        }
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 0

        GridLayout {
            Layout.fillWidth: true
            columns: isHorizontal ? 2 : 1
            rowSpacing: -5
            ComboBox {
                id: pageBox
                Layout.fillWidth: true

                model: VescIf.appConfig().getParamGroups()

                onCurrentTextChanged: {
                    var tabTextOld = tabBox.currentText
                    var subgroups = VescIf.appConfig().getParamSubgroups(currentText)

                    tabBox.model = subgroups
                    tabBox.visible = subgroups.length > 1

                    if (tabTextOld === tabBox.currentText && tabTextOld !== "") {
                        updateEditors()
                    }
                }
            }

            ComboBox {
                id: tabBox
                Layout.fillWidth: true

                onCurrentTextChanged: {
                    updateEditors()
                }
            }
        }

        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: column.width
            clip: true

            GridLayout {
                id: scrollCol
                anchors.fill: parent
                columns: isHorizontal ? 2 : 1
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Button {
                Layout.preferredWidth: 100
                Layout.fillWidth: true
                text: "Write"

                onClicked: {
                    mCommands.setAppConf()
                }
            }

            Button {
                Layout.preferredWidth: 100
                Layout.fillWidth: true
                text: "Read"

                onClicked: {
                    mCommands.getAppConf()
                }
            }

            Button {
                Layout.preferredWidth: 50
                Layout.fillWidth: true
                text: "..."
                onClicked: menu.open()

                Menu {
                    id: menu
                    bottomPadding: notchBot
                    leftPadding: notchLeft
                    rightPadding: notchRight
                    parent: appPageItem
                    y: parent.height - implicitHeight
                    width: parent.width

                    MenuItem {
                        text: "Read Default Settings"
                        onTriggered: {
                            mCommands.getAppConfDefault()
                        }
                    }
                    MenuItem {
                        text: "PPM Mapping..."
                        onTriggered: {
                            ppmMap.open()
                        }
                    }
                    MenuItem {
                        text: "ADC Mapping..."
                        onTriggered: {
                            adcMap.open()
                        }
                    }
                    MenuItem {
                        text: "Pair NRF..."
                        onTriggered: {
                            nrfPair.open()
                        }
                    }
                    MenuItem {
                        text: "Save XML"
                        onTriggered: {
                            if (Utility.requestFilePermission()) {
                                fileDialogSave.close()
                                fileDialogSave.open()
                            } else {
                                VescIf.emitMessageDialog(
                                            "File Permissions",
                                            "Unable to request file system permission.",
                                            false, false)
                            }
                        }

                        Dl.FileDialog {
                            id: fileDialogSave
                            title: "Please choose a file"
                            nameFilters: ["*"]
                            selectExisting: false
                            selectMultiple: false
                            onAccepted: {
                                var path = fileUrl.toString()
                                if (!path.toLowerCase().endsWith(".xml")) {
                                    path += ".xml"
                                }

                                if (VescIf.appConfig().saveXml(path, "APPConfiguration")) {
                                    VescIf.emitStatusMessage("Appconf Saved", true)
                                } else {
                                    VescIf.emitStatusMessage("Appconf Save Failed", false)
                                }

                                close()
                                parent.forceActiveFocus()
                            }
                            onRejected: {
                                close()
                                parent.forceActiveFocus()
                            }
                        }
                    }
                    MenuItem {
                        text: "Load XML"
                        onTriggered: {
                            if (Utility.requestFilePermission()) {
                                fileDialogLoad.close()
                                fileDialogLoad.open()
                            } else {
                                VescIf.emitMessageDialog(
                                            "File Permissions",
                                            "Unable to request file system permission.",
                                            false, false)
                            }
                        }

                        Dl.FileDialog {
                            id: fileDialogLoad
                            title: "Please choose a file"
                            nameFilters: ["*"]
                            selectExisting: true
                            selectMultiple: false
                            onAccepted: {
                                var path = fileUrl.toString()
                                if (VescIf.appConfig().loadXml(path, "APPConfiguration")) {
                                    VescIf.emitStatusMessage("Appconf Loaded", true)
                                } else {
                                    VescIf.emitStatusMessage("Appconf Load Failed", false)
                                }

                                close()
                                parent.forceActiveFocus()
                            }
                            onRejected: {
                                close()
                                parent.forceActiveFocus()
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: VescIf
        function onConfigurationChanged() {
            pageBox.model = VescIf.appConfig().getParamGroups()

            var tabTextOld = tabBox.currentText
            var subgroups = VescIf.appConfig().getParamSubgroups(pageBox.currentText)

            tabBox.model = subgroups
            tabBox.visible = subgroups.length > 1

            updateEditors()
        }
    }
}
