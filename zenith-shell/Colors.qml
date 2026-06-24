pragma Singleton
import QtQuick

QtObject {
    // Core Colors
    readonly property color primary: "#e9c16c"
    readonly property color on_primary: "#402e00"
    readonly property color primary_container: "#5b4300"
    readonly property color on_primary_container: "#ffdf9e"
    
    readonly property color secondary: "#d8c4a0"
    readonly property color on_secondary: "#3b2f15"
    readonly property color secondary_container: "#52452a"
    readonly property color on_secondary_container: "#f5e0bb"
    
    readonly property color tertiary: "#b0cfa9"
    readonly property color on_tertiary: "#1d361c"
    readonly property color tertiary_container: "#334d30"
    readonly property color on_tertiary_container: "#ccebc4"
    
    readonly property color error: "#ffb4ab"
    readonly property color on_error: "#690005"
    readonly property color error_container: "#93000a"
    readonly property color on_error_container: "#ffdad6"
    
    readonly property color background: "#17130b"
    readonly property color on_background: "#ebe1d4"
    
    readonly property color surface: "#17130b"
    readonly property color on_surface: "#ebe1d4"
    readonly property color surface_variant: "#4d4639"
    readonly property color on_surface_variant: "#d0c5b4"
    
    readonly property color outline: "#998f80"
    readonly property color outline_variant: "#4d4639"
    
    // Surface Containers (Matugen 2.x)
    readonly property color surface_container_lowest: "#110e07"
    readonly property color surface_container_low: "#1f1b13"
    readonly property color surface_container: "#231f17"
    readonly property color surface_container_high: "#2e2921"
    readonly property color surface_container_highest: "#39342b"
    
    readonly property color accent: "#e9c16c"

    Component.onCompleted: console.log("[Colors]: Singleton Loaded/Reloaded")
}
