//
//  SideMenuContent.swift
//  Nos
//
//  Created by Jason Cheatham on 2/21/23.
//

import SwiftUI
import MessageUI
import Dependencies

struct SideMenuContent: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var router: Router
    @EnvironmentObject private var currentUser: CurrentUser
    @Dependency(\.analytics) private var analytics
    
    @State private var isShowingReportABugMailView = false
    @State private var shareNosPressed = false
    
    @State var result: Result<MFMailComposeResult, Error>?
    
    let closeMenu: () -> Void
    
    var body: some View {
        NavigationStack(path: $router.sideMenuPath) {
            VStack(alignment: .leading, spacing: 0) {
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
                            PlainText(name)
                                .foregroundColor(.primaryTxt)
                                .font(.clarityTitle2)
                                .padding(.top, 15)
                        }
                    }
                }
                .padding(.vertical, 80)
                SideMenuRow(title: .yourProfile, image: Image(systemName: "person.crop.circle"), destination: .profile)
                SideMenuRow(title: .settings, image: Image(systemName: "gear"), destination: .settings)
                SideMenuRow(
                    title: .relays,
                    image: Image(systemName: "antenna.radiowaves.left.and.right"),
                    destination: .relays
                )
                SideMenuRow(title: .about, image: Image(systemName: "questionmark.circle"), destination: .about)
                SideMenuRow(title: .contactUs, image: Image(systemName: "envelope.circle")) {
                    isShowingReportABugMailView = true
                }
                .disabled(!MFMailComposeViewController.canSendMail())
                .sheet(isPresented: $isShowingReportABugMailView) {
                    ReportABugMailView(result: self.$result)
                        .onAppear {
                            analytics.showedSupport()
                        }
                }
                SideMenuRow(title: .shareNos, image: Image(systemName: "person.2.circle")) {
                    shareNosPressed = true
                }
                .sheet(isPresented: $shareNosPressed) {
                    let url = URL(string: "https://nos.social")!
                    ActivityViewController(activityItems: [url])
                }
                Spacer()
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
            .navigationDestination(for: Author.self) { profile in
                if profile == CurrentUser.shared.author, CurrentUser.shared.editing {
                    ProfileEditView(author: profile)
                } else {
                    ProfileView(author: profile)
                }
            }
        }
    }
}

struct SideMenuRow: View {
    
    var title: Localized
    var image: Image
    var destination: SideMenu.Destination?
    var action: (() -> Void)?
    
    @EnvironmentObject private var router: Router
    
    var body: some View {
        Button {
            if let destination {
                router.sideMenuPath.append(destination)
            }
            if let action {
                action()
            }
        } label: {
            HStack(alignment: .center) {
                image
                    .font(.clarityTitle3)
                PlainText(title.string)
                    .font(.clarityTitle3)
                    .foregroundColor(.primaryTxt)
                Spacer()
            }
        }
        .padding()
    }
}
