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
    
    @State var result: Result<MFMailComposeResult, Error>?
    
    let closeMenu: () -> Void
    
    var body: some View {
        NavigationStack(path: $router.sideMenuPath) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                    AvatarView(imageUrl: currentUser.author?.profilePhotoURL, size: 120)
                    Spacer()
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
                SideMenuRow(title: .contactUs, image: Image(systemName: "envelope")) {
                    isShowingReportABugMailView = true
                }
                .disabled(!MFMailComposeViewController.canSendMail())
                .sheet(isPresented: $isShowingReportABugMailView) {
                    ReportABugMailView(result: self.$result)
                        .onAppear {
                            analytics.showedSupport()
                        }
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
    var destination: SideMenu.Destination? = nil
    var action: (() -> Void)? = nil
    
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
                    .font(.clarityTitle2)
                PlainText(title.string)
                    .font(.clarityTitle2)
                    .foregroundColor(.primaryTxt)
                Spacer()
            }
        }
        .padding()
    }
}
