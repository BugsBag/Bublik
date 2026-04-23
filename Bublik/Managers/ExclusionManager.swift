import AppKit
import Combine
import SwiftUI

class ExclusionManager: ObservableObject {
  static let shared = ExclusionManager()
  private let storageKey = "excludedApps"
  
  @Published var excludedApps: [String] {
    didSet {
      UserDefaults.standard.set(excludedApps, forKey: storageKey)
    }
  }
  
  private init() {
    self.excludedApps = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
  }
  
    /// Checks if the current active application is in the exclusion list
  func isCurrentAppExcluded() -> Bool {
      // Get the bundle identifier of the currently active application
    guard let activeAppId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
      return false
    }
    return excludedApps.contains(activeAppId)
  }
  
  func addApp(bundleId: String) {
    if !excludedApps.contains(bundleId) {
      excludedApps.append(bundleId)
    }
  }
  
  func removeApp(at offsets: IndexSet) {
    excludedApps.remove(atOffsets: offsets)
  }
}
