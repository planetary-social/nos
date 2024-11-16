import Dependencies
import SensitiveContentAnalysis
import SwiftUI

/// A debug view to manage testing of sensitive content analysis.
struct SensitiveImageSettingView: View {
    @Dependency(\.featureFlags) private var featureFlags
    @Dependency(\.userDefaults) private var userDefaults
    
    private let sensitiveContentAnalysisEnabledKey = "sensitiveContentAnalysisEnabled"
    private let sensitiveContentAnalysisFlagAllKey = "sensitiveContentAnalysisFlagAll"
    
    private let analyzer = SCSensitivityAnalyzer()
    
    var body: some View {
        Form {
            Text(analyzer.analysisPolicy.description)
                .foregroundColor(.primaryTxt)
                .font(.clarity(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .textCase(nil)
                .listRowGradientBackground()
            
            if analyzer.analysisPolicy != .disabled {
                Section {
                    sensitiveContentAnalysisToggle
                } header: {
                }
                .listRowGradientBackground()
                
                Section {
                    flagAllToggle
                } header: {
                    VStack(alignment: .leading, spacing: 10) {
                        
                        Text("Use the toggle below to override the Sensitive Content Analyzer, once enabled.")
                            .foregroundColor(.secondaryTxt)
                            .font(.footnote)
                    }
                    .textCase(nil)
                    .listRowInsets(EdgeInsets())
                    .padding(.top, 30)
                    .padding(.bottom, 20)
                }
                .listRowGradientBackground()
                .disabled(!featureFlags.isEnabled(.sensitiveContentAnalysisEnabled))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .nosNavigationBar("Sensitive Content")
    }
    
    private var sensitiveContentAnalysisToggle: some View {
        VStack {
            NosToggle("Sensitive Content Analysis", isOn: isSensitiveContentAnalysisEnabled)
            
            HStack {
                Text("When on, downloaded and uploaded images will be scanned for sensitivity.")
                    .foregroundColor(.secondaryTxt)
                    .font(.footnote)
                Spacer()
            }
        }
    }
    
    private var flagAllToggle: some View {
        VStack {
            NosToggle("Flag All Content As Sensitive", isOn: shouldFlagAllContentAsSensitive)
            
            HStack {
                Text("When on, all images will be flagged as sensitive. With it off, the real analyzer will determine sensitivity.")   // swiftlint:disable:this line_length
                    .foregroundColor(.secondaryTxt)
                    .font(.footnote)
                Spacer()
            }
        }
    }
    
    private var isSensitiveContentAnalysisEnabled: Binding<Bool> {
        Binding<Bool>(
            get: { featureFlags.isEnabled(.sensitiveContentAnalysisEnabled) },
            set: {
                featureFlags.setFeature(.sensitiveContentAnalysisEnabled, enabled: $0)
                userDefaults.set($0, forKey: sensitiveContentAnalysisEnabledKey)
            }
        )
    }
    
    private var shouldFlagAllContentAsSensitive: Binding<Bool> {
        Binding<Bool>(
            get: { featureFlags.isEnabled(.sensitiveContentFlagAllAsSensitive) },
            set: {
                featureFlags.setFeature(.sensitiveContentFlagAllAsSensitive, enabled: $0)
                userDefaults.set($0, forKey: sensitiveContentAnalysisFlagAllKey)
            }
        )
    }
}
