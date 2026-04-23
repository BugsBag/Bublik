import SwiftUI

struct AboutView: View {
  let startYear = 2026

  var yearString: String {
    let currentYear = Calendar.current.component(.year, from: Date())
    return currentYear > startYear ? "\(startYear)-\(currentYear)" : "\(startYear)"
  }
  
  var body: some View {
    VStack(spacing: 15) {
      
      // App image
      ZStack {
        RoundedRectangle(cornerRadius: 16)
          .fill(LinearGradient(colors: [.gray.opacity(0.1), .gray.opacity(0.05)], startPoint: .top, endPoint: .bottom))
          .frame(width: 80, height: 80)
        
        Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 65, height: 65)
          .foregroundStyle(.primary)
      }
      .padding(.top, 10)
      
      // Name and version
      VStack(spacing: 4) {
        Text(Bundle.main.appName)
          .font(.system(size: 24, weight: .bold, design: .rounded))
        
        Text("Version \(Bundle.main.appVersion). Build number \(Bundle.main.appBuildNumber).")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      
      // Link and author
      VStack(spacing: 8) {
        Link(destination: URL(string: Bundle.main.githubURL)!) {
          Label("Source Code on GitHub", systemImage: "arrow.branch")
            .font(.caption.bold())
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        
        Text("© \(yearString) Igor V.")
          .font(.system(size: 10))
          .foregroundColor(.secondary)
        
        Text("Licensed under GPLv3")
          .font(.system(size: 10, weight: .semibold))
          .foregroundColor(.secondary.opacity(0.8))
      }
      .padding(.top, 10)

    }
    .frame(alignment: .center)
  }
}

#Preview {
    AboutView()
}
