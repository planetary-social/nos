import SwiftUI
import Dependencies
import Logger
import SwiftUINavigation

/// The report menu can be added to another element and controlled with the `isPresented` variable. When `isPresented`
/// is set to `true` it will walk the user through a series of menus that allows them to report content in a given
/// category and optionally mute the respective author.
struct ReportMenuModifier: ViewModifier {
    @Binding var isPresented: Bool

    let reportedObject: ReportTarget

    @State private var selectedFlagOption: FlagOption?
    @State private var selectedFlagSendOption: FlagOption?
    @State private var selectedVisibilityOption: FlagOption?
    @State private var showFlagSuccessView = false

    @Environment(\.managedObjectContext) private var viewContext
    @Dependency(\.featureFlags) private var featureFlags

    func body(content: Content) -> some View {
        switch reportedObject {
        case .note:
            content
                .sheet(isPresented: $isPresented) {
                    NavigationStack {
                        ContentFlagView(
                            selectedFlagOptionCategory: $selectedFlagOption,
                            selectedSendOptionCategory: $selectedFlagSendOption,
                            showSuccessView: $showFlagSuccessView,
                            flagTarget: reportedObject,
                            sendAction: {
                                if let selectCategory = selectedFlagOption?.category {
                                    publishReport(selectCategory)
                                    showFlagSuccessView = true
                                }
                            }
                        )
                    }
                }
        case .author:
            content
                .sheet(isPresented: $isPresented) {
                    NavigationStack {
                        UserFlagView(
                            selectedFlagOption: $selectedFlagOption,
                            selectedSendOption: $selectedFlagSendOption,
                            selectedVisibilityOption: $selectedVisibilityOption,
                            showSuccessView: $showFlagSuccessView,
                            flagTarget: reportedObject,
                            sendAction: {
                                let selectCategory = selectedVisibilityOption?.category ?? .visibility(.dontMute)
                                publishReport(selectCategory)
                                Task {
                                    await muteUserIfNeeded()
                                    showFlagSuccessView = true
                                }
                            }
                        )
                    }
                }
        }
    }

    private func mute(author: Author) async {
        do {
            try await author.mute(viewContext: viewContext)
        } catch {
            Log.error(error.localizedDescription)
        }
    }

    /// Determines if the user being flagged should be muted.
    private func muteUserIfNeeded() async {
        if let author = reportedObject.author {
            guard case .visibility(let visibilityCategory) = selectedVisibilityOption?.category else { return }

            if visibilityCategory == .mute {
                guard !author.muted else { return }
                await mute(author: author)
            }
        }
    }

    /// Publishes a report based on the category the user selected.
    private func publishReport(_ selectedCategory: FlagCategory) {
        if case .privacy(let privacyCategory) = selectedFlagSendOption?.category, privacyCategory == .sendToNos {
            sendToNos(selectedCategory)
        } else {
            flagPublicly(selectedCategory)
        }
    }

    private func sendToNos(_ selectedCategory: FlagCategory) {
        if case .report(let reportCategory) = selectedCategory {
            // Call the publisher with the extracted ReportCategory
            ReportPublisher().publishPrivateReport(
                for: reportedObject,
                category: reportCategory,
                context: viewContext
            )
        }
    }

    private func flagPublicly(_ selectedCategory: FlagCategory) {
        if case .report(let reportCategory) = selectedCategory {
            ReportPublisher().publishPublicReport(
                for: reportedObject,
                category: reportCategory,
                context: viewContext
            )
        }
    }
}

extension View {
    /// The report menu can be added to another element and controlled with the `isPresented` variable. When
    /// `isPresented` is set to `true` it will walk the user through a series of menus that allows them to report
    /// content in a given category and optionally mute the respective author.
    func reportMenu(_ show: Binding<Bool>, reportedObject: ReportTarget) -> some View {
        self.modifier(ReportMenuModifier(isPresented: show, reportedObject: reportedObject))
    }
}

struct ReportMenu_Previews: PreviewProvider {
    static var previewData = PreviewData()
    static var previews: some View {
        StatefulPreviewContainer(false) { binding in
            VStack {
                Button("Report this") {
                    binding.wrappedValue.toggle()
                }
                .reportMenu(binding, reportedObject: .note(previewData.imageNote))
            }
        }
    }
}
