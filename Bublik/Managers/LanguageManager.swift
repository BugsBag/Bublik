import Foundation
import Carbon

class LanguageManager {
  private static var isSwitching = false
  private static var lastSwitchTime: Date = .distantPast
  
  // Cache for input sources
  private static var cachedSources: [TISInputSource]?
  
  private static let inputSourceFilter: CFDictionary = [
    kTISPropertyInputSourceIsSelectCapable: kCFBooleanTrue as Any,
    kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource as Any
  ] as CFDictionary

  static func setup() {
      // Listen for changes in enabled input sources to invalidate cache
      // If the user adds or removes a language in macOS preferences,
      // the source list will be updated without rebooting.
    DistributedNotificationCenter.default().addObserver(
        forName: NSNotification.Name(kTISNotifyEnabledKeyboardInputSourcesChanged as String),
        object: nil,
        queue: .main
    ) { _ in
        cachedSources = nil
    }
  }

  static func toggleLanguage() {
    // Debounce and double-call protection
    // If less than 50ms passed since last switch — ignore
    if isSwitching || Date().timeIntervalSince(lastSwitchTime) < 0.05 {
      return
    }
    
    isSwitching = true
    
    // Execute on main thread since TISSelectInputSource works with UI state
    DispatchQueue.main.async {
      defer {
        isSwitching = false
        lastSwitchTime = Date()
      }
      
      // Get current layout
      guard let currentSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return }
      let currentID = getID(currentSource)
      
      // Get or update sources list
      if cachedSources == nil {
          guard let sources = TISCreateInputSourceList(inputSourceFilter, false)?.takeRetainedValue() as? [TISInputSource] else { return }
          // Filter only keyboard layouts
          cachedSources = sources.filter { isKeyboardLayout($0) }
      }
      
      guard let selectableSources = cachedSources, !selectableSources.isEmpty else { return }
      
      // Find next
      if let currentIndex = selectableSources.firstIndex(where: { getID($0) == currentID }) {
        let nextIndex = (currentIndex + 1) % selectableSources.count
        TISSelectInputSource(selectableSources[nextIndex])
      } else {
        // If current not found (e.g. list changed), just take first and reset cache
        TISSelectInputSource(selectableSources[0])
        cachedSources = nil
      }
    }
  }
  
  private static func getID(_ source: TISInputSource) -> String {
    guard let cfID = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return "Unknown" }
    return Unmanaged<CFString>.fromOpaque(cfID).takeUnretainedValue() as String
  }
  
  private static func isKeyboardLayout(_ source: TISInputSource) -> Bool {
    guard let cfCategory = TISGetInputSourceProperty(source, kTISPropertyInputSourceCategory) else { return false }
    let category = Unmanaged<CFString>.fromOpaque(cfCategory).takeUnretainedValue() as String
      // Check that it is specifically a keyboard layout
    return category == (kTISCategoryKeyboardInputSource as String)
  }
}
