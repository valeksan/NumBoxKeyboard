import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: dialog

    // --- Properties ---
    property string label: qsTr("Input Number")
    property string textBtOK: qsTr("OK")
    property string textBtCancel: qsTr("Cancel")
    property real minimumValue: -999999
    property real maximumValue: 999999
    property int precision: 6
    property int decimals: 2
    property string placeholderValue: "0" // Default value shown when empty
    property bool enableSequenceGrid: false
    property real sequenceStep: 1
    property alias antialiasing: dialogPanel.antialiasing
    property real minimumDialogHeight: 455
    property real minimumDialogWidth: 600
    // Display colors (can be customized if not using styles)
    property color displayBackground: "#F8F9FA"
    property color displayBorderColor: "#E0E0E0"
    property color displayTextColor: "black"
    property color displayPlaceholderTextColor: "gray"
    property string measurement: " Kg" // Unit suffix
    // Internal state
    property string value: "" // Absolute value (without sign)
    property bool flag_minus: false // Sign flag
    readonly property string placeholderSafeValue: dialog.toPosixTextValue(dialog.placeholderValue)

    // --- Signals ---
    signal ok(var number, var equal)
    signal cancel()

    // --- Internal variables ---
    property string localeDecimal: Qt.locale().decimalPoint
    property string localeGroup: Qt.locale().groupSeparator
    property int systemLocaleDecimalChar: 46 // Default to '.'
    property string systemLocaleDecimalStr: "."

    // --- Functions ---
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
        return (code >= 48 && code <= 57); // '0' to '9'
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
            // Digits
            case '0': case '1': case '2': case '3': case '4':
            case '5': case '6': case '7': case '8': case '9':
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

            // Decimal Point
            case '.':
            {
                if (dialog.precision <= 0) {
                    result = false;
                    break;
                }
                if (dialog.value.indexOf(dialog.getSystemLocaleDecimalChar()) !== -1) {
                    result = false;
                    break;
                }
                let candidate = dialog.value + '.';
                let numStr = dialog.flag_minus ? ('-' + candidate) : candidate;
                let num = parseFloat(numStr);
                if (isNaN(num) || num < dialog.minimumValue || num > dialog.maximumValue) {
                    result = false;
                    break;
                }
                result = true;
                break;
            }

            // Minus Sign
            case '-':
            {
                if (dialog.minimumValue >= 0 || dialog.value.length === 0) {
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

            // Restore Placeholder ('#' button)
            case '#':
            {
                result = (dialog.placeholderSafeValue.length > 0);
                break;
            }

            // Clear ('C' button)
            case 'C':
            {
                result = (dialog.value.length > 0);
                break;
            }

            // Backspace ('<' button)
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

    function putSymbol(sym) {
        if (isBtSymbolCorrect(sym)) {
            if (dialog.value.length === 0 && sym === '.') dialog.value = "0";
            if (dialog.value.length === 1 && dialog.value.charAt(0) === '0' && dialog.isNumericChar(sym)) {
                dialog.value = dialog.value.substring(1);
            }
            dialog.value = dialog.value + sym;
            updateDisplay();
        }
    }

    function backspSymbol() {
        if (dialog.value.length === 0) return false;
        const lastIndex = dialog.value.length - 1;
        dialog.value = dialog.value.substring(0, lastIndex);
        updateDisplay();
        return true;
    }

    function clear() {
        dialog.value = "";
        updateDisplay();
    }

    function updateDisplay() {
        textValue.text = dialog.value.length > 0
            ? (dialog.getValueStr(dialog.value) + dialog.measurement)
            : (dialog.placeholderValue + dialog.measurement);
        textValue.color = dialog.value.length > 0
            ? dialog.displayTextColor
            : dialog.displayPlaceholderTextColor;
    }

    function show(numberStr, is_placeholder) {
        if (typeof(is_placeholder) === 'undefined') is_placeholder = true;
        if (typeof(numberStr) === 'undefined') numberStr = "";

        let tmpValue = numberStr ? dialog.getAbsValueStr(numberStr) : "";
        dialogPanel.visible = true;

        if (tmpValue) {
            if (is_placeholder) {
                dialog.value = "";
                dialog.flag_minus = (parseFloat(numberStr) < 0);
                dialog.placeholderValue = tmpValue
            } else {
                dialog.value = tmpValue;
                dialog.flag_minus = (parseFloat(numberStr) < 0);
            }
        } else {
            dialog.value = "";
            dialog.flag_minus = dialog.func_autoselect_flag_minus();
        }

        updateDisplay()
    }

    function hide() { dialogPanel.visible = false; }

    function func_autoselect_flag_minus() {
        if (dialog.minimumValue < 0 && dialog.maximumValue < 0) return true;
        if (dialog.minimumValue < 0 && dialog.maximumValue >= 0) {
            if (placeholderValue.length > 0) {
                return Math.floor(parseFloat(dialog.placeholderValue)) < 0;
            } else {
                return Math.abs(dialog.minimumValue * 2 / 3) > dialog.maximumValue;
            }
        }
        return false;
    }

    function isPlaceholderSigned() {
        if (dialog.placeholderSafeValue.length > 1) {
            return dialog.placeholderSafeValue.charAt(0) === '-';
        }
        return false;
    }

    function isValueEqualToPlaceholder() {
        const currentVal = dialog.getValueStr(dialog.value);
        const placeVal = dialog.getValueStr(dialog.placeholderSafeValue);
        return currentVal === placeVal;
    }

    function executeOk(arg_number, is_equal_placeholder) {
        if (typeof(is_equal_placeholder) === 'undefined') is_equal_placeholder = false;
        if (typeof(arg_number) === 'undefined') arg_number = dialog.getValueStr(dialog.value);
        dialog.ok(arg_number, is_equal_placeholder);
    }

    function executeCancel() {
        dialog.cancel();
    }

    // --- Shadow ---
    Rectangle {
        id: dialogMsgShadow
        visible: dialogPanel.visible
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.3)
        antialiasing: true
        MouseArea { anchors.fill: parent }
    }

    // --- Dialog Panel ---
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
            if (visible) { Keys.enabled = true; dialogPanel.forceActiveFocus(); }
        }

        // --- Content Panel ---
        ColumnLayout {
            id: contentDialogPanel
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            // Label
            Label {
                Layout.fillWidth: true
                text: dialog.label
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            // Display
            Rectangle {
                id: displayRect
                Layout.fillWidth: true
                height: contentDialogPanel.height * 0.15
                color: dialog.displayBackground
                border.color: dialog.displayBorderColor
                border.width: 1
                radius: 8
                antialiasing: true

                Label {
                    id: textValue
                    anchors.centerIn: parent
                    anchors.margins: 12
                    text: ""
                    color: dialog.displayPlaceholderTextColor // Default
                    font.pixelSize: 22
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }

            // Grid Layout for Buttons
            GridLayout {
                id: buttonGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 3
                rowSpacing: 4
                columnSpacing: 4

                // Row 0: #, C, <-
                Button { text: "#"; Layout.fillWidth: true; enabled: dialog.isBtSymbolCorrect('#'); onClicked: { if (dialog.value.length > 0) { dialog.clear(); dialog.flag_minus = dialog.func_autoselect_flag_minus(); } else { dialog.value = dialog.getAbsValueStr(dialog.toPosixTextValue(dialog.placeholderSafeValue)); dialog.flag_minus = dialog.isPlaceholderSigned(); } updateDisplay(); } }
                Button { text: "C"; Layout.fillWidth: true; enabled: dialog.isBtSymbolCorrect('C'); onClicked: { if (dialog.value.length > 0) dialog.clear(); else dialog.flag_minus = dialog.func_autoselect_flag_minus(); } }
                Button { text: "<"; Layout.fillWidth: true; enabled: dialog.isBtSymbolCorrect('<'); onClicked: dialog.backspSymbol(); }

                // Row 1: 7, 8, 9
                Button { text: "7"; Layout.fillWidth: true; enabled: dialog.isBtSymbolCorrect('7'); onClicked: dialog.putSymbol('7'); }
                Button { text: "8"; Layout.fillWidth: true; enabled: dialog.isBtSymbolCorrect('8'); onClicked: dialog.putSymbol('8'); }
                Button { text: "9"; Layout.fillWidth: true; enabled: dialog.isBtSymbolCorrect('9'); onClicked: dialog.putSymbol('9'); }

                // Row 2: 4, 5, 6
                Button { text: "4"; Layout.fillWidth: true; enabled: dialog.isBtSymbolCorrect('4'); onClicked: dialog.putSymbol('4'); }
                Button { text: "5"; Layout.fillWidth: true; enabled: dialog.isBtSymbolCorrect('5'); onClicked: dialog.putSymbol('5'); }
                Button { text: "6"; Layout.fillWidth: true; enabled: dialog.isBtSymbolCorrect('6'); onClicked: dialog.putSymbol('6'); }

                // Row 3: 1, 2, 3
                Button { text: "1"; Layout.fillWidth: true; enabled: dialog.isBtSymbolCorrect('1'); onClicked: dialog.putSymbol('1'); }
                Button { text: "2"; Layout.fillWidth: true; enabled: dialog.isBtSymbolCorrect('2'); onClicked: dialog.putSymbol('2'); }
                Button { text: "3"; Layout.fillWidth: true; enabled: dialog.isBtSymbolCorrect('3'); onClicked: dialog.putSymbol('3'); }

                // Row 4: 0, ., +/-
                Button { text: "0"; Layout.fillWidth: true; enabled: dialog.isBtSymbolCorrect('0'); onClicked: dialog.putSymbol('0'); }
                Button { text: dialog.getSystemLocaleDecimalChar(); Layout.fillWidth: true; enabled: dialog.isBtSymbolCorrect('.'); onClicked: dialog.putSymbol('.'); }
                Button { text: "+/-"; Layout.fillWidth: true; onClicked: { dialog.flag_minus = !dialog.flag_minus; updateDisplay(); } }

                // Row 5: OK (span 2), Cancel
                Button { text: dialog.textBtOK; Layout.columnSpan: 2; Layout.fillWidth: true; enabled: (dialog.value.length > 0) && dialog.isNumberInLimits(); onClicked: { dialog.executeOk(dialog.getValueStr(dialog.value), dialog.isValueEqualToPlaceholder()); dialog.hide(); } }
                Button { text: dialog.textBtCancel; Layout.fillWidth: true; enabled: true; onClicked: { dialog.executeCancel(); dialog.hide(); } }
            }
        }
    }

    // --- Keyboard Handling ---
    Keys.onReturnPressed: (event) => { if (btOK.enabled) { dialog.executeOk(dialog.getValueStr(dialog.value), dialog.isValueEqualToPlaceholder()); dialog.hide(); } }
    Keys.onEscapePressed: (event) => { dialog.executeCancel(); dialog.hide(); }
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_0) { dialog.putSymbol('0'); }
        else if (event.key === Qt.Key_1) { dialog.putSymbol('1'); }
        else if (event.key === Qt.Key_2) { dialog.putSymbol('2'); }
        else if (event.key === Qt.Key_3) { dialog.putSymbol('3'); }
        else if (event.key === Qt.Key_4) { dialog.putSymbol('4'); }
        else if (event.key === Qt.Key_5) { dialog.putSymbol('5'); }
        else if (event.key === Qt.Key_6) { dialog.putSymbol('6'); }
        else if (event.key === Qt.Key_7) { dialog.putSymbol('7'); }
        else if (event.key === Qt.Key_8) { dialog.putSymbol('8'); }
        else if (event.key === Qt.Key_9) { dialog.putSymbol('9'); }
        else if (event.key === 46 || event.key === 44) { dialog.putSymbol('.'); } // '.' or ','
        else if (event.key === 45) { if (dialog.isBtSymbolCorrect('-')) { dialog.flag_minus = !dialog.flag_minus; updateDisplay(); } }
        else if (event.key === Qt.Key_Backspace) { dialog.backspSymbol(); }
        else if (event.key === Qt.Key_Delete) { if (dialog.isBtSymbolCorrect('#')) { if (dialog.value.length > 0) { dialog.clear(); dialog.flag_minus = dialog.func_autoselect_flag_minus(); } else { dialog.value = dialog.getAbsValueStr(dialog.toPosixTextValue(dialog.placeholderSafeValue)); dialog.flag_minus = dialog.isPlaceholderSigned(); } updateDisplay(); } }
        else if (event.key === Qt.Key_Space) { if (dialog.isBtSymbolCorrect('#')) { if (dialog.value.length > 0) { dialog.clear(); dialog.flag_minus = dialog.func_autoselect_flag_minus(); } else { dialog.value = dialog.getAbsValueStr(dialog.toPosixTextValue(dialog.placeholderSafeValue)); dialog.flag_minus = dialog.isPlaceholderSigned(); } updateDisplay(); } }
        else if (event.key === Qt.Key_C && event.modifiers === Qt.ControlModifier) { dialog.copyValue(); }
        else if (event.key === Qt.Key_V && event.modifiers === Qt.ControlModifier) { dialog.pastValue(); }
    }

    // --- Helper Functions ---
    function copyValue() {
        clipboardHelper.copy(dialog.getValueStr(dialog.value));
    }

    function pastValue() {
        if (clipboardHelper.canPast()) {
            const buffer = clipboardHelper.past();
            const conv_text = dialog.toPosixTextValue(buffer);
            let real_value = parseFloat(conv_text);
            if (!isNaN(real_value)) {
                real_value = dialog.roundPlus(real_value, dialog.precision);
                if (real_value >= dialog.minimumValue && real_value <= dialog.maximumValue) {
                    dialog.flag_minus = (real_value < 0);
                    dialog.value = Math.abs(real_value).toString();
                    updateDisplay();
                }
            }
        }
    }

    function fixScale() {
        if (dialog.height < dialog.minimumDialogHeight || dialog.width < dialog.minimumDialogWidth) {
            return Math.min(dialog.height / dialog.minimumDialogHeight, dialog.width / dialog.minimumDialogWidth);
        }
        return 1.0;
    }
}
