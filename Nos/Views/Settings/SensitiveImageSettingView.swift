import Dependencies
import SensitiveContentAnalysis
import SwiftUI

struct SensitiveImageSettingView: View {
    @Dependency(\.featureFlags) private var featureFlags
    
    private let analyzer = SCSensitivityAnalyzer()
    
    var body: some View {
        Form {
            Section {
                Group {
                    incomingImagesToggle
                    outgoingImagesToggle
                }
            } header: {
                VStack(alignment: .leading, spacing: 10) {
                    Text(analyzer.analysisPolicy.description)
                        .foregroundColor(.primaryTxt)
                        .font(.clarity(.semibold))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Use the toggles below to override the Sensitive Content Analyzer, once enabled.")
                        .foregroundColor(.secondaryTxt)
                        .font(.footnote)
                }
                .textCase(nil)
                .listRowInsets(EdgeInsets())
                .padding(.top, 30)
                .padding(.bottom, 20)
            }
            .listRowGradientBackground()
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .nosNavigationBar("Sensitive Content")
    }
    
    private var incomingImagesToggle: some View {
        VStack {
            NosToggle("Flag All Downloaded Images", isOn: shouldFlagIncomingImages)
            
            HStack {
                Text("When on, all downloaded images will be flagged as sensitive. With it off, the real analyzer will determine sensitivity.") // swiftlint:disable:this line_length
                    .foregroundColor(.secondaryTxt)
                    .font(.footnote)
                Spacer()
            }
        }
    }
    
    private var outgoingImagesToggle: some View {
        VStack {
            NosToggle("Flag All Uploaded Images", isOn: shouldFlagOutgoingImages)
            
            HStack {
                Text("When on, all uploaded images will be flagged as sensitive. With it off, the real analyzer will determine sensitivity.")   // swiftlint:disable:this line_length
                    .foregroundColor(.secondaryTxt)
                    .font(.footnote)
                Spacer()
            }
        }
    }
    
    private var shouldFlagIncomingImages: Binding<Bool> {
        Binding<Bool>(
            get: { featureFlags.isEnabled(.sensitiveContentIncoming) },
            set: { featureFlags.setFeature(.sensitiveContentIncoming, enabled: $0) }
        )
    }
    
    private var shouldFlagOutgoingImages: Binding<Bool> {
        Binding<Bool>(
            get: { featureFlags.isEnabled(.sensitiveContentOutgoing) },
            set: { featureFlags.setFeature(.sensitiveContentOutgoing, enabled: $0) }
        )
    }
}
