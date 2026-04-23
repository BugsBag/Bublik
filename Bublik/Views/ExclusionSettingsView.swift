import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ExclusionSettingsView: View {
  @ObservedObject var manager = ExclusionManager.shared
  
  var body: some View {
    VStack(alignment: .leading, spacing: 15) {
        // Header
      VStack(alignment: .leading, spacing: 4) {
        Text("Excluded apps")
          .font(.headline)
        
        Text("Bublik will ignore keyboard events when these apps are in focus.")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      
        // Application list
      List {
        ForEach(manager.excludedApps, id: \.self) { (bundleId: String) in
          HStack(spacing: 8) {
            if let appPath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
              Image(nsImage: NSWorkspace.shared.icon(forFile: appPath.path))
                .resizable()
                .frame(width: 16, height: 16)
            }
            
            Text(appName(for: bundleId))
            Spacer()
            Text(bundleId).font(.caption2).foregroundColor(.secondary)
            
            Button(action: { removeAppByBundleId(bundleId) }) {
              Image(systemName: "x.circle.fill")
                .foregroundColor(.secondary)
                .opacity(0.7)
            }
            .buttonStyle(.plain)
          }
          .padding(.vertical, 4)
        }
      }
      .listStyle(.bordered)
      
        // Footer
      HStack {
        Button(action: selectApp) {
          Label("Add application...", systemImage: "plus.circle")
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
  
    // Removes an app from the exclusion list by its bundle identifier
  func removeAppByBundleId(_ bundleId: String) {
    if let index = manager.excludedApps.firstIndex(of: bundleId) {
      manager.removeApp(at: IndexSet(integer: index))
    }
  }
  
  func selectApp() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowedContentTypes = [.application]
    panel.directoryURL = URL(fileURLWithPath: "/Applications")
    
    if panel.runModal() == .OK {
      if let url = panel.url, let bundle = Bundle(url: url) {
        if let bundleId = bundle.bundleIdentifier {
          manager.addApp(bundleId: bundleId)
        }
      }
    }
  }
  
  func appName(for bundleId: String) -> String {
    if let path = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
      return path.lastPathComponent.replacingOccurrences(of: ".app", with: "")
    }
    return bundleId
  }
}

#Preview {
  ExclusionSettingsView()
}
