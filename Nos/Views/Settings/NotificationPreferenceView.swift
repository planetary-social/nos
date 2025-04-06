import SwiftUI
import Dependencies

/// A view that allows the user to configure notification preferences
struct NotificationPreferenceView: View {
    @Dependency(\.pushNotificationService) private var pushNotificationService
    @EnvironmentObject private var router: Router
    
    @State private var selectedPreference: NotificationPreference = .allMentions
    @State private var notifyOnThreadReplies: Bool = true
    
    var body: some View {
        VStack(spacing: 24) {
            // Thread replies toggle
            VStack(alignment: .leading, spacing: 12) {
                Text("threadRepliesTitle")
                    .font(.headline)
                    .foregroundColor(.primaryTxt)
                
                Toggle(isOn: $notifyOnThreadReplies) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("threadRepliesDescription")
                            .font(.subheadline)
                            .foregroundColor(.primaryTxt)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(2)
                    }
                }
                .tint(.green)
            }
            
            // Source filter section
            VStack(alignment: .leading, spacing: 12) {
                Text("sourceFilterTitle")
                    .font(.headline)
                    .foregroundColor(.primaryTxt)
                
                Text("sourceFilterDescription")
                    .font(.subheadline)
                    .foregroundColor(.secondaryTxt)
                
                // Source filter options
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
            }
            
            // Muted users and threads section
            VStack(alignment: .leading, spacing: 16) {
                Text("manageMutesTitle")
                    .font(.headline)
                    .foregroundColor(.primaryTxt)
                
                VStack(spacing: 8) {
                    Button {
                        router.push(MutesDestination())
                    } label: {
                        HStack {
                            Image(systemName: "speaker.slash.fill")
                                .foregroundColor(.secondaryTxt)
                            
                            Text("mutedUsers")
                                .font(.subheadline)
                                .foregroundColor(.primaryTxt)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondaryTxt)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondaryTxt.opacity(0.05))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // TODO: Add MutedThreadsView when implemented
                    Button {
                        // Will link to muted threads view when implemented
                    } label: {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .foregroundColor(.secondaryTxt)
                            
                            Text("mutedThreads")
                                .font(.subheadline)
                                .foregroundColor(.primaryTxt)
                            
                            Spacer()
                            
                            Text("comingSoon")
                                .font(.caption)
                                .foregroundColor(.secondaryTxt)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.secondaryTxt.opacity(0.1))
                                )
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondaryTxt.opacity(0.05))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(true) // Disabled until muted threads feature is implemented
                }
            }
        }
        .onAppear {
            // Set the initial state
            selectedPreference = pushNotificationService.notificationPreference
            notifyOnThreadReplies = pushNotificationService.notifyOnThreadReplies
        }
        .onChange(of: selectedPreference) { _, newValue in
            // Update the service when selection changes
            pushNotificationService.notificationPreference = newValue
        }
        .onChange(of: notifyOnThreadReplies) { _, newValue in
            // Update the thread replies preference
            pushNotificationService.notifyOnThreadReplies = newValue
        }
    }
}

#Preview {
    let previewData = PreviewData()
    
    return NotificationPreferenceView()
        .inject(previewData: previewData)
        .environmentObject(previewData.router)
        .padding()
}