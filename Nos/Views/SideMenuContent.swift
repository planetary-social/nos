//
//  SideMenuContent.swift
//  Nos
//
//  Created by Jason Cheatham on 2/21/23.
//
import SwiftUI
import MessageUI

struct SideMenuContent: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var router: Router
    
    @State private var isShowingReportABugMailView = false
    
    @State var result: Result<MFMailComposeResult, Error>?
    
    let closeMenu: () -> Void
    
    var body: some View {
        NavigationStack(path: $router.sideMenuPath) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                HStack {
                    Button {
                        do {
                            guard let keyPair = KeyPair.loadFromKeychain() else { return }
                            try Author.findOrCreate(by: keyPair.publicKeyHex, context: viewContext)
                            router.sideMenuPath.append(SideMenu.Destination.profile)
                        } catch {
                            // Replace this implementation with code to handle the error appropriately.
                            let nsError = error as NSError
                            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                        }
                    } label: {
                        HStack(alignment: .center) {
                            Image(systemName: "person.crop.circle")
                            Text("Your Profile")
                                .foregroundColor(.primaryTxt)
                                .bold()
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                HStack {
                    Button {
                        router.sideMenuPath.append(SideMenu.Destination.settings)
                    } label: {
                        HStack(alignment: .center) {
                            Image(systemName: "gear")
                            Text("Settings")
                                .foregroundColor(.primaryTxt)
                                .bold()
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                HStack {
                    Button {
                        router.sideMenuPath.append(SideMenu.Destination.relays)
                    } label: {
                        HStack(alignment: .center) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text(Localized.relays.string)
                                .foregroundColor(.primaryTxt)
                                .bold()
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                HStack {
                    Button {
                    } label: {
                        HStack(alignment: .center) {
                            Image(systemName: "questionmark.circle")
                            Text("Help and Support")
                                .foregroundColor(.primaryTxt)
                                .bold()
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                HStack {
                    Button {
                        isShowingReportABugMailView = true
                    } label: {
                        HStack(alignment: .center) {
                            Image(systemName: "ant.circle.fill")
                            Text("Report a Bug")
                                .foregroundColor(.primaryTxt)
                                .bold()
                        }
                    }
                    .disabled(!MFMailComposeViewController.canSendMail())
                    .sheet(isPresented: $isShowingReportABugMailView) {
                        ReportABugMailView(result: self.$result)
                    }
                    
                    Spacer()
                }
                .padding()
                Spacer(minLength: 0)
            }
            .background(Color.appBg)
            .navigationDestination(for: SideMenu.Destination.self) { destination in
                switch destination {
                case .settings:
                    SettingsView()
                case .relays:
                    RelayView(author: CurrentUser.shared.author!)
                case .profile:
                    ProfileView(author: CurrentUser.shared.author!)
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
