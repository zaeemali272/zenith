pragma Singleton
import QtQuick

QtObject {
    // Core Colors
    readonly property color primary: "#ffb3b3"
    readonly property color on_primary: "#561d20"
    readonly property color primary_container: "#733335"
    readonly property color on_primary_container: "#ffdad9"
    
    readonly property color secondary: "#e6bdbc"
    readonly property color on_secondary: "#442929"
    readonly property color secondary_container: "#5d3f3f"
    readonly property color on_secondary_container: "#ffdad9"
    
    readonly property color tertiary: "#e5c18d"
    readonly property color on_tertiary: "#422c05"
    readonly property color tertiary_container: "#5b421a"
    readonly property color on_tertiary_container: "#ffdeae"
    
    readonly property color error: "#ffb4ab"
    readonly property color on_error: "#690005"
    readonly property color error_container: "#93000a"
    readonly property color on_error_container: "#ffdad6"
    
    readonly property color background: "#1a1111"
    readonly property color on_background: "#f0dede"
    
    readonly property color surface: "#1a1111"
    readonly property color on_surface: "#f0dede"
    readonly property color surface_variant: "#524343"
    readonly property color on_surface_variant: "#d7c1c1"
    
    readonly property color outline: "#a08c8c"
    readonly property color outline_variant: "#524343"
    
    // Surface Containers (Matugen 2.x)
    readonly property color surface_container_lowest: "#140c0c"
    readonly property color surface_container_low: "#221919"
    readonly property color surface_container: "#271d1d"
    readonly property color surface_container_high: "#322827"
    readonly property color surface_container_highest: "#3d3232"
    
    readonly property color accent: "#ffb3b3"

    Component.onCompleted: console.log("[Colors]: Singleton Loaded/Reloaded")
}
