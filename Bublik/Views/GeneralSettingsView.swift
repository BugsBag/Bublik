import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
  @ObservedObject var updateManager = UpdateManager.shared
  
  @AppStorage("launchAtLogin") private var launchAtLogin = false
    // get first element from array or awalable languages
  @AppStorage("selectedLanguage") private var selectedLanguage: String = {
    let current = UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first
    return current ?? "en"
  }()
  @AppStorage("updateInterval") private var updateInterval = "never"
  
  @State private var isRestartButtonDisabled = false
  @State private var manualCheckResult: UpdateCheckResult? = nil
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
        // Autostart section
      settingRow(
        title: String(localized: "Launch at Login"),
        description: String(localized: "This allows the app to start working immediately after your will Log in to your profile.")) {
          Toggle(isOn: $launchAtLogin) {
              // skip adding the title to the localization
            Text(verbatim: "")
          }
          .toggleStyle(.switch)
          .labelsHidden()
          .controlSize(.small)
          .onChange(of: launchAtLogin) { _, newValue in
            toggleAutoStart(enabled: newValue)
          }
        }
      
      Divider().padding(.vertical, 8)
      
        // Lanuage select section
      settingRow(
        title: String(localized: "Language"),
        description: String(localized: "Changing the language will have consequences after restarting the application.")) {
          Picker(selection: $selectedLanguage) {
            Text("English").tag("en")
            Text("Russian").tag("ru")
          } label: {
              // skip adding the title to the localization
            Text(verbatim: "")
          }
          .labelsHidden()
          .fixedSize()
          .onChange(of: selectedLanguage) { _, newValue in
            UserDefaults.standard.set([newValue], forKey: "AppleLanguages")
          }
        }
      
      Divider().padding(.vertical, 8)
      
        // Updates section
      settingRow(
        title: String(localized: "Updates"),
        description: String(localized: "Configure how often Bublik checks for new versions on GitHub.")) {
          VStack(alignment: .trailing, spacing: 8) {
            Picker(selection: $updateInterval) {
              Text("Never").tag("never")
              Text("Daily").tag("daily")
              Text("Weekly").tag("weekly")
              Text("Monthly").tag("monthly")
            } label: {
                // skip adding the title to the localization
              Text(verbatim: "")
            }
            .labelsHidden()
            .fixedSize()
            .onChange(of: updateInterval) { _, _ in
              updateManager.setupBackgroundActivity()
            }
            
            Button {
              updateManager.checkForUpdates(isManual: true) { result in
                self.manualCheckResult = result
              }
            } label: {
              HStack(spacing: 6) {
                if updateManager.isChecking {
                  ProgressView().controlSize(.small)
                  Text("Checking updates...")
                } else if manualCheckResult == .updated {
                  Text("No updates found")
                } else if manualCheckResult == .available {
                  Text("Update found")
                } else {
                  Text("Check now")
                }
              }
            }
            .buttonStyle(.bordered)
            .disabled(updateManager.isChecking || manualCheckResult != nil)
          }
        }
      
      Divider().padding(.vertical, 8)
      
        // Restart app section
      settingRow(
        title: String(localized: "Restart application"),
        description: String(localized: "All changes will be saved.")) {
          Button {
            isRestartButtonDisabled = true
            AppUtils.relaunch()
          } label: {
            Label("Restart application", systemImage: "arrow.clockwise")
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.small)
          .disabled(isRestartButtonDisabled)
        }
    }
    .frame(alignment: .center)
    .onAppear {
      manualCheckResult = nil
    }
  }
  
    /// Helper view for build compact row
  @ViewBuilder
  private func settingRow<Content: View>(title: String, description: String, @ViewBuilder content: () -> Content) -> some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.system(size: 13, weight: .medium))
        Text(description)
          .font(.system(size: 11))
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer()
      content()
    }
  }
  
  func toggleAutoStart(enabled: Bool) {
    let service = SMAppService.mainApp
    do {
      if enabled {
        try service.register()
      } else {
        try service.unregister()
      }
    } catch {
        // TODO - show error to user?
      print("Autostart configuration error: \(error)")
    }
  }
}

#Preview {
  GeneralSettingsView()
}
