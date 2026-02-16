import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: dialog

    // The minimum dimensions after which the input panel will be scaled down
    property int minimumDialogHeight: getGoldenMin(600) /* Default: golden ratio:) */
    property int minimumDialogWidth: 600
    // ------------------------------------------------------------------------

    // Dimensions of the 'dialog window' (for reading)
    property alias dialogHeight: dialogPanel.height
    property alias dialogWidth: dialogPanel.width
    // ------------------------------------------------------------------------

    // Title and measurement
    property string label: "test" /* Some text */
    property alias labelFont: labelDialog.font
    property string measurement: " Kg" /* "Hz" or "Kg" or "Mbyte" or ... */
    // ------------------------------------------------------------------------

    // Old value (slightly visible before entering the first character)
    property string placeholderValue: ""
    property bool flagCurrentValueSetted: false /* control used, not editable! */
    // ------------------------------------------------------------------------

    /* View settings */
    property alias radius: dialogPanel.radius
    property alias colorBackground: dialogPanel.color
    property alias border: dialogPanel.border
    property alias dialogOpacity: dialogPanel.opacity
    property color displayBackground: "#f1f3f1"
    property color displayTextColor: "black"
    property color displayPlaceholderTextColor: "gray"
    property color buttonsColors: "#f7a363"
    property color buttonsColorsOff: buttonsColors
    property color buttonsColorsOn: Qt.lighter(buttonsColorsOff, 1.2)
    property color buttonsColorsDimmed: Qt.darker(buttonsColorsOff, 1.5)
    property color buttonsColorDlgOn: "white"
    property color buttonsColorDlgOff: Qt.darker(buttonsColorDlgOn, 1.2)
    property color buttonsTextColors: "black"
    property color buttonsTextColorsOff: buttonsTextColors
    property color buttonsTextColorsOn: Qt.lighter(buttonsColorsOff, 1.5)
    property color buttonsTextColorDlg: "black"
    property color buttonsTextColorDlgOn: Qt.lighter(buttonsTextColorDlg, 1.5)
    property color buttonsTextColorDlgOff: buttonsTextColorDlg
    // ------------------------------------------------------------------------

    // Precision settings
    property int precision: 0
    property int decimals: 0
    // ------------------------------------------------------------------------

    // Input limits
    property double minimumValue: -Number.MAX_VALUE/2
    property double maximumValue: Number.MAX_VALUE/2
    // ------------------------------------------------------------------------

    // Layer close (hide) button names
    property string textBtOK: "ВВОД"
    property string textBtCancel: "ОТМЕНА"
    // ------------------------------------------------------------------------

    // Feature enable: sequence grid
    // (if the value is not a multiple of sequenceStep then it will be blocked
    // for input by buttons)
    property bool enableSequenceGrid: false
    property double sequenceStep: 0.5
    // ------------------------------------------------------------------------
    // Signals
    signal ok(var number, var equal); /* The signal is sent when
        we press the 'ENTER' button and close the layer
        (if the button is unlocked by the condition of non-empty input) */

    signal cancel(); /* the signal is sent when we press
        the 'CANCEL' button and close the layer */
    // ------------------------------------------------------------------------

    // Main methods
    /* show input box */
    function show(numberStr, is_placeholder) {
        if (typeof(is_placeholder) === 'undefined')
            is_placeholder = true;
        if (typeof(numberStr) === 'undefined')
            numberStr = "";
        let tmpValue = numberStr ? dialog.getAbsValueStr(numberStr) : ""
        let countD = 0;
        dialogPanel.visible = true;
        print("is_placeholder: ", is_placeholder)
        if (tmpValue) {
            if (dialog.decimals > 0 && dialog.minimumValue >= 0) {
                let i;
                for (i = 0; i < tmpValue.length; i++) {
                    if (tmpValue[i] === '0') {
                        countD += 1;
                    } else break;
                }
                if (countD === tmpValue.length)
                    countD -= 1;
                for (i = 0; i < countD; i++) {
                    tmpValue = tmpValue.substring(1);
                }
            }
            dialog.value = ""
            dialog.placeholderValue = dialog.toPosixTextValue(tmpValue);
            dialog.flag_minus = (parseFloat(numberStr) < 0);
        }
    }
    /* hide input box */
    function hide() {
        dialogPanel.visible = false;
        dialog.flagCurrentValueSetted = false;
        dialog.value = "";
    }
    /* clear input */
    function clear() {
        dialog.value = "";
    }
    /* input window open state */
    function isVisible() {
        return dialogPanel.visible;
    }
    // ------------------------------------------------------------------------

    // System settings
    property string placeholderSafeValue: dialog.getPlaceholderValueSafe()
    property bool flag_minus: false /* used to memorize the sign */
    property string value: "" /* absolute entered value (unsigned) */
    property string displayValue: dialog.flag_minus ?
                                      dialog.getValueStr(dialog.toLocaleTextValue(dialog.value))
                                    : dialog.getValueStr(dialog.toLocaleTextValue(dialog.value)); /*
        Displayed input value on display */
    // ------------------------------------------------------------------------

    // System Scaling Methods
    function fixScale() {
        if (dialog.height < dialog.minimumDialogHeight
                || dialog.width < dialog.minimumDialogWidth)
        {
            return Math.min(dialog.height/dialog.minimumDialogHeight,
                            dialog.width/dialog.minimumDialogWidth);
        }
        return 1.0;
    }
    function getGoldenMin(size) {
        return size * 514229.0 / 832040.0;
    }
    function getGoldenMax(size) {
        return size * 1.618033988749;
    }
    // ------------------------------------------------------------------------

    // Системные методы ввода
    /* to enter character */
    function putSymbol(sym) {
        if (isBtSymbolCorrect(sym)) {
            if (dialog.value.length === 0 && sym === '.') {
                dialog.value = "0";
            }
            if (dialog.value.length === 1
                    && dialog.value.charAt(0) === '0'
                    && dialog.isNumericChar(sym))
            {
                dialog.value = dialog.value.substring(1);
            }
            dialog.value = dialog.value + sym;
        }
    }
    /* to erase the entered character */
    function backspSymbol() {
        if (dialog.value.length === 0)
            return false;
        const lastIndex = dialog.value.length - 1;
        dialog.value = dialog.value.substring(0, lastIndex);
        return true;
    }
    /* to paste a number to input from the clipboard */
    function pastValue() {
        if (clipboardHelper.canPast()) {
            const buffer = clipboardHelper.past();
            const conv_text = dialog.toPosixTextValue(buffer);
            let real_value = parseFloat(conv_text);
            real_value = dialog.roundPlus(real_value, dialog.precision);
            if (real_value >= dialog.minimumValue
                    && real_value <= dialog.maximumValue)
            {
                dialog.value = dialog.getAbsValueStr(real_value.toString());
                dialog.flag_minus = (real_value < 0);
            }
        }
    }
    /* to copy the entered number to the clipboard
        (or the old number if nothing is entered) */
    function copyValue() {
        if (dialog.value.length > 0) {
            clipboardHelper.copy(displayText.text);
        } else if (placeholderSafeValue.length > 0) {
            clipboardHelper.copy(placeholderSafeValue);
        }
    }
    /* to auto-selection of the input character by default
        (when showing the panel) */
    function func_autoselect_flag_minus() {
        if (dialog.minimumValue < 0 && dialog.maximumValue < 0)
            return true;
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
    /* to get the protected version of the old value
        (excludes incorrect input when pressing the '#' button) */
    function getPlaceholderValueSafe() {
        if (dialog.placeholderValue.length > 0) {
            const checkValue = roundPlus(
                                 parseFloat(toPosixTextValue(dialog.placeholderValue)),
                                 dialog.precision);
            // Range check:
            if (isNaN(checkValue)) {
                return "";
            }
            if (!(checkValue >= dialog.minimumValue
                  && checkValue <= dialog.maximumValue))
            {
                return "";
            }
            // If the range check was successful, then the multiplicity check of the sequence step (if enabled)
            if (dialog.enableSequenceGrid) {
                const tmp_value = parseFloat(Number(checkValue).toFixed(dialog.precision));
                const valPr = parseInt((tmp_value * Math.pow(10, dialog.precision)).toFixed(0));
                const valArgPr = parseInt((dialog.sequenceStep * Math.pow(10, dialog.precision)).toFixed(0));
                if ((valPr % valArgPr) !== 0) {
                    // Resulting value is not a multiple of the sequence step!
                    return "";
                }
            }
            return dialog.toLocaleTextValue(checkValue.toString());
        }
        return "";
    }
    /* the old value is negative */
    function isPlaceholderSigned() {
        if (dialog.placeholderSafeValue.length > 1) {
            if (dialog.placeholderSafeValue.charAt(0) === '-') {
                return true;
            }
        }
        return false;
    }
    /* range check */
    function isNumberInLimits() {
        const new_value_str = dialog.value;
        const real_value = ((dialog.flag_minus) ?
                              (-1) * parseFloat(new_value_str)
                            : parseFloat(new_value_str)); // checked number
        if (isNaN(real_value)) {
            return false;
        }
        if (real_value > dialog.maximumValue
                || real_value < dialog.minimumValue)
        {
            return false;
        }
        return true;
    }
    /* method of blocking control input buttons (predictive) */
    function isBtSymbolCorrect(symbols) {
        let result = false;
        switch (symbols) {
        // Alg 1. - check for range, precision and multiplicity
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
            if (dialog.value.length > 0) {
                if (dialog.value.length > 2) {
                    // verification of the fact that we introduce the integer part
                    const indexDecSeparator2 = dialog.value.indexOf('.');
                    if (~indexDecSeparator2) {
                        // the symbol is found, so we enter the fractional part
                        const fractionPrecisionFact = (dialog.value.substring(indexDecSeparator2)).length - 1;
                        // precision check
                        if ((fractionPrecisionFact + 1) > dialog.precision) {
                            // precision is not observed!
                            break;
                        }
                    }
                }
                const new_value_str = dialog.value + symbols;
                const real_value = ((dialog.flag_minus) ?
                                        (-1) * parseFloat(new_value_str)
                                      : parseFloat(new_value_str)); // checked number
                if (isNaN(real_value)) {
                    break;
                }
                if (real_value <= dialog.maximumValue) {
                    result = true;
                } else {
                    break;
                }
                // Range check
                // If the range check was successful, then the multiplicity check (if enabled)
                if (dialog.enableSequenceGrid) {
                    if (!dialog.isNumberInSequenceGrid(real_value, dialog.precision)) {
                        // the resulting value is not a multiple of the sequence step!
                        result = false;
                    }
                }
            } else {
                // Single character check
                const real_value_1s = ((dialog.flag_minus) ?
                                         (-1) * parseFloat(symbols + ".0")
                                       : parseFloat(symbols + ".0")); // checked number
                if (isNaN(real_value_1s)) {
                    break;
                }
                if (real_value_1s <= dialog.maximumValue) {
                    result = true;
                } else {
                    break;
                }
                // Range check
                // If the range check was successful, then the multiplicity check (if enabled)
                if (dialog.enableSequenceGrid) {
                    if (!dialog.isNumberInSequenceGrid(real_value_1s, dialog.precision)) {
                        // the resulting value is not a multiple of the sequence step!
                        result = false;
                    }
                }
            }
            break;
        // Alg 2.
        case '.':
            if (dialog.precision <= 0) {
                break;
            }
            if (dialog.value.length > 0) {
                const indexDecSeparator = value.indexOf('.');
                if (~indexDecSeparator) {
                    // the symbol is found, the second is not needed!
                    break;
                } else {
                    // exclude a point in the boundary values!
                    if (!dialog.isAddsPutDoteInLimitAtRange()) {
                        // enters the range and is not boundary -> point input
                        result = true;
                    }
                }
            } else {
                // checking zero is in range
                if (0.0 >= dialog.minimumValue && 0.0 <= dialog.maximumValue) {
                    // exclude a point in the boundary values!
                    if (!dialog.isAddsPutDoteInLimitAtRange()) {
                        // 0.0 is in the range and is not a boundary
                        // -> enter point with a wildcard '0' in front of point
                        result = true;
                    }
                }
            }
            break;
        // Alg 3.
        case '-':
            if (dialog.minimumValue >= 0) {
                result = false;
            } else if (dialog.value.length > 0) {
                const realValue3 = (-1) * parseFloat(dialog.value); // checked number
                if (realValue3 === 0) {
                    if (0 === dialog.minimumValue
                            || 0 === dialog.maximumValue)
                    {
                        break;
                    }
                }
                // range check
                if (realValue3 <= dialog.maximumValue) {
                    result = true;
                } else {
                    break;
                }
            }
            break;
        // Alg 4.
        case '#':
            if (dialog.placeholderValue.length > 0)
                result = true;
            break;
        // Alg 5.
        case 'C':
            if (dialog.value.length > 0)
                result = true;
            break;
        // Alg 6.
        case '<':
            if (dialog.value.length > 0)
                result = true;
            break;
        }
        return result;
    }
    // ------------------------------------------------------------------------

    // System Helper Methods
    /* checking that the entered value is different from the old one */
    function isPlaceholderEqual() {
        return (dialog.displayValue === dialog.placeholderValue);
    }
    /* get signed number string */
    function getValueStr(arg) {
        let valueStr = ((!dialog.flag_minus) ? arg : ("-" + arg));
        let countD = 0;
        if (dialog.decimals > 0 && dialog.minimumValue >= 0) {
            let i;
            for (i = 0; i < valueStr.length; i++) {
                if (dialog.isNumericChar(valueStr[i])) {
                    countD += 1;
                } else {
                    break;
                }
            }
            for (i = 0; i < (dialog.decimals - countD); i++) {
                valueStr = "0" + valueStr;
            }
        }
        return valueStr;
    }
    /* get an unsigned number string */
    function getAbsValueStr(arg) {
        if (arg.length > 1) {
            if (arg.charAt(0) === '-') {
                return arg.substr(1);
            }
        }
        return arg;
    }
    /* Get integer separator character from fractional in environment localization */
    function getSystemLocaleDecimalChar() {
        return Qt.locale("").decimalPoint;
    }
    /* Convert numeric string to posix format (for javascript conversions) */
    function toPosixTextValue(arg) {
        const doteSymbol = dialog.getSystemLocaleDecimalChar();
        let strValue = arg;
        if (doteSymbol !== '.') {
            if (strValue.length > 0) {
                strValue = strValue.replace(doteSymbol, '.');
            }
        }
        return strValue;
    }
    /* Convert numeric string to environment localization format (for display) */
    function toLocaleTextValue(arg) {
        const doteSymbol = dialog.getSystemLocaleDecimalChar();
        let strValue = arg;
        if (doteSymbol !== '.') {
            strValue = strValue.replace('.', doteSymbol)
        } else {
            strValue = strValue.replace(',', doteSymbol)
        }
        return strValue;
    }
    /* symbol is a number */
    function isNumericChar(sym) {
        if (sym >= '0' && sym <= '9') {
            return true;
        }
        return false;
    }
    /* rounding to precision
        x - number, n - number of characters */
    function roundPlus(x, n) {
      const m = Math.pow(10, n);
      return Math.round(x * m) / m;
    }
    /* checking a number for a multiple of the number of steps
        in a sequence with precision */
    function isNumberInSequenceGrid(real_value, precision_arg) {
        if (isNaN(real_value))
            return false;
        const tmp_value = roundPlus(real_value, precision_arg);
        const valPr = parseInt((tmp_value * Math.pow(10, precision_arg)).toFixed(0));
        const valArgPr = parseInt((dialog.sequenceStep * Math.pow(10, precision_arg)).toFixed(0));
        if((valPr % valArgPr) === 0) {
            return true; // the value is a multiple of the sequence step!
        }
        return false;
    }
    /* checking whether a point has been entered at the boundaries
        of an input range */
    function isAddsPutDoteInLimitAtRange() {
        let tmp_value;
        if (dialog.value.length > 0) {
            tmp_value = ((dialog.flag_minus) ?
                             (-1) * parseInt(dialog.value)
                           : parseInt(dialog.value));
        } else {
            if (0 >= dialog.maximumValue) {
                // to exclude period from being entered if nothing is entered
                // and the default zero for substitution is not in the range
                return true;
            }
            tmp_value = 0;
        }
        const check_value_str = tmp_value + ".0";
        var check_value = dialog.roundPlus(parseFloat(check_value_str), dialog.precision);
        if (!dialog.flag_minus) {
            if (check_value >= dialog.maximumValue) {
                return true
            }
        } else {
            if (check_value <= dialog.minimumValue) {
                return true
            }
        }
        return false
    }
    // ------------------------------------------------------------------------

    // Clipboard buffer
    Item {
        id: clipboardHelper
        opacity: 0
        property alias buffer: helper.text
        function copy(text) {
            buffer = text;
            helper.selectAll();
            helper.copy();
        }
        function cut(text) {
            buffer = text;
            helper.selectAll();
            helper.cut()
        }
        function canPast() {
            return helper.canPaste
        }
        function past() {
            if(helper.canPaste) {
                buffer = " "
                helper.selectAll()
                helper.paste();
                return buffer;
            }
            return ""
        }
        TextEdit {
            id: helper
            text: ""
        }
    }

    // Shadow
    Rectangle {
        id: dialogMsgShadow
        visible: dialogPanel.visible
        anchors.fill: parent
        color: Qt.darker("#c0ffffff", 1.5)
        antialiasing: true
        MouseArea {
            anchors.fill: parent
        }
    }

    // Input Dialog Box
    Rectangle {
        id: dialogPanel
        anchors.centerIn: parent
        scale: dialog.fixScale()
        height: 455
        width: 600
        visible: false
        antialiasing: true
        color: "#f1eee0"
        focus: true
        onVisibleChanged: {
            if (visible === true) {
                Keys.enabled = true
            }
            dialogPanel.forceActiveFocus()
        }
        Menu {
            id: serviceMenu
            MenuItem {
                text: qsTr("Copy")
                enabled: ((dialog.value.length > 0) || (dialog.placeholderSafeValue.length > 0))
                onTriggered: {
                    dialog.copyValue();
                    dialogPanel.forceActiveFocus()
                }
            }
            MenuItem {
                text: qsTr("Paste")
                enabled: clipboardHelper.canPast()
                onTriggered: {
                    dialog.pastValue();
                    dialogPanel.forceActiveFocus()
                }
            }
        }
        MouseArea {
            id: textArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
        ColumnLayout {
            id: contentDialogPanel
            height: parent.height
            width: parent.width
            spacing: 0
            anchors.horizontalCenter: parent.horizontalCenter
            Row {
                id: rowLabelPanel
                height: 0.1 * contentDialogPanel.height
                width: parent.width
                spacing: 0

                // Title area
                Label {
                    id: labelDialog
                    width: parent.width
                    height: 0.1 * contentDialogPanel.height
                    color: "black"
                    text: label
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 16
                    font.bold: true
                }
            }
            RowLayout {
                id: rowDisplayPanel
                width: contentDialogPanel.width
                height: contentDialogPanel.height*0.15
                Layout.alignment: Qt.AlignHCenter

                // Input indicator area
                Rectangle {
                    id: displayTextDisplay
                    color: trigger_copy ? Qt.darker(dialog.displayBackground, 1.5) : dialog.displayBackground
                    border.color: Qt.darker(color, 2)
                    implicitHeight: contentDialogPanel.height * 0.15
                    implicitWidth: contentDialogPanel.width - 2
                    Text {
                        id: displayText
                        anchors.fill: parent
                        verticalAlignment: "AlignVCenter"
                        horizontalAlignment: "AlignHCenter"
                        text: dialog.value.length > 0 ? dialog.displayValue + dialog.measurement : dialog.placeholderValue + dialog.measurement
                        color: dialog.value.length > 0 ? dialog.displayTextColor : dialog.displayPlaceholderTextColor
                        font.pixelSize: displayTextDisplay.height * 0.65
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton | Qt.LeftButton
                        onPressAndHold: {
                            serviceMenu.x = textArea.mouseX;
                            serviceMenu.y = textArea.mouseY;
                            serviceMenu.open();
                        }
                        onClicked: {
                            if(mouse.button === Qt.RightButton) {
                                serviceMenu.x = textArea.mouseX;
                                serviceMenu.y = textArea.mouseY;
                                serviceMenu.open();
                            }
                        }

                    }
                }
            }
            Grid {
                id: gridDigits
                columns: 3
                padding: 0
                rows: 5
                antialiasing: true
                Layout.alignment: Qt.AlignHCenter
                width: contentDialogPanel.width + 2
                height: contentDialogPanel.height * 0.625
                spacing: -1
                ButtonKey {
                    id: areaCClearFront
                    height: 0.125 * contentDialogPanel.height
                    width: 0.3333333 * contentDialogPanel.width
                    colorOn: dialog.buttonsColorsOn
                    colorOff: dialog.buttonsColorsOff
                    colorDimmed: dialog.buttonsColorsDimmed
                    textColorOff: dialog.buttonsTextColorsOff
                    textColorOn: dialog.buttonsTextColorsOn
                    text: "#"
                    state: trigger_ftsp ? "on" : "off"
                    enableOnPressIndicate: false
                    onPressed: {
                        trigger_ftsp = true;
                    }
                    onReleased: {
                        if (dialog.value.length > 0) {
                            dialog.clear();
                            dialog.flag_minus = dialog.func_autoselect_flag_minus();
                        } else {
                            dialog.value = dialog.getAbsValueStr(toPosixTextValue(placeholderSafeValue));
                            dialog.flag_minus = dialog.isPlaceholderSigned();
                        }
                        trigger_ftsp = false;
                        trigger_clear = false;
                    }
                }
                ButtonKey {
                    id: areaCClear
                    height: 0.125 * contentDialogPanel.height
                    width: 0.3333333 * contentDialogPanel.width
                    colorOn: dialog.buttonsColorsOn
                    colorOff: dialog.buttonsColorsOff
                    colorDimmed: dialog.buttonsColorsDimmed
                    textColorOff: dialog.buttonsTextColorsOff
                    textColorOn: dialog.buttonsTextColorsOn
                    text: "C"
                    state: dialog.isBtSymbolCorrect('C') ?
                               (trigger_clear ? "on" : "off")
                             : "dimmed"
                    enableOnPressIndicate: false
                    onPressed: {
                        trigger_clear = true;
                    }
                    onReleased: {
                        trigger_clear = false;
                        dialog.clear();
                        dialog.flag_minus = dialog.func_autoselect_flag_minus();
                    }
                }
                ButtonKey {
                    id: areaCClearBack
                    height: 0.125 * contentDialogPanel.height
                    width: 0.3333333 * contentDialogPanel.width
                    colorOn: dialog.buttonsColorsOn
                    colorOff: dialog.buttonsColorsOff
                    colorDimmed: dialog.buttonsColorsDimmed
                    textColorOff: dialog.buttonsTextColorsOff
                    textColorOn: dialog.buttonsTextColorsOn
                    text: "<-"
                    state: dialog.isBtSymbolCorrect('<') ?
                               (trigger_bksp ? "on" : "off")
                             : "dimmed"
                    enableOnPressIndicate: false
                    onPressed: {
                        trigger_bksp = true
                    }
                    onReleased: {
                        trigger_bksp = false;
                        dialog.backspSymbol();
                        if (dialog.value.length === 0) {
                            flag_minus = dialog.func_autoselect_flag_minus();
                        }
                    }
                }
                ButtonKey {
                    id: areaC7
                    text: "7"
                    height: 0.125 * contentDialogPanel.height
                    width: 0.333333 * contentDialogPanel.width
                    colorOn: dialog.buttonsColorsOn
                    colorOff: dialog.buttonsColorsOff
                    colorDimmed: dialog.buttonsColorsDimmed
                    textColorOff: dialog.buttonsTextColorsOff
                    textColorOn: dialog.buttonsTextColorsOn
                    state: dialog.isBtSymbolCorrect('7') ?
                               (trigger_7 ? "on" : "off")
                             : "dimmed"
                    enableOnPressIndicate: false
                    onPressed: {
                        trigger_7 = true;
                    }
                    onReleased: {
                        trigger_7 = false;
                        dialog.putSymbol('7');
                    }
                }
                ButtonKey {
                    id: areaC8
                    text: "8"
                    height: 0.125 * contentDialogPanel.height
                    width: 0.333333 * contentDialogPanel.width
                    colorOn: dialog.buttonsColorsOn
                    colorOff: dialog.buttonsColorsOff
                    colorDimmed: dialog.buttonsColorsDimmed
                    textColorOff: dialog.buttonsTextColorsOff
                    textColorOn: dialog.buttonsTextColorsOn
                    state: dialog.isBtSymbolCorrect('8') ?
                               (trigger_8 ? "on" : "off")
                             : "dimmed"
                    enableOnPressIndicate: false
                    onPressed: {
                        trigger_8 = true;
                    }
                    onReleased: {
                        trigger_8 = false;
                        dialog.putSymbol('8');
                    }
                }
                ButtonKey {
                    id: areaC9
                    text: "9"
                    height: 0.125 * contentDialogPanel.height
                    width: 0.333333 * contentDialogPanel.width
                    colorOn: dialog.buttonsColorsOn
                    colorOff: dialog.buttonsColorsOff
                    colorDimmed: dialog.buttonsColorsDimmed
                    textColorOff: dialog.buttonsTextColorsOff
                    textColorOn: dialog.buttonsTextColorsOn
                    state: dialog.isBtSymbolCorrect('9') ?
                               (trigger_9 ? "on" : "off")
                             : "dimmed"
                    enableOnPressIndicate: false
                    onPressed: {
                        trigger_9 = true;
                    }
                    onReleased: {
                        trigger_9 = false;
                        dialog.putSymbol('9');
                    }
                }
                ButtonKey {
                    id: areaC4
                    text: "4"
                    height: 0.125 * contentDialogPanel.height
                    width: 0.333333 * contentDialogPanel.width
                    colorOn: dialog.buttonsColorsOn
                    colorOff: dialog.buttonsColorsOff
                    colorDimmed: dialog.buttonsColorsDimmed
                    textColorOff: dialog.buttonsTextColorsOff
                    textColorOn: dialog.buttonsTextColorsOn
                    state: dialog.isBtSymbolCorrect('4') ?
                               (trigger_4 ? "on" : "off")
                             : "dimmed"
                    enableOnPressIndicate: false
                    onPressed: {
                        trigger_4 = true;
                    }
                    onReleased: {
                        trigger_4 = false;
                        dialog.putSymbol('4');
                    }
                }
                ButtonKey {
                    id: areaC5
                    text: "5"
                    height: 0.125 * contentDialogPanel.height
                    width: 0.333333 * contentDialogPanel.width
                    colorOn: dialog.buttonsColorsOn
                    colorOff: dialog.buttonsColorsOff
                    colorDimmed: dialog.buttonsColorsDimmed
                    textColorOff: dialog.buttonsTextColorsOff
                    textColorOn: dialog.buttonsTextColorsOn
                    state: dialog.isBtSymbolCorrect('5') ?
                               (trigger_5 ? "on" : "off")
                             : "dimmed"
                    enableOnPressIndicate: false
                    onPressed: {
                        trigger_5 = true;
                    }
                    onReleased: {
                        trigger_5 = false;
                        dialog.putSymbol('5');
                    }
                }
                ButtonKey {
                    id: areaC6
                    text: "6"
                    height: 0.125 * contentDialogPanel.height
                    width: 0.333333 * contentDialogPanel.width
                    colorOn: dialog.buttonsColorsOn
                    colorOff: dialog.buttonsColorsOff
                    colorDimmed: dialog.buttonsColorsDimmed
                    textColorOff: dialog.buttonsTextColorsOff
                    textColorOn: dialog.buttonsTextColorsOn
                    state: dialog.isBtSymbolCorrect('6') ?
                               (trigger_6 ? "on" : "off")
                             : "dimmed"
                    enableOnPressIndicate: false
                    onPressed: {
                        trigger_6 = true;
                    }
                    onReleased: {
                        trigger_6 = false;
                        dialog.putSymbol('6');
                    }
                }
                ButtonKey {
                    id: areaC1
                    text: "1"
                    height: 0.125 * contentDialogPanel.height
                    width: 0.333333 * contentDialogPanel.width
                    colorOn: dialog.buttonsColorsOn
                    colorOff: dialog.buttonsColorsOff
                    colorDimmed: dialog.buttonsColorsDimmed
                    textColorOff: dialog.buttonsTextColorsOff
                    textColorOn: dialog.buttonsTextColorsOn
                    state: dialog.isBtSymbolCorrect('1') ?
                               (trigger_1 ? "on" : "off")
                             : "dimmed"
                    enableOnPressIndicate: false
                    onPressed: {
                        trigger_1 = true;
                    }
                    onReleased: {
                        trigger_1 = false;
                        dialog.putSymbol('1');
                    }
                }
                ButtonKey {
                    id: areaC2
                    text: "2"
                    height: 0.125 * contentDialogPanel.height
                    width: 0.333333 * contentDialogPanel.width
                    colorOn: dialog.buttonsColorsOn
                    colorOff: dialog.buttonsColorsOff
                    colorDimmed: dialog.buttonsColorsDimmed
                    textColorOff: dialog.buttonsTextColorsOff
                    textColorOn: dialog.buttonsTextColorsOn
                    state: dialog.isBtSymbolCorrect('2') ?
                               (trigger_2 ? "on" : "off")
                             : "dimmed"
                    enableOnPressIndicate: false
                    onPressed: {
                        trigger_2 = true;
                    }
                    onReleased: {
                        trigger_2 = false;
                        dialog.putSymbol('2');
                    }
                }
                ButtonKey {
                    id: areaC3
                    text: "3"
                    height: 0.125 * contentDialogPanel.height
                    width: 0.333333 * contentDialogPanel.width
                    colorOn: dialog.buttonsColorsOn
                    colorOff: dialog.buttonsColorsOff
                    colorDimmed: dialog.buttonsColorsDimmed
                    textColorOff: dialog.buttonsTextColorsOff
                    textColorOn: dialog.buttonsTextColorsOn
                    state: dialog.isBtSymbolCorrect('3') ?
                               (trigger_3 ? "on" : "off")
                             : "dimmed"
                    enableOnPressIndicate: false
                    onPressed: {
                        trigger_3 = true;
                    }
                    onReleased: {
                        trigger_3 = false;
                        dialog.putSymbol('3');
                    }
                }
                ButtonKey {
                    id: areaC0
                    text: "0"
                    height: 0.125 * contentDialogPanel.height
                    width: 0.333333 * contentDialogPanel.width
                    colorOn: dialog.buttonsColorsOn
                    colorOff: dialog.buttonsColorsOff
                    colorDimmed: dialog.buttonsColorsDimmed
                    textColorOff: dialog.buttonsTextColorsOff
                    textColorOn: dialog.buttonsTextColorsOn
                    state: dialog.isBtSymbolCorrect('0') ?
                               (trigger_0 ? "on" : "off")
                             : "dimmed"
                    enableOnPressIndicate: false
                    onPressed: {
                        trigger_0 = true;
                    }
                    onReleased: {
                        trigger_0 = false;
                        dialog.putSymbol('0');
                    }
                }
                ButtonKey {
                    id: areaCDote
                    text: dialog.getSystemLocaleDecimalChar() // "." or ","
                    height: 0.125 * contentDialogPanel.height
                    width: 0.333333 * contentDialogPanel.width
                    colorOn: dialog.buttonsColorsOn
                    colorOff: dialog.buttonsColorsOff
                    colorDimmed: dialog.buttonsColorsDimmed
                    textColorOff: dialog.buttonsTextColorsOff
                    textColorOn: dialog.buttonsTextColorsOn
                    state: dialog.isBtSymbolCorrect('.') ?
                               (trigger_dote ? "on" : "off")
                             : "dimmed"
                    enableOnPressIndicate: false
                    onPressed: {
                        trigger_dote = true;
                    }
                    onReleased: {
                        trigger_dote = false;
                        dialog.putSymbol('.');
                    }
                }
                ButtonKey {
                    id: areaCMinus
                    text: "+/-"
                    height: 0.125 * contentDialogPanel.height
                    width: 0.333333 * contentDialogPanel.width
                    colorOn: dialog.buttonsColorsOn
                    colorOff: dialog.buttonsColorsOff
                    colorDimmed: dialog.buttonsColorsDimmed
                    textColorOff: dialog.buttonsTextColorsOff
                    textColorOn: dialog.buttonsTextColorsOn
                    state: dialog.isBtSymbolCorrect('-') ?
                               (trigger_minus ? "on" : "off")
                             : "dimmed"
                    enableOnPressIndicate: false
                    onPressed: {
                        trigger_minus = true;
                    }
                    onReleased: {
                        trigger_minus = false;
                        dialog.flag_minus = !dialog.flag_minus;
                    }
                }
            }
            RowLayout {
                id: rowFinishEditButtons
                height: 0.125 * contentDialogPanel.height
                width: contentDialogPanel.width + 1
                spacing: -1
                Layout.alignment: Qt.AlignHCenter
                ButtonDlg {
                    id: btOK
                    property bool allow: dialog.isNumberInLimits()
                    color: dialog.buttonsColorDlgOn
                    backgroundColorOn: dialog.buttonsColorDlgOn
                    backgroundColorOff: dialog.buttonsColorDlgOff
                    textColor: dialog.buttonsTextColorDlg
                    textColorOff: dialog.buttonsTextColorDlgOff
                    textColorOn: dialog.buttonsColorDlgOn
                    text: dialog.textBtOK
                    height: parent.height
                    width: parent.width / 2
                    enabled: (dialog.value.length > 0) && allow
                    onClicked: {
                        dialog.ok(dialog.getValueStr(value),
                                  dialog.isPlaceholderEqual());
                        dialog.hide();
                    }
                }
                ButtonDlg {
                    id: btCancel
                    color: dialog.buttonsColorDlgOn
                    backgroundColorOn: dialog.buttonsColorDlgOn
                    backgroundColorOff: dialog.buttonsColorDlgOff
                    textColor: dialog.buttonsTextColorDlg
                    textColorOff: dialog.buttonsTextColorDlgOff
                    textColorOn: dialog.buttonsColorDlgOn
                    text: dialog.textBtCancel
                    height: parent.height
                    width: parent.width / 2
                    onClicked: {
                        dialog.cancel()
                        dialog.hide();
                    }
                }
            }
        }
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_C && event.modifiers === Qt.ControlModifier) {
                // Copy by CTRL + C
                trigger_copy = true;
                dialog.copyValue();
            } else if(event.key === Qt.Key_V && event.modifiers === Qt.ControlModifier) {
                // Paste by CTRL + V
                dialog.pastValue();
            } else if (event.key === Qt.Key_0) {
                trigger_0 = true;
            } else if (event.key === Qt.Key_1) {
                trigger_1 = true;
            } else if (event.key === Qt.Key_2) {
                trigger_2 = true;
            } else if (event.key === Qt.Key_3) {
                trigger_3 = true;
            } else if (event.key === Qt.Key_4) {
                trigger_4 = true;
            } else if (event.key === Qt.Key_5) {
                trigger_5 = true;
            } else if (event.key === Qt.Key_6) {
                trigger_6 = true;
            } else if (event.key === Qt.Key_7) {
                trigger_7 = true;
            } else if (event.key === Qt.Key_8) {
                trigger_8 = true;
            } else if (event.key === Qt.Key_9) {
                trigger_9 = true;
            } else if (event.key === 46 || event.key === 44) {
                // '.' or ','
                trigger_dote = true;
            } else if (event.key === 45) {
                // '-'
                trigger_minus = true;
            } else if (event.key === Qt.Key_Backspace) {
                trigger_bksp = true;
            } else if (event.key === Qt.Key_Delete) {
                trigger_ftsp = true;
            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && btOK.enabled ) {
                dialog.ok(dialog.getValueStr(value), dialog.isPlaceholderEqual());
                dialog.hide();
            } else if (event.key === Qt.Key_Space) {
                if (dialog.value.length > 0) {
                    trigger_clear = true;
                } else {
                    trigger_ftsp = true;
                }
            }
        }
        Keys.onReleased: (event) => {
            if (event.key === Qt.Key_C && event.modifiers === Qt.ControlModifier) {
                trigger_copy = false;
                copyValue();
            } else if (event.key === Qt.Key_0) {
                trigger_0 = false;
                dialog.putSymbol('0');
            } else if (event.key === Qt.Key_1) {
                trigger_1 = false;
                dialog.putSymbol('1');
            } else if (event.key === Qt.Key_2) {
                trigger_2 = false;
                dialog.putSymbol('2');
            } else if (event.key === Qt.Key_3) {
                trigger_3 = false;
                dialog.putSymbol('3');
            } else if (event.key === Qt.Key_4) {
                trigger_4 = false;
                dialog.putSymbol('4');
            } else if (event.key === Qt.Key_5) {
                trigger_5 = false;
                dialog.putSymbol('5');
            } else if (event.key === Qt.Key_6) {
                trigger_6 = false;
                dialog.putSymbol('6');
            } else if (event.key === Qt.Key_7) {
                trigger_7 = false;
                dialog.putSymbol('7');
            } else if (event.key === Qt.Key_8) {
                trigger_8 = false;
                dialog.putSymbol('8');
            } else if (event.key === Qt.Key_9) {
                trigger_9 = false;
                dialog.putSymbol('9');
            } else if (event.key === 46 || event.key === 44) {
                trigger_dote = false;
                dialog.putSymbol('.');
            } else if (event.key === 45) {
                if (dialog.isBtSymbolCorrect('-')) {
                    trigger_minus = false;
                    dialog.flag_minus = !dialog.flag_minus;
                }
            } else if (event.key === Qt.Key_Backspace) {
                if (dialog.isBtSymbolCorrect('<')) {
                    trigger_bksp = false;
                    dialog.backspSymbol();
                    if (dialog.value.length === 0) {
                        dialog.flag_minus = func_autoselect_flag_minus();
                    }
                }
            } else if (event.key === Qt.Key_Delete) {
                if (dialog.isBtSymbolCorrect('C')) {
                    trigger_ftsp = false;
                    dialog.clear();
                    dialog.flag_minus = dialog.func_autoselect_flag_minus();
                }
            } else if (event.key === Qt.Key_Space) {
                if (dialog.isBtSymbolCorrect('#')) {
                    if (dialog.value.length > 0) {
                        dialog.clear();
                        dialog.flag_minus = dialog.func_autoselect_flag_minus();
                    } else {
                        dialog.value = dialog.getAbsValueStr(dialog.toPosixTextValue(dialog.placeholderSafeValue));
                        dialog.flag_minus = dialog.isPlaceholderSigned();
                    }
                }
                trigger_clear = false;
                trigger_ftsp = false;
            } else {
                trigger_1 = false;
                trigger_2 = false;
                trigger_3 = false;
                trigger_4 = false;
                trigger_5 = false;
                trigger_6 = false;
                trigger_7 = false;
                trigger_8 = false;
                trigger_9 = false;
                trigger_0 = false;
                trigger_bksp = false;
                trigger_ftsp = false;
                trigger_dote = false;
                trigger_minus = false;
                trigger_clear = false;
                trigger_copy = false;
            }
        }
    }

    property bool trigger_1: false
    property bool trigger_2: false
    property bool trigger_3: false
    property bool trigger_4: false
    property bool trigger_5: false
    property bool trigger_6: false
    property bool trigger_7: false
    property bool trigger_8: false
    property bool trigger_9: false
    property bool trigger_0: false
    property bool trigger_bksp: false
    property bool trigger_ftsp: false
    property bool trigger_dote: false
    property bool trigger_minus: false
    property bool trigger_clear: false
    property bool trigger_copy: false

    onFocusChanged: {
        if (!dialogPanel.focus)
            dialogPanel.forceActiveFocus();
    }
}
