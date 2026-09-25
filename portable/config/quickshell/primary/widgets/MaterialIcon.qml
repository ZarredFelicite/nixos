import QtQuick

Text {
    property real fill: 0
    property int grade: -25

    font.family: "Material Symbols Outlined"
    font.pixelSize: 16
    color: "#cdd6f4"
    
    // Material Design variable font axes
    font.variableAxes: ({
        FILL: fill.toFixed(1),
        GRAD: grade,
        opsz: font.pixelSize,
        wght: 400
    })
}