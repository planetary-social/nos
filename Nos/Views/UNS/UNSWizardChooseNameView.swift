import SwiftUI
import Dependencies
import Logger

struct UNSWizardChooseNameView: View {
    
    @Dependency(\.analytics) var analytics
    @Dependency(\.unsAPI) var api
    @Dependency(\.currentUser) var currentUser 
    @ObservedObject var controller: UNSWizardController
    @State var selectedName: UNSNameRecord?
    @State var desiredName: UNSName = ""

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    UNSStepImage { Image.unsChooseName.offset(x: 7, y: 5) }
                        .padding(20)
                        .padding(.top, 50)
                    
                    Text("chooseNameOrRegister")
                        .font(.clarityBold(.title))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primaryTxt)
                        .shadow(radius: 1, y: 1)
                        .padding(20)
                    
                    Spacer()
                    UNSNamePicker(selectedName: $selectedName, desiredName: $desiredName, controller: controller)
                }
                Spacer()
                
                BigActionButton("next") {
                    await submit()
                }
                .padding(.vertical, 31)
            }
            .padding(.horizontal, 38)
            .readabilityPadding()
            .background(Color.appBg)
        }
    }    
    
    @MainActor func submit() async {
        do {
            if let selectedName {
                try await controller.link(existingName: selectedName)
            } else if !desiredName.isEmpty {
                try await controller.register(desiredName: desiredName)
            } 
        } catch {
            Log.optional(error)
            controller.state = .error(error)
        }
    }
}

#Preview {
    @State var controller = UNSWizardController(
        state: .chooseName, 
        names: [
            UNSNameRecord(name: "Fred", id: "1"),
            UNSNameRecord(name: "Sally", id: "2"),
            UNSNameRecord(name: "Hubert Blaine Wolfeschlegelsteinhausenbergerdorff Sr.", id: "3"),
        ]
    )
    
    return UNSWizardChooseNameView(controller: controller)
}
