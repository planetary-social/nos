import Combine
import SwiftUI

struct NoteCardHeader: View {
    
    let authorSafeName: String
    let authorProfilePhotoURL: URL?
    let noteExpirationDate: Date?
    let noteCreatedDate: Date?
    let clientName: String?
    let note: Event?
    
    @State private var currentTime = Date.now
    @State private var expirationDateDistanceString: String?
    @State private var createdDateDistanceString: String?
    @State private var isLoadingClientInfo = false
    
    /// A timer used to cause a periodic refresh of the date strings.
    @State private var timer: Timer.TimerPublisher?
    @State private var timerCancellable: AnyCancellable?
    
    @EnvironmentObject private var router: Router
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            AuthorLabel(name: authorSafeName, profilePhotoURL: authorProfilePhotoURL)
            
            if let expirationDateDistanceString {
                Image.disappearingMessages
                    .resizable()
                    .foregroundColor(.secondaryTxt)
                    .frame(width: 25, height: 25)
                Text(expirationDateDistanceString)
                    .lineLimit(1)
                    .font(.clarity(.medium))
                    .foregroundColor(.secondaryTxt)
            } else if let createdDateDistanceString {
                HStack(spacing: 4) {
                    Text(createdDateDistanceString)
                        .lineLimit(1)
                        .font(.clarity(.medium))
                        .foregroundColor(.secondaryTxt)
                    
                    // Display client name if available
                    if let clientName = clientName {
                        Button {
                            Task {
                                isLoadingClientInfo = true
                                await note?.loadClientMetadata()
                                isLoadingClientInfo = false
                                
                                // If we find a client app in author's profile, go to their profile
                                if let clientInfo = note?.clientInfo,
                                    let parsed = clientInfo.parsedIdentifier,
                                    let pubkey = parsed.pubkey {
                                    Task { @MainActor in
                                        router.push(.author(pubkey))
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 2) {
                                Text("• via \(clientName)")
                                    .lineLimit(1)
                                    .font(.clarity(.medium, size: 12, textStyle: .caption))
                                    .foregroundColor(.secondaryTxt)
                                
                                if isLoadingClientInfo {
                                    ProgressView()
                                        .scaleEffect(0.5)
                                }
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.leading, 10)
        .onAppear {
            update()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func update() {
        createdDateDistanceString = noteCreatedDate?.distanceString()
        if let noteExpirationDate {
            expirationDateDistanceString = currentTime.distanceString(noteExpirationDate)
        }
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 60, on: .main, in: .common)
        timerCancellable = timer?
            .autoconnect()
            .sink { newTime in
                currentTime = newTime
                update()
            }
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        timer = nil
    }
}

struct NoteCardHeader_Previews: PreviewProvider {
    static var previewData = PreviewData()
    
    static var previews: some View {
        NoteCardHeader(
            authorSafeName: previewData.previewAuthor.safeName,
            authorProfilePhotoURL: previewData.previewAuthor.profilePhotoURL,
            noteExpirationDate: previewData.imageNote.expirationDate,
            noteCreatedDate: previewData.imageNote.createdAt,
            clientName: "nos.social",
            note: previewData.imageNote
        )
        .inject(previewData: previewData)
        .environmentObject(previewData.router)
        
        NoteCardHeader(
            authorSafeName: previewData.previewAuthor.safeName,
            authorProfilePhotoURL: previewData.previewAuthor.profilePhotoURL,
            noteExpirationDate: previewData.expiringNote.expirationDate,
            noteCreatedDate: previewData.expiringNote.createdAt,
            clientName: nil,
            note: nil
        )
        .inject(previewData: previewData)
        .environmentObject(previewData.router)
    }
}
