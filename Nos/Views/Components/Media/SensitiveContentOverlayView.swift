import Combine
import SwiftUI
import SwiftUINavigation
import UIKit

struct VisualEffectView: UIViewRepresentable {
    let effect: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: effect))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: effect)
    }
}

/// A view to add over another view as an overlay that blurs the image beneath while it is being analyzed.
struct SensitiveContentOverlayView: View {
    /// The URL of the content to check for sensitivity.
    let url: URL
    
    /// The author of the content being analyzed.
    ///
    /// > Note: The author is required here to provide the user with the ability to block or report the user or content.
    let author: Author?
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var analysisState: SensitiveContentController.AnalysisState
    @State private var cancellable: AnyCancellable?
    @State private var showingReportMenu = false
    
    @State private var alert: AlertState<Never>?
    
    init(url: URL, author: Author?) {
        self.url = url
        self.author = author
        
        let shouldAnalyzeContent = url.isImage && SensitiveContentController.shared.isSensitivityAnalysisEnabled
        analysisState = shouldAnalyzeContent ? .analyzing : .allowed
    }
    
    var body: some View {
        ZStack {
            VisualEffectView(effect: .dark)
            
            if analysisState == .analyzing {
                ProgressView()
                    .scaleEffect(2)
            } else {
                Text("This content may be sensitive.")  // TODO: Localize
                
                HStack {
                    Spacer()
                    VStack(alignment: .trailing) {
                        Menu {
                            Button("muteUser") {
                                Task { @MainActor in
                                    do {
                                        try await author?.mute(viewContext: viewContext)
                                    } catch {
                                        alert = AlertState(title: {
                                            TextState(String(localized: "error"))
                                        }, message: {
                                            TextState(error.localizedDescription)
                                        })
                                    }
                                }
                            }
                            
                            Button("flagUser", action: { showingReportMenu = true })
                        } label: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Circle().fill(Color.gray.opacity(0.5)))
                                .frame(width: 40, height: 40)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        Button {
                            Task {
                                await SensitiveContentController.shared.allowContent(at: url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "eye")
                                Text("Show")
                            }
                            .padding([.top, .bottom], 12)
                            .padding([.leading, .trailing], 16)
                        }
                        .background(Color.gray.opacity(0.5))
                        .clipShape(Capsule())
                    }
                    .padding([.top, .bottom], 12)
                    .padding([.leading, .trailing], 12)
                }
            }
        }
        .opacity(analysisState.shouldObfuscate ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: analysisState)
        .contentShape(Rectangle()) // Define the touchable area to capture taps
        .onTapGesture {} // Prevent taps from passing through the overlay
        .reportMenu($showingReportMenu, reportedObject: .author(author!))
        .task {
            if url.isImage && SensitiveContentController.shared.isSensitivityAnalysisEnabled {
                Task {  // The separate Task here is intentional! SwiftUI will sometimes cancel the .task of the view.
                    await SensitiveContentController.shared.analyzeContent(atURL: url)
                    
                    cancellable = await SensitiveContentController.shared.analysisStatePublisher(for: url)
                        .receive(on: DispatchQueue.main)
                        .sink { state in
                            analysisState = state
                        }
                }
            }
        }
    }
}
