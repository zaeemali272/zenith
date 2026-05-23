pragma Singleton
import QtQuick

QtObject {
    // Core Colors
    readonly property color primary: "#ffb4a2"
    readonly property color on_primary: "#561f11"
    readonly property color primary_container: "#723425"
    readonly property color on_primary_container: "#ffdad2"
    
    readonly property color secondary: "#e7bdb3"
    readonly property color on_secondary: "#442a23"
    readonly property color secondary_container: "#5d4038"
    readonly property color on_secondary_container: "#ffdad2"
    
    readonly property color tertiary: "#dac58c"
    readonly property color on_tertiary: "#3c2f04"
    readonly property color tertiary_container: "#544519"
    readonly property color on_tertiary_container: "#f7e1a6"
    
    readonly property color error: "#ffb4ab"
    readonly property color on_error: "#690005"
    readonly property color error_container: "#93000a"
    readonly property color on_error_container: "#ffdad6"
    
    readonly property color background: "#1a110f"
    readonly property color on_background: "#f1dfdb"
    
    readonly property color surface: "#1a110f"
    readonly property color on_surface: "#f1dfdb"
    readonly property color surface_variant: "#534340"
    readonly property color on_surface_variant: "#d8c2bd"
    
    readonly property color outline: "#a08c88"
    readonly property color outline_variant: "#534340"
    
    // Surface Containers (Matugen 2.x)
    readonly property color surface_container_lowest: "#140c0a"
    readonly property color surface_container_low: "#231917"
    readonly property color surface_container: "#271d1b"
    readonly property color surface_container_high: "#322825"
    readonly property color surface_container_highest: "#3d3230"
    
    readonly property color accent: "#ffb4a2"

    Component.onCompleted: console.log("[Colors]: Singleton Loaded/Reloaded")
}
