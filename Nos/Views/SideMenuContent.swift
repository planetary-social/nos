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
        ZStack {
            Color(UIColor(red: 255 / 255.0, green: 255 / 255.0, blue: 255 / 255.0, alpha: 1))
            
            VStack(alignment: .leading, spacing: 0, content: {
                HStack {
                    Button {
                        do {
                            guard let keyPair = KeyPair.loadFromKeychain() else { return }
                            let author = try Author.findOrCreate(by: keyPair.publicKeyHex, context: viewContext)
                            router.path.append(author)
                            router.navigationTitle = Localized.profile.string
                            closeMenu()
                        } catch {
                            // Replace this implementation with code to handle the error appropriately.
                            let nsError = error as NSError
                            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                        }
                    } label: {
                        HStack(alignment: .center) {
                            Image(systemName: "person.crop.circle")
                            Text("Your Profile")
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                HStack {
                    Button {
                        router.path.append(AppView.Destination.settings)
                        router.navigationTitle = Localized.settings.string
                        closeMenu()
                    } label: {
                        HStack(alignment: .center) {
                            Image(systemName: "gear")
                            Text("Settings")
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
                        }
                    }
                    .disabled(!MFMailComposeViewController.canSendMail())
                    .sheet(isPresented: $isShowingReportABugMailView) {
                        ReportABugMailView(result: self.$result)
                    }
                    
                    Spacer()
                }
                .padding()
            })
        }
    }
}
