import SwiftUI
import Combine

  // GitHub API respose models
struct GitHubAsset: Codable {
  let name: String
  let browser_download_url: String
}

struct GitHubRelease: Codable {
  let tag_name: String
  let assets: [GitHubAsset]
}

enum UpdateCheckResult {
  case updated      // Обновлений нет
  case available    // Найдено новое
}

// MainActor because we can call methods from background thread
@MainActor
class UpdateManager: ObservableObject {
  static let shared = UpdateManager()
  
  let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
  
  @AppStorage("skippedVersion") var skippedVersion: String = ""
  @AppStorage("updateInterval") var updateInterval = "never"
  
  @Published var isChecking = false
  @Published var isDownloading = false
  @Published var downloadedFileURL: URL? = nil
  
  var lastFoundAssetURL: String? = nil
  
  private var updateWindow: NSWindow?
  private let activityIdentifier = Bundle.main.bundleIdentifier! + ".updateCheck"
  
  private init() {
    setupBackgroundActivity()
  }
  
  func checkForUpdates(isManual: Bool, completion: (@MainActor (UpdateCheckResult) -> Void)? = nil) {
    if !isManual && updateInterval == "never" { return }
    if isManual { isChecking = true }
    
    Task {
      var result: UpdateCheckResult = .updated
      
      defer {
        if isManual { isChecking = false }
        completion?(result)
        setupBackgroundActivity()
      }
      
      do {
         guard let url = URL(string: Bundle.main.githubApiLatestReleaseURL) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Bublik-App", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
          throw URLError(.badServerResponse)
        }
        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        self.lastFoundAssetURL = release.assets.first(where: { $0.name.hasSuffix(".dmg") })?.browser_download_url
          // clean version from "v" letter if exists (e.g. "v1.1.2" -> "1.1.2")
        let fetchedVersion = release.tag_name.trimmingCharacters(in: CharacterSet.decimalDigits.inverted)
        
        if self.isVersionHigher(fetchedVersion, than: self.currentVersion) {
          result = .available
          if isManual || fetchedVersion != self.skippedVersion {
            self.showUpdateWindow(version: fetchedVersion, isManualUpdateCheck: isManual)
          }
        }
      }
      catch {
        print("Update check failed: \(error.localizedDescription)")
      }
    }
  }
  
  func setupBackgroundActivity() {
    let interval = getIntervalInSeconds()
    if interval <= 0 { return }
    
    let activity = NSBackgroundActivityScheduler(identifier: activityIdentifier)
    activity.repeats = true
    activity.interval = interval
    activity.tolerance = interval * 0.1 // 10% tolerance
    
    activity.schedule { completion in
      Task { @MainActor in
        print("--- Scheduler tick ---")
        self.checkForUpdates(isManual: false)
        completion(.finished)
      }
    }
  }
  
  private func getIntervalInSeconds() -> TimeInterval {
    switch updateInterval {
      case "daily":   return 86400
      case "weekly":  return 604800
      case "monthly": return 2592000
      default:        return 0
    }
  }
  
  private func isVersionHigher(_ new: String, than current: String) -> Bool {
    return new.compare(current, options: .numeric) == .orderedDescending
  }
  
  func downloadUpdate() {
    guard let urlString = lastFoundAssetURL, let url = URL(string: urlString) else { return }
    
    isDownloading = true
    
    Task {
      do {
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let destinationURL = downloadsURL.appendingPathComponent(url.lastPathComponent)
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
          try? FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        
        self.downloadedFileURL = destinationURL
        self.isDownloading = false
      } catch {
        print("Download failed: \(error)")
        self.isDownloading = false
      }
    }
  }
  
  func finalizeUpdate(mountFile: Bool, shouldQuitApp: Bool) {
    guard let fileURL = downloadedFileURL else { return }
    
    if mountFile { NSWorkspace.shared.open(fileURL) }
    
    if shouldQuitApp {
      NSApp.terminate(nil)
    } else {
        // Open folder in Finder
      NSWorkspace.shared.activateFileViewerSelecting([fileURL])
      closeUpdateWindow()
    }
  }
  
    // MARK: UpdateAvailableView Window Management
  func showUpdateWindow(version: String, isManualUpdateCheck: Bool) {
    if updateWindow != nil {
      updateWindow?.makeKeyAndOrderFront(nil)
      return
    }
    
    let contentView = UpdateAvailableView(version: version, isManual: isManualUpdateCheck)
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 450, height: 220),
      styleMask: [.titled, .closable],
      backing: .buffered, defer: false)
    
    window.center()
    window.title = String(localized: "Software Update")
    window.contentView = NSHostingView(rootView: contentView)
    window.isReleasedWhenClosed = false
    window.level = .floating
    window.makeKeyAndOrderFront(nil)
    
    self.updateWindow = window
  }
  
  func closeUpdateWindow() {
    updateWindow?.close()
    updateWindow = nil
  }
}
