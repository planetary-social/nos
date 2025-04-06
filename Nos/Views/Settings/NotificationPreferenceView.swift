import SwiftUI
import Dependencies

/// A view that allows the user to configure notification preferences
struct NotificationPreferenceView: View {
    @Dependency(\.pushNotificationService) private var pushNotificationService
    
    @State private var selectedPreference: NotificationPreference = .allMentions
    
    var body: some View {
        VStack {
            NosSegmentedPicker(
                title: "notificationSettings",
                options: NotificationPreference.allCases,
                selection: $selectedPreference,
                getTitle: { $0.description }
            )
            
            HStack {
                Text("notificationSettingsDescription")
                    .foregroundColor(.secondaryTxt)
                    .font(.footnote)
                Spacer()
            }
        }
        .onAppear {
            // Set the initial state
            selectedPreference = pushNotificationService.notificationPreference
        }
        .onChange(of: selectedPreference) { _, newValue in
            // Update the service when selection changes
            pushNotificationService.notificationPreference = newValue
        }
    }
}

#Preview {
    let previewData = PreviewData()
    
    return NotificationPreferenceView()
        .inject(previewData: previewData)
        .padding()
}