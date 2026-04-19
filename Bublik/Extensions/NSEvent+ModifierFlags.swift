import Cocoa

extension NSEvent.ModifierFlags {
  var shortcutString: String {
    var components: [String] = []
    
    // Standard macOS order: Control -> Option -> Shift -> Command
    if contains(.control) { components.append("⌃") }
    if contains(.option) { components.append("⌥") }
    if contains(.shift) { components.append("⇧") }
    if contains(.command) { components.append("⌘") }
    
    // Use two spaces between characters
    return components.joined(separator: "  ")
  }
}
