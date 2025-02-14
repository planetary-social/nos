import SwiftUI
import Logger

/// A view that puts a note behind a content warning if appropriate.
struct WarningView: View {
    
    @Bindable var controller: NoteWarningController
    
    var body: some View {
        if !controller.showWarning {
            EmptyView()
        } else if !controller.noteReports.isEmpty || !controller.authorReports.isEmpty {
            OverlayContentReportView(controller: controller)
        } else if controller.outOfNetwork {
            OutOfNetworkView(controller: controller)
        }
    }
}

struct OutOfNetworkView: View {
    
    @Bindable var controller: NoteWarningController
    
    @State private var isTextBoxShown = false
    @State private var isOverlayHelpTextBoxShown = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Button(action: {
                    self.isOverlayHelpTextBoxShown.toggle()
                }, label: {
                    (isTextBoxShown ? Image.x : Image.info)
                        .resizable()
                        .frame(width: 24, height: 24)
                })
                .padding(.trailing, 24)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 24)
            
            // Center align the content
            VStack(alignment: .center) {
                Spacer() // pushes content to the center
                
                if self.isOverlayHelpTextBoxShown {
                    Text("outsideNetworkExplanation")
                        .font(.body)
                        .foregroundColor(.primaryTxt)
                        .padding(.horizontal, 24)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("outsideNetwork")
                        .font(.body)
                        .foregroundColor(.primaryTxt)
                        .padding(.horizontal, 24)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                SecondaryActionButton("viewThisPostAnyway") {
                    withAnimation {
                        controller.userHidWarning = true
                    }
                }
                .padding(.top, 10) // Move the button closer to the text
                
                Spacer() // pushes content to the center
            }
            .frame(maxWidth: .infinity) // Allow the VStack to take full width
            Spacer(minLength: 30) // Ensure there's some spacing at the bottom
        }
    }
}

struct OverlayContentReportView: View {
    
    @Bindable var controller: NoteWarningController
    
    @State private var isTextBoxShown = false
    @State private var isOverlayHelpTextBoxShown = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        self.isOverlayHelpTextBoxShown.toggle()
                    }
                }, label: {
                    (isTextBoxShown ? Image.x : Image.info)
                        .resizable()
                        .frame(width: 24, height: 24)
                })
                .padding(.trailing, 24)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 24)
            
            // Center align the content
            VStack(alignment: .center) {
                Spacer() // pushes content to the center
                
                // TextBox or Image based on isTextBoxShown
                if self.isOverlayHelpTextBoxShown {
                    Text("contentWarningExplanation")
                        .font(.body)
                        .foregroundColor(.secondaryTxt)
                        .padding(.horizontal, 24)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                } else {
                    
                    Image.warningEye
                        .scaledToFit()
                        .frame(width: 48, height: 48) // Set the width and height to 48
                        .padding(.bottom, 20)
                    
                    if controller.noteReports.count > 0 {
                        ContentWarningMessage(reports: controller.noteReports, type: .note)
                    } else if controller.authorReports.count > 0 {
                        ContentWarningMessage(reports: controller.authorReports, type: .author)
                    }
                }
                SecondaryActionButton("viewThisPostAnyway") {
                    withAnimation {
                        controller.userHidWarning = true
                    }
                }
                .padding(.top, 10) // Move the button closer to the text
                
                Spacer() // pushes content to the center
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Spacer(minLength: 30) // Ensure there's some spacing at the bottom
            
        }
    }
}

struct ContentWarningMessage: View {
    
    let reports: [Event]
    let type: ContentWarningType
    
    @State private var controller = ContentWarningController()
    
    var body: some View {
        Text(controller.localizedContentWarning)
            .font(.body)
            .foregroundColor(.primaryTxt)
            .padding(.horizontal, 25)
            .task {
                // pass values to the controller
                // I don't like this pattern
                controller.reports = reports
                controller.type = type
                Log.info("Displaying content warning based on reports:")
                for report in reports {
                    Log.info("Report with ID: \(String(describing: report.identifier))")
                }
            }
    }
}

#Preview {
    var previewData = PreviewData()
    
    return VStack {
        ContentWarningMessage(reports: [previewData.shortNoteReportOne], type: .author)
        ContentWarningMessage(reports: [previewData.shortNoteReportOne, previewData.shortNoteReportTwo], type: .author)
        ContentWarningMessage(
            reports: [
                previewData.shortNoteReportOne,
                previewData.shortNoteReportTwo,
                previewData.shortNoteReportThree
            ],
            type: .author
        )
        ContentWarningMessage(reports: [previewData.shortNoteReportOne], type: .note)
        ContentWarningMessage(reports: [previewData.shortNoteReportOne, previewData.shortNoteReportTwo], type: .note)
        ContentWarningMessage(
            reports: [
                previewData.shortNoteReportOne,
                previewData.shortNoteReportTwo,
                previewData.shortNoteReportThree
            ],
            type: .note
        )
    }
    .inject(previewData: previewData)
}
