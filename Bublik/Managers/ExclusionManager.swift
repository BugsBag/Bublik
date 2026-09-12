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

    // Bundle identifier of the frontmost application.
    // Updated via NSWorkspace notifications so that the keyboard event tap
    // callback never has to call NSWorkspace directly (which can block).
    // The lock protects cross-thread access (event tap thread vs. main thread).
  private let frontmostAppLock = NSLock()
  private var cachedFrontmostAppId: String?

  private var frontmostAppId: String? {
    get { frontmostAppLock.withLock { cachedFrontmostAppId } }
    set { frontmostAppLock.withLock { cachedFrontmostAppId = newValue } }
  }

  private init() {
    self.excludedApps = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
    self.cachedFrontmostAppId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier

    NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didActivateApplicationNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
      self?.frontmostAppId = app?.bundleIdentifier
    }
  }

    /// Checks if the current active application is in the exclusion list
  func isCurrentAppExcluded() -> Bool {
    guard let activeAppId = frontmostAppId else {
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
