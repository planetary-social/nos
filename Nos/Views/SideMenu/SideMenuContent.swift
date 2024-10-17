import SwiftUI
import MessageUI
import Dependencies

struct SideMenuContent: View {
    
    @EnvironmentObject private var router: Router
    @Environment(CurrentUser.self) private var currentUser
    @Dependency(\.analytics) private var analytics
    
    @State private var isShowingReportABugMailView = false
    @State private var shareNosPressed = false
    
    @State var result: Result<MFMailComposeResult, Error>?
    
    let closeMenu: @MainActor () -> Void
    
    @MainActor var profileHeader: some View {
        Group {
            if let author = currentUser.author, author.needsMetadata == true {
                ActionBanner(
                    messageText: "completeProfileMessage",
                    buttonText: "completeProfileButton",
                    buttonImage: .editProfile,
                    shouldButtonFillHorizontalSpace: true
                ) {
                    if let author = currentUser.author {
                        router.push(EditProfileDestination(profile: author))
                    }
                }
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .padding(.horizontal, 20)
                .padding(.vertical, 30)
            } else {
                Button {
                    router.sideMenuPath.append(SideMenu.Destination.profile)
                } label: {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .foregroundColor(.accent)
                                .frame(width: 129, height: 129)
                                .overlay {
                                    AvatarView(imageUrl: currentUser.author?.profilePhotoURL, size: 120)
                                }
                            Spacer()
                        }
                        if let name = currentUser.author?.safeName {
                            Text(name)
                                .foregroundColor(.primaryTxt)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                                .font(.clarityBold(.title2))
                                .padding(.top, 15)
                        }
                    }
                }
                .padding(.vertical, 80)
            }
        }
    }
    
    var body: some View {
        NosNavigationStack(path: $router.sideMenuPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    profileHeader
                    SideMenuRow(
                        "yourProfile",
                        image: Image(systemName: "person.crop.circle"),
                        destination: .profile
                    )
                    SideMenuRow("settings", image: Image(systemName: "gear"), destination: .settings)
                    SideMenuRow(
                        "relays",
                        image: Image(systemName: "antenna.radiowaves.left.and.right"),
                        destination: .relays
                    )
                    SideMenuRow(
                        "about",
                        image: Image(systemName: "questionmark.circle"),
                        destination: .about
                    )
                    SideMenuRow("contactUs", image: Image(systemName: "envelope.circle")) {
                        isShowingReportABugMailView = true
                    }
                    .disabled(!MFMailComposeViewController.canSendMail())
                    .sheet(isPresented: $isShowingReportABugMailView) {
                        ReportABugMailView(result: self.$result)
                            .onAppear {
                                analytics.showedSupport()
                            }
                    }
                    SideMenuRow("shareNos", image: Image(systemName: "person.2.circle")) {
                        shareNosPressed = true
                    }
                    .sheet(isPresented: $shareNosPressed) {
                        let url = URL(string: "https://nos.social")!
                        ActivityViewController(activityItems: [url])
                    }
                    Spacer()
                }
            }
            .background(Color.appBg)
            .navigationDestination(for: SideMenu.Destination.self) { destination in
                switch destination {
                case .settings:
                    SettingsView()
                case .relays:
                    RelayView(author: currentUser.author!)
                case .profile:
                    ProfileView(author: currentUser.author!)
                case .about:
                    AboutView()
                }
            }
            .navigationDestination(for: EditProfileDestination.self) { destination in
                ProfileEditView(author: destination.profile)
            }
        }
    }
}

struct SideMenuRow: View {
    
    let title: LocalizedStringKey
    let image: Image
    var destination: SideMenu.Destination?
    var action: (() -> Void)?
    
    @EnvironmentObject private var router: Router
    
    init(
        _ title: LocalizedStringKey,
        image: Image,
        destination: SideMenu.Destination? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.image = image
        self.destination = destination
        self.action = action
    }
    
    var body: some View {
        Button {
            if let destination {
                router.sideMenuPath.append(destination)
            }
            action?()
        } label: {
            HStack(alignment: .center) {
                image
                Text(title)
                    .foregroundColor(.primaryTxt)
                Spacer()
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .font(.clarityBold(.title3))
        }
        .padding()
    }
}

struct SideMenuContent_Previews: PreviewProvider {
    
    static var previewData = PreviewData()
    static var emptyUserData = { 
        var data = PreviewData()
        _ = data.currentUser
        Task {
            await data.currentUser.setKeyPair(KeyFixture.emptyProfile)
        }
        return data
    }()
    static var menuOpened = true
    
    static var previews: some View {
        Group {
            SideMenuContent { 
                menuOpened = false
            }
            .inject(previewData: previewData)
            
            SideMenuContent { 
                menuOpened = false
            }
            .inject(previewData: emptyUserData)
        }
    }
}
