import SwiftUI

struct UpdateAvailableView: View {
  let version: String
  let isManual: Bool
  @ObservedObject var manager = UpdateManager.shared
  
  var body: some View {
    VStack(spacing: 0) {
        // Skipped version banner
      if isManual && version == manager.skippedVersion && manager.downloadedFileURL == nil {
        skippedVersionBanner
      }
      
        // New version content
      HStack(alignment: .top, spacing: 20) {
        Image(nsImage: NSApp.applicationIconImage)
          .resizable()
          .frame(width: 64, height: 64)
        
        VStack(alignment: .leading, spacing: 8) {
          if manager.downloadedFileURL == nil {
            Text("A new version of Bublik is available!")
              .font(.headline)
            Text("Version \(version) is now available. Would you like to download it to your Downloads folder?")
              .font(.subheadline)
              .foregroundColor(.secondary)
          } else {
            Text("Download Complete!")
              .font(.headline)
            Text("The installer has been downloaded. Would you like to close Bublik and open the installer now?")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          
          if manager.isDownloading {
            HStack {
              ProgressView().controlSize(.small)
              Text("Downloading to your Downloads folder...").font(.caption).foregroundColor(.secondary)
            }
          }
        }
      }
      
      Spacer()
      
        // Bottom buttons
      HStack {
        if manager.downloadedFileURL == nil {
            // Suggestion for download
          if !isManual {
            Button("Skip This Version") {
              manager.skippedVersion = version
              manager.closeUpdateWindow()
            }
            .disabled(manager.isDownloading)
          }
          
          Spacer()
          
          Button("Remind Me Later") { manager.closeUpdateWindow() }
            .disabled(manager.isDownloading)
          
          Button("Download Update") {
            manager.downloadUpdate()
          }
          .buttonStyle(.borderedProminent)
          .disabled(manager.isDownloading)
          
        } else {
          // Suggestion for post-download actions
          Button("Show in Finder") {
            manager.finalizeUpdate(mountFile: false, shouldQuitApp: false)
          }
          Spacer()
          Button("Close Bublik & Install") {
            manager.finalizeUpdate(mountFile: true, shouldQuitApp: true)
          }
          .buttonStyle(.borderedProminent)
        }
      }
    }
    .padding(25)
    .frame(width: 550, height: (isManual && version == manager.skippedVersion) ? 230 : 190)
    .animation(.default, value: manager.downloadedFileURL)
  }
  
  private var skippedVersionBanner: some View {
    HStack(spacing: 12) {
      Image(systemName: "exclamationmark.triangle.fill").symbolRenderingMode(.multicolor)
      Text("You previously skipped this version, but it is still the latest available.")
        .font(.system(size: 11, weight: .medium))
      Spacer()
    }
    .padding(10)
    .background(Color(NSColor.quaternaryLabelColor))
    .cornerRadius(6)
    .padding(.bottom, 16)
  }
}

#Preview {
  UpdateAvailableView(version: "0.1.0", isManual: false)
}
