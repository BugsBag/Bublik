import SwiftUI

struct AccessibilitySetupView: View {
  @State private var checkTimer: Timer?
  
  var body: some View {
    VStack(spacing: 16) {
          // Icon, Title, Description
        VStack(spacing: 12) {
          Image(systemName: "accessibility")
            .font(.system(size: 48))
            .foregroundColor(.blue)
          
          Text("Accessibility Access Required")
            .font(.title2.bold())
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
          
          Text("To detect your hotkeys and switch languages, Bublik needs permission to monitor keyboard events.")
            .multilineTextAlignment(.center)
            .font(.body)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        
        Divider()
        
          // Steps
        VStack(alignment: .leading, spacing: 16) {
          Text("How to grant access:")
            .font(.headline)
          
          instructionRow(number: "1", text: String(localized: "Click the button below to open System Settings."))
          instructionRow(number: "2", text: String(localized: "Find 'Bublik' in the list and turn on the switch."))
          instructionRow(number: "3", text: String(localized: "The app will restart automatically once access is granted."))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        
        Spacer(minLength: 0)
        
          // Open settings button
      VStack(spacing: 12) {
          Button {
            AccessibilityManager.openSystemSettings()
          } label: {
            Text("Open System Settings")
              .frame(maxWidth: .infinity)
              .font(.headline)
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.regular)
          
          Text("You can revoke this permission at any time in System Settings. After revoking permissions, you need to restart the application.")
            .font(.caption)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

    }
    .padding(20)
    .frame(width: 450)
    .frame(minHeight: 450, maxHeight: 650)
    .onAppear {
      startPermissionCheck()
    }
    .onDisappear {
      stopPermissionCheck()
    }
  }
  
  @ViewBuilder
  private func instructionRow(number: String, text: String) -> some View {
    HStack(alignment: .center, spacing: 12) {
      Text(number)
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(.white)
        .frame(width: 20, height: 20)
        .background(Circle().fill(Color.orange))
      
      Text(text)
        .font(.subheadline)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
  
  private func startPermissionCheck() {
    checkTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
      if AccessibilityManager.isTrusted() {
        DispatchQueue.main.async {
          self.stopPermissionCheck()
          AppUtils.relaunch()
        }
      }
    }
  }

  private func stopPermissionCheck() {
    checkTimer?.invalidate()
    checkTimer = nil
  }
  }


#Preview {
  AccessibilitySetupView()
    .environment(\.locale, Locale(identifier: "en"))
}
