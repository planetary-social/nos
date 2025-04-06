import SwiftUI
import Dependencies

/// A view that allows the user to configure notification preferences
struct NotificationPreferenceView: View {
    @Dependency(\.pushNotificationService) private var pushNotificationService
    
    @State private var selectedPreference: NotificationPreference = .allMentions
    
    var body: some View {
        VStack {
            // Using a VStack for vertical arrangement for better readability
            VStack(spacing: 12) {
                ForEach(NotificationPreference.allCases) { preference in
                    Button {
                        selectedPreference = preference
                    } label: {
                        HStack {
                            preference.image
                                .foregroundColor(selectedPreference == preference ? .accentColor : .secondaryTxt)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preference.titleKey)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(selectedPreference == preference ? .primaryTxt : .secondaryTxt)
                                
                                Text(preference.description)
                                    .font(.caption)
                                    .foregroundColor(.secondaryTxt)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if selectedPreference == preference {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedPreference == preference ? Color.accentColor.opacity(0.1) : Color.clear)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            HStack {
                Text("notificationSettingsDescription")
                    .foregroundColor(.secondaryTxt)
                    .font(.footnote)
                Spacer()
            }
            .padding(.top, 8)
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
