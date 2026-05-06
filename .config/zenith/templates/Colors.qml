pragma Singleton
import QtQuick

QtObject {
    // Core Colors
    readonly property color primary: "{{colors.primary.default.hex}}"
    readonly property color on_primary: "{{colors.on_primary.default.hex}}"
    readonly property color primary_container: "{{colors.primary_container.default.hex}}"
    readonly property color on_primary_container: "{{colors.on_primary_container.default.hex}}"
    
    readonly property color secondary: "{{colors.secondary.default.hex}}"
    readonly property color on_secondary: "{{colors.on_secondary.default.hex}}"
    readonly property color secondary_container: "{{colors.secondary_container.default.hex}}"
    readonly property color on_secondary_container: "{{colors.on_secondary_container.default.hex}}"
    
    readonly property color tertiary: "{{colors.tertiary.default.hex}}"
    readonly property color on_tertiary: "{{colors.on_tertiary.default.hex}}"
    readonly property color tertiary_container: "{{colors.tertiary_container.default.hex}}"
    readonly property color on_tertiary_container: "{{colors.on_tertiary_container.default.hex}}"
    
    readonly property color error: "{{colors.error.default.hex}}"
    readonly property color on_error: "{{colors.on_error.default.hex}}"
    readonly property color error_container: "{{colors.error_container.default.hex}}"
    readonly property color on_error_container: "{{colors.on_error_container.default.hex}}"
    
    readonly property color background: "{{colors.background.default.hex}}"
    readonly property color on_background: "{{colors.on_background.default.hex}}"
    
    readonly property color surface: "{{colors.surface.default.hex}}"
    readonly property color on_surface: "{{colors.on_surface.default.hex}}"
    readonly property color surface_variant: "{{colors.surface_variant.default.hex}}"
    readonly property color on_surface_variant: "{{colors.on_surface_variant.default.hex}}"
    
    readonly property color outline: "{{colors.outline.default.hex}}"
    readonly property color outline_variant: "{{colors.outline_variant.default.hex}}"
    
    // Surface Containers (Matugen 2.x)
    readonly property color surface_container_lowest: "{{colors.surface_container_lowest.default.hex}}"
    readonly property color surface_container_low: "{{colors.surface_container_low.default.hex}}"
    readonly property color surface_container: "{{colors.surface_container.default.hex}}"
    readonly property color surface_container_high: "{{colors.surface_container_high.default.hex}}"
    readonly property color surface_container_highest: "{{colors.surface_container_highest.default.hex}}"
    
    readonly property color accent: "{{colors.primary.default.hex}}"

    Component.onCompleted: console.log("[Colors]: Singleton Loaded/Reloaded")
}
