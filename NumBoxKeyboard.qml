import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: dialog

    // Properties
    property string label: qsTr("Input Number")
    property string textBtOK: qsTr("OK")
    property string textBtCancel: qsTr("Cancel")
    property real minimumValue: -999999
    property real maximumValue: 999999
    property int precision: 6
    property int decimals: 2
    property string placeholderValue: "0"
    property bool enableSequenceGrid: false
    property real sequenceStep: 1
    property alias antialiasing: dialogPanel.antialiasing
    property real minimumDialogHeight: 455
    property real minimumDialogWidth: 600
    property color buttonsColorDlgOn: Qt.rgba(0.1, 0.6, 0.1, 1.0)
    property color buttonsColorDlgOff: Qt.rgba(0.8, 0.8, 0.8, 1.0)
    property color buttonsTextColorDlg: "white"
    property color buttonsTextColorDlgOff: "black"
    property color displayBackground: "#F8F9FA"
    property color displayBorderColor: "#E0E0E0"
    property color displayTextColor: "black"
    property color displayPlaceholderTextColor: "gray"
    property string displayText: qsTr("Value:")
    property string measurement: " Kg"

    property string value: ""
    property bool flag_minus: false
    property string placeholderSafeValue: dialog.toPosixTextValue(dialog.placeholderValue)

    // Triggers
    property bool trigger_0: false
    property bool trigger_1: false
    property bool trigger_2: false
    property bool trigger_3: false
    property bool trigger_4: false
    property bool trigger_5: false
    property bool trigger_6: false
    property bool trigger_7: false
    property bool trigger_8: false
    property bool trigger_9: false
    property bool trigger_dote: false
    property bool trigger_minus_btn: false
    property bool trigger_bksp: false
    property bool trigger_clear: false
    property bool trigger_ftsp: false
    property bool trigger_copy: false
    property bool trigger_paste: false

    // Signals
    signal ok(var number, var equal)
    signal cancel()

    // Internal variables
    property string localeDecimal: Qt.locale().decimalPoint
    property string localeGroup: Qt.locale().groupSeparator
    property int systemLocaleDecimalChar: 46
    property string systemLocaleDecimalStr: "."
    property string valueSafe: ""

    // Functions
    function getSystemLocaleDecimalChar() { return systemLocaleDecimalStr; }

    function toPosixTextValue(valueStr) {
        if (valueStr.length === 0) return valueStr;
        let result = valueStr.replace(localeDecimal, '.').replace(localeGroup, '');
        if (result === localeDecimal) result = "0";
        return result;
    }

    function toLocaleTextValue(valueStr) {
        if (valueStr.length === 0) return valueStr;
        return valueStr.replace('.', localeDecimal);
    }

    function getAbsValueStr(valueStr) {
        if (valueStr.length > 0 && valueStr.charAt(0) === '-') return valueStr.substring(1);
        return valueStr;
    }

    function getValueStr(valueStr) {
        if (valueStr.length === 0) return valueStr;
        const absValue = dialog.getAbsValueStr(valueStr);
        if (dialog.flag_minus) return '-' + absValue;
        return absValue;
    }

    function roundPlus(x, n) {
        if (isNaN(x) || isNaN(n)) return NaN;
        const m = Math.pow(10, n);
        return Math.round(x * m) / m;
    }

    function isNumericChar(chr) {
        const code = chr.charCodeAt(0);
        return (code >= 48 && code <= 57);
    }

    function isNumberInLimits() {
        if (dialog.value.length === 0) return false;
        const check_value_str = dialog.toPosixTextValue(dialog.value);
        if (isNaN(parseFloat(check_value_str))) return false;
        const check_value = dialog.roundPlus(parseFloat(check_value_str), dialog.precision);
        if (!dialog.flag_minus) {
            if (check_value > dialog.maximumValue) return false;
        } else {
            if (check_value < dialog.minimumValue) return false;
        }
        return true;
    }

    function isBtSymbolCorrect(symbols) {
        let result = false;

        switch (symbols) {
            // Alg 1. - Check for range, precision and multiplicity for digits
            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
            {
                let candidate = dialog.value + symbols;

                if (dialog.value.length === 0 && symbols === '0') {
                    candidate = '0';
                }

                if (dialog.value.length === 1 && dialog.value === "0" && dialog.isNumericChar(symbols)) {
                    candidate = symbols;
                }

                let numStr = dialog.flag_minus ? ('-' + candidate) : candidate;
                let num = parseFloat(numStr);

                if (isNaN(num)) {
                    result = false;
                    break;
                }

                if (num < dialog.minimumValue || num > dialog.maximumValue) {
                    result = false;
                    break;
                }

                if (dialog.enableSequenceGrid) {
                    let rounded = dialog.roundPlus(num, dialog.precision);
                    let step = dialog.sequenceStep;
                    let diff = Math.abs(rounded % step);
                    // Допускаем погрешность float
                    if (diff > 1e-10 && Math.abs(diff - step) > 1e-10) {
                        result = false;
                        break;
                    }
                }

                if (candidate.split('.').length > 2) {
                    result = false;
                    break;
                }

                result = true;
                break;
            }

            // Alg 2. - Dot
            case '.':
            {
                if (dialog.precision <= 0) {
                    result = false;
                    break;
                }
                if (dialog.value.indexOf(dialog.getSystemLocaleDecimalChar()) !== -1) {
                    result = false; // Уже есть точка
                    break;
                }
                let candidate = dialog.value + '.';
                let numStr = dialog.flag_minus ? ('-' + candidate) : candidate;
                let num = parseFloat(numStr);
                if (isNaN(num)) {
                    result = false;
                    break;
                }
                if (num < dialog.minimumValue || num > dialog.maximumValue) {
                    result = false;
                    break;
                }
                result = true;
                break;
            }

            // Alg 3. - Minus
            case '-':
            {
                if (dialog.minimumValue >= 0) {
                    result = false;
                    break;
                }
                if (dialog.value.length === 0) {
                    result = false;
                    break;
                }
                let num = -parseFloat(dialog.value);
                if (isNaN(num) || num < dialog.minimumValue || num > dialog.maximumValue) {
                    result = false;
                    break;
                }
                result = true;
                break;
            }

            // Alg 4. - '#' (Restore placeholder)
            case '#':
            {
                result = (dialog.placeholderSafeValue.length > 0);
                break;
            }

            // Alg 5. - 'C' (Clear)
            case 'C':
            {
                result = (dialog.value.length > 0);
                break;
            }

            // Alg 6. - '<' (Backspace)
            case '<':
            {
                result = (dialog.value.length > 0);
                break;
            }

            default:
                result = false;
                break;
        }

        return result;
    }

    function fixScale() {
        if (dialog.height < dialog.minimumDialogHeight || dialog.width < dialog.minimumDialogWidth) {
            return Math.min(dialog.height / dialog.minimumDialogHeight, dialog.width / dialog.minimumDialogWidth);
        }
        return 1.0;
    }

    function getGoldenMin(size) { return size * 514229.0 / 832040.0; }
    function getGoldenMax(size) { return size * 1.618033988749; }

    function putSymbol(sym) {
        if (isBtSymbolCorrect(sym)) {
            if (dialog.value.length === 0 && sym === '.') dialog.value = "0";
            if (dialog.value.length === 1 && dialog.value.charAt(0) === '0' && dialog.isNumericChar(sym)) {
                dialog.value = dialog.value.substring(1);
            }
            dialog.value = dialog.value + sym;
            textValue.text = dialog.value.length > 0
                ? (dialog.getValueStr(dialog.value) + dialog.measurement)
                : (dialog.placeholderValue + dialog.measurement);
            textValue.color = dialog.value.length > 0
                ? dialog.displayTextColor
                : dialog.displayPlaceholderTextColor;
        }
    }

    function backspSymbol() {
        if (dialog.value.length === 0) return false;
        const lastIndex = dialog.value.length - 1;
        dialog.value = dialog.value.substring(0, lastIndex);
        textValue.text = dialog.value.length > 0
            ? (dialog.getValueStr(dialog.value) + dialog.measurement)
            : (dialog.placeholderValue + dialog.measurement);
        textValue.color = dialog.value.length > 0
            ? dialog.displayTextColor
            : dialog.displayPlaceholderTextColor;
        return true;
    }

    function clear() {
        dialog.value = "";
        textValue.text = dialog.placeholderValue + dialog.measurement;
        textValue.color = dialog.displayPlaceholderTextColor;
    }

    function copyValue() {
        clipboardHelper.copy(dialog.getValueStr(dialog.value));
        trigger_copy = true;
        Qt.callLater(function() { trigger_copy = false; });
    }

    function pastValue() {
        if (clipboardHelper.canPast()) {
            const buffer = clipboardHelper.past();
            const conv_text = dialog.toPosixTextValue(buffer);
            let real_value = parseFloat(conv_text);
            if (!isNaN(real_value)) {
                real_value = dialog.roundPlus(real_value, dialog.precision);
                const check_limit = dialog.roundPlus(real_value, dialog.decimals);
                if (real_value >= dialog.minimumValue && real_value <= dialog.maximumValue) {
                    dialog.flag_minus = (real_value < 0);
                    dialog.value = Math.abs(real_value).toString();
                    textValue.text = dialog.getValueStr(dialog.value) + dialog.measurement;
                    textValue.color = dialog.displayTextColor;
                    trigger_paste = true;
                    Qt.callLater(function() { trigger_paste = false; });
                }
            }
        }
    }

    function isPlaceholderSigned() {
        if (dialog.placeholderSafeValue.length > 1) {
            if (dialog.placeholderSafeValue.charAt(0) === '-') {
                return true;
            }
        }
        return false;
    }

    function func_autoselect_flag_minus() {
        if (dialog.minimumValue < 0 && dialog.maximumValue < 0) return true;
        if (dialog.minimumValue < 0 && dialog.maximumValue >= 0) {
            if (placeholderValue.length > 0) {
                if (Math.floor(parseFloat(dialog.placeholderValue)) >= 0) {
                    return false;
                } else {
                    return true;
                }
            } else {
                if (Math.abs(dialog.minimumValue * 2 / 3) > dialog.maximumValue) {
                    return true;
                } else {
                    return false;
                }
            }
        }
        return false;
    }

    function isValueEqualToPlaceholder() {
        const currentVal = dialog.getValueStr(dialog.value);
        const placeVal = dialog.getValueStr(dialog.placeholderSafeValue);
        return currentVal === placeVal;
    }

    function show(val, is_placeholder) {
        if (typeof(is_placeholder) === 'undefined') is_placeholder = true;
        if (typeof(val) === 'undefined') val = "";

        let tmpValue = val ? dialog.getAbsValueStr(val) : "";
        dialogPanel.visible = true;

        if (!is_placeholder && tmpValue.length > 0) {
            dialog.value = tmpValue;
            dialog.flag_minus = (val.charAt(0) === '-');
        } else {
            dialog.value = "";
            dialog.flag_minus = is_placeholder
                ? dialog.isPlaceholderSigned()
                : dialog.func_autoselect_flag_minus();
        }

        textValue.text = dialog.value.length > 0
            ? (dialog.getValueStr(dialog.value) + dialog.measurement)
            : (dialog.placeholderValue + dialog.measurement);
        textValue.color = dialog.value.length > 0
            ? dialog.displayTextColor
            : dialog.displayPlaceholderTextColor;
    }

    function hide() { dialogPanel.visible = false; }

    function isVisible() { return dialogPanel.visible; }

    function executeOk(arg_number, is_equal_placeholder) {
        if (typeof(is_equal_placeholder) === 'undefined') is_equal_placeholder = false;
        if (typeof(arg_number) === 'undefined') arg_number = dialog.getValueStr(dialog.value);
        dialog.ok(arg_number, is_equal_placeholder);
    }

    function executeCancel() {
        dialog.cancel();
    }

    // Clipboard Helper
    Item {
        id: clipboardHelper
        opacity: 0
        property alias buffer: helper.text
        function copy(text) { buffer = text; helper.selectAll(); helper.copy(); }
        function cut(text) { buffer = text; helper.selectAll(); helper.cut(); }
        function canPast() { return helper.canPaste; }
        function past() {
            if (helper.canPaste) {
                buffer = " ";
                helper.selectAll();
                helper.paste();
                return buffer;
            }
            return "";
        }
        TextEdit { id: helper; text: "" }
    }

    // Shadow
    Rectangle {
        id: dialogMsgShadow
        visible: dialogPanel.visible
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.3)
        antialiasing: true
        MouseArea { anchors.fill: parent }
    }

    // Dialog Panel
    Rectangle {
        id: dialogPanel
        anchors.centerIn: parent
        scale: dialog.fixScale()
        height: 455
        width: 600
        visible: false
        antialiasing: true
        color: "#FAFAFA"
        radius: 12
        border.color: "#E0E0E0"
        border.width: 1
        focus: true
        onVisibleChanged: {
            if (visible === true) { Keys.enabled = true; }
            dialogPanel.forceActiveFocus();
        }

        Menu {
            id: serviceMenu
            MenuItem {
                text: qsTr("Copy")
                enabled: ((dialog.value.length > 0) || (dialog.placeholderSafeValue.length > 0))
                onTriggered: { dialog.copyValue(); dialogPanel.forceActiveFocus(); }
            }
            MenuItem {
                text: qsTr("Paste")
                enabled: clipboardHelper.canPast()
                onTriggered: { dialog.pastValue(); dialogPanel.forceActiveFocus(); }
            }
        }

        MouseArea {
            id: textArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        // Content Panel
        ColumnLayout {
            id: contentDialogPanel
            height: parent.height
            width: parent.width
            spacing: 10
            anchors.margins: 10

            // Label Panel
            Row {
                id: rowLabelPanel
                height: 0.1 * contentDialogPanel.height
                width: parent.width
                spacing: 0
                Label {
                    id: labelDialog
                    width: parent.width
                    height: parent.height
                    color: "black"
                    text: label
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 16
                    font.bold: true
                }
            }

            // Display Panel (Enhanced)
            RowLayout {
                id: rowDisplayPanel
                width: contentDialogPanel.width
                Layout.preferredHeight: contentDialogPanel.height * 0.15
                Layout.alignment: Qt.AlignHCenter

                // Display Field (Modern Style)
                Rectangle {
                    id: displayTextDisplay
                    color: dialog.displayBackground
                    border.color: dialog.displayBorderColor
                    border.width: 1
                    radius: 8
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height
                    Layout.alignment: Qt.AlignVCenter
                    antialiasing: true

                    Label {
                        id: textValue
                        text: dialog.value.length > 0
                               ? (dialog.getValueStr(dialog.value) + dialog.measurement)
                               : (dialog.placeholderValue + dialog.measurement)
                        color: dialog.value.length > 0
                               ? dialog.displayTextColor
                               : dialog.displayPlaceholderTextColor
                        anchors.fill: parent
                        anchors.margins: 12
                        font.pixelSize: 22
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onClicked: { if (mouse.button === Qt.RightButton) serviceMenu.open(); }
                    }
                }
            }

            // Grid Layout for Buttons
            GridLayout {
                id: gridDigits
                columns: 3
                rowSpacing: 4
                columnSpacing: 4
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                // Row 0: #, C, <-
                Button {
                    text: "#"
                    Layout.row: 0; Layout.column: 0; Layout.fillWidth: true
                    enabled: dialog.isBtSymbolCorrect('#')
                    onClicked: {
                        if (dialog.value.length > 0) {
                            dialog.value = "";
                            dialog.flag_minus = dialog.func_autoselect_flag_minus();
                        } else {
                            dialog.value = dialog.getAbsValueStr(dialog.placeholderSafeValue);
                            dialog.flag_minus = dialog.isPlaceholderSigned();
                        }
                        textValue.text = dialog.value.length > 0
                            ? (dialog.getValueStr(dialog.value) + dialog.measurement)
                            : (dialog.placeholderValue + dialog.measurement);
                        textValue.color = dialog.value.length > 0
                            ? dialog.displayTextColor
                            : dialog.displayPlaceholderTextColor;
                    }
                }

                Button {
                    text: "C"
                    Layout.row: 0; Layout.column: 1; Layout.fillWidth: true
                    enabled: dialog.isBtSymbolCorrect('C')
                    onClicked: {
                        if (dialog.value.length > 0) dialog.clear();
                        else dialog.flag_minus = dialog.func_autoselect_flag_minus();
                    }
                }

                Button {
                    text: "<"
                    Layout.row: 0; Layout.column: 2; Layout.fillWidth: true
                    enabled: dialog.isBtSymbolCorrect('<')
                    onClicked: dialog.backspSymbol()
                }

                // Row 1: 7, 8, 9
                Button { text: "7"; Layout.row: 1; Layout.column: 0; Layout.fillWidth: true; onClicked: dialog.putSymbol('7'); enabled: dialog.isBtSymbolCorrect('7') }
                Button { text: "8"; Layout.row: 1; Layout.column: 1; Layout.fillWidth: true; onClicked: dialog.putSymbol('8'); enabled: dialog.isBtSymbolCorrect('8') }
                Button { text: "9"; Layout.row: 1; Layout.column: 2; Layout.fillWidth: true; onClicked: dialog.putSymbol('9'); enabled: dialog.isBtSymbolCorrect('9') }

                // Row 2: 4, 5, 6
                Button { text: "4"; Layout.row: 2; Layout.column: 0; Layout.fillWidth: true; onClicked: dialog.putSymbol('4'); enabled: dialog.isBtSymbolCorrect('4') }
                Button { text: "5"; Layout.row: 2; Layout.column: 1; Layout.fillWidth: true; onClicked: dialog.putSymbol('5'); enabled: dialog.isBtSymbolCorrect('5') }
                Button { text: "6"; Layout.row: 2; Layout.column: 2; Layout.fillWidth: true; onClicked: dialog.putSymbol('6'); enabled: dialog.isBtSymbolCorrect('6') }

                // Row 3: 1, 2, 3
                Button { text: "1"; Layout.row: 3; Layout.column: 0; Layout.fillWidth: true; onClicked: dialog.putSymbol('1'); enabled: dialog.isBtSymbolCorrect('1') }
                Button { text: "2"; Layout.row: 3; Layout.column: 1; Layout.fillWidth: true; onClicked: dialog.putSymbol('2'); enabled: dialog.isBtSymbolCorrect('2') }
                Button { text: "3"; Layout.row: 3; Layout.column: 2; Layout.fillWidth: true; onClicked: dialog.putSymbol('3'); enabled: dialog.isBtSymbolCorrect('3') }

                // Row 4: 0, ., +/-
                Button { text: "0"; Layout.row: 4; Layout.column: 0; Layout.fillWidth: true; onClicked: dialog.putSymbol('0'); enabled: dialog.isBtSymbolCorrect('0') }
                Button {
                    text: dialog.getSystemLocaleDecimalChar()
                    Layout.row: 4; Layout.column: 1; Layout.fillWidth: true
                    enabled: dialog.isBtSymbolCorrect('.')
                    onClicked: dialog.putSymbol('.');
                }
                Button {
                    text: "+/-"
                    Layout.row: 4; Layout.column: 2; Layout.fillWidth: true
                    onClicked: {
                        dialog.flag_minus = !dialog.flag_minus;
                        textValue.text = dialog.value.length > 0
                            ? (dialog.getValueStr(dialog.value) + dialog.measurement)
                            : (dialog.placeholderValue + dialog.measurement);
                        textValue.color = dialog.value.length > 0
                            ? dialog.displayTextColor
                            : dialog.displayPlaceholderTextColor;
                    }
                    onPressed: { trigger_minus_btn = true; }
                    onReleased: { trigger_minus_btn = false; }
                }

                // Row 5: OK (span 2) + Cancel (span 1)
                Button {
                    text: dialog.textBtOK
                    Layout.row: 5; Layout.column: 0; Layout.columnSpan: 2; Layout.fillWidth: true
                    enabled: (dialog.value.length > 0) && dialog.isNumberInLimits()
                    onClicked: {
                        dialog.executeOk(dialog.getValueStr(value), dialog.isValueEqualToPlaceholder());
                        dialog.hide();
                    }
                }
                Button {
                    text: dialog.textBtCancel
                    Layout.row: 5; Layout.column: 2; Layout.fillWidth: true
                    enabled: true
                    onClicked: {
                        dialog.executeCancel()
                        dialog.hide();
                    }
                }
            }
        }
    }

    // Keys Handling
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            dialog.executeCancel();
            dialog.hide();
            event.accepted = true;
        }
        else if (event.key === Qt.Key_C && event.modifiers === Qt.ControlModifier) { dialog.copyValue(); event.accepted = true; }
        else if (event.key === Qt.Key_V && event.modifiers === Qt.ControlModifier) { dialog.pastValue(); event.accepted = true; }
        else if (event.key === Qt.Key_0) { trigger_0 = true; }
        else if (event.key === Qt.Key_1) { trigger_1 = true; }
        else if (event.key === Qt.Key_2) { trigger_2 = true; }
        else if (event.key === Qt.Key_3) { trigger_3 = true; }
        else if (event.key === Qt.Key_4) { trigger_4 = true; }
        else if (event.key === Qt.Key_5) { trigger_5 = true; }
        else if (event.key === Qt.Key_6) { trigger_6 = true; }
        else if (event.key === Qt.Key_7) { trigger_7 = true; }
        else if (event.key === Qt.Key_8) { trigger_8 = true; }
        else if (event.key === Qt.Key_9) { trigger_9 = true; }
        else if (event.key === 46 || event.key === 44) { trigger_dote = true; }
        else if (event.key === 45) { trigger_minus_btn = true; }
        else if (event.key === Qt.Key_Backspace) { trigger_bksp = true; }
        else if (event.key === Qt.Key_Delete) { trigger_ftsp = true; }
        else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && btOK && btOK.enabled ) {
            dialog.executeOk(dialog.getValueStr(value), dialog.isValueEqualToPlaceholder());
            dialog.hide();
        }
        else if (event.key === Qt.Key_Space) {
            if (dialog.value.length > 0) { trigger_clear = true; }
            else { trigger_ftsp = true; }
        }
    }

    Keys.onReleased: (event) => {
        if (event.key === Qt.Key_C && event.modifiers === Qt.ControlModifier) {
            trigger_copy = false;
            copyValue();
        }
        else if (event.key === Qt.Key_0) { trigger_0 = false; dialog.putSymbol('0'); }
        else if (event.key === Qt.Key_1) { trigger_1 = false; dialog.putSymbol('1'); }
        else if (event.key === Qt.Key_2) { trigger_2 = false; dialog.putSymbol('2'); }
        else if (event.key === Qt.Key_3) { trigger_3 = false; dialog.putSymbol('3'); }
        else if (event.key === Qt.Key_4) { trigger_4 = false; dialog.putSymbol('4'); }
        else if (event.key === Qt.Key_5) { trigger_5 = false; dialog.putSymbol('5'); }
        else if (event.key === Qt.Key_6) { trigger_6 = false; dialog.putSymbol('6'); }
        else if (event.key === Qt.Key_7) { trigger_7 = false; dialog.putSymbol('7'); }
        else if (event.key === Qt.Key_8) { trigger_8 = false; dialog.putSymbol('8'); }
        else if (event.key === Qt.Key_9) { trigger_9 = false; dialog.putSymbol('9'); }
        else if (event.key === 46 || event.key === 44) { trigger_dote = false; dialog.putSymbol('.'); }
        else if (event.key === 45) {
            if (dialog.isBtSymbolCorrect('-')) {
                trigger_minus_btn = false;
                dialog.flag_minus = !dialog.flag_minus;

                textValue.text = dialog.value.length > 0
                    ? (dialog.getValueStr(dialog.value) + dialog.measurement)
                    : (dialog.placeholderValue + dialog.measurement);
                textValue.color = dialog.value.length > 0
                    ? dialog.displayTextColor
                    : dialog.displayPlaceholderTextColor;
            }
        }
        else if (event.key === Qt.Key_Backspace) {
            if (dialog.isBtSymbolCorrect('<')) {
                trigger_bksp = false;
                dialog.backspSymbol();
                if (dialog.value.length === 0) {
                    dialog.flag_minus = func_autoselect_flag_minus();
                }
            }
        }
        else if (event.key === Qt.Key_Delete) {
            if (dialog.isBtSymbolCorrect('#')) {
                trigger_ftsp = false;
                if (dialog.value.length > 0) {
                    dialog.value = "";
                    dialog.flag_minus = dialog.func_autoselect_flag_minus();
                } else {
                    dialog.value = dialog.getAbsValueStr(dialog.toPosixTextValue(dialog.placeholderSafeValue));
                    dialog.flag_minus = dialog.isPlaceholderSigned();
                }
                textValue.text = dialog.value.length > 0
                    ? (dialog.getValueStr(dialog.value) + dialog.measurement)
                    : (dialog.placeholderValue + dialog.measurement);
                textValue.color = dialog.value.length > 0
                    ? dialog.displayTextColor
                    : dialog.displayPlaceholderTextColor;
            }
        }
        else if (event.key === Qt.Key_Space) {
            if (dialog.isBtSymbolCorrect('#')) {
                if (dialog.value.length > 0) {
                    dialog.value = "";
                    dialog.flag_minus = dialog.func_autoselect_flag_minus();
                } else {
                    dialog.value = dialog.getAbsValueStr(dialog.toPosixTextValue(dialog.placeholderSafeValue));
                    dialog.flag_minus = dialog.isPlaceholderSigned();
                }
                textValue.text = dialog.value.length > 0
                    ? (dialog.getValueStr(dialog.value) + dialog.measurement)
                    : (dialog.placeholderValue + dialog.measurement);
                textValue.color = dialog.value.length > 0
                    ? dialog.displayTextColor
                    : dialog.displayPlaceholderTextColor;
            }
            trigger_clear = false;
            trigger_ftsp = false;
        } else {
            trigger_1 = false; trigger_2 = false; trigger_3 = false;
            trigger_4 = false; trigger_5 = false; trigger_6 = false;
            trigger_7 = false; trigger_8 = false; trigger_9 = false;
            trigger_0 = false; trigger_bksp = false; trigger_ftsp = false;
            trigger_dote = false; trigger_minus_btn = false; trigger_clear = false;
            trigger_copy = false; trigger_paste = false;
        }
    }
}
