pragma Singleton
import QtQuick

QtObject {
    // Core Colors
    readonly property color primary: "#8ecff3"
    readonly property color on_primary: "#003549"
    readonly property color primary_container: "#004d68"
    readonly property color on_primary_container: "#c2e8ff"
    
    readonly property color secondary: "#b5c9d7"
    readonly property color on_secondary: "#20333d"
    readonly property color secondary_container: "#364954"
    readonly property color on_secondary_container: "#d1e5f3"
    
    readonly property color tertiary: "#c9c1ea"
    readonly property color on_tertiary: "#312c4c"
    readonly property color tertiary_container: "#484264"
    readonly property color on_tertiary_container: "#e6deff"
    
    readonly property color error: "#ffb4ab"
    readonly property color on_error: "#690005"
    readonly property color error_container: "#93000a"
    readonly property color on_error_container: "#ffdad6"
    
    readonly property color background: "#0f1417"
    readonly property color on_background: "#dfe3e7"
    
    readonly property color surface: "#0f1417"
    readonly property color on_surface: "#dfe3e7"
    readonly property color surface_variant: "#41484d"
    readonly property color on_surface_variant: "#c0c7cd"
    
    readonly property color outline: "#8a9297"
    readonly property color outline_variant: "#41484d"
    
    // Surface Containers (Matugen 2.x)
    readonly property color surface_container_lowest: "#0a0f12"
    readonly property color surface_container_low: "#171c1f"
    readonly property color surface_container: "#1b2023"
    readonly property color surface_container_high: "#262b2e"
    readonly property color surface_container_highest: "#313539"
    
    readonly property color accent: "#8ecff3"

    Component.onCompleted: console.log("[Colors]: Singleton Loaded/Reloaded")
}
