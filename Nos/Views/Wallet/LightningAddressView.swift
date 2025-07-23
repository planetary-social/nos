// ABOUTME: View for configuring Lightning address and gateway settings
// ABOUTME: Allows users to receive Lightning zaps as ecash tokens

import SwiftUI
import Dependencies

struct LightningAddressView: View {
    @Dependency(\.crashReporting) private var crashReporting
    @Dependency(\.currentUser) private var currentUser
    
    @State private var lightningAddress: String = ""
    @State private var selectedGateway: String = ""
    @State private var showingGatewayPicker = false
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let wallet: CashuWallet
    let walletService: CashuWalletService
    
    private var availableGateways: [MintInfo] {
        DefaultMints.recommended.filter { $0.lightningGateway != nil }
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lightning Address")
                        .font(.headline)
                    
                    TextField("you@getalby.com", text: $lightningAddress)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    Text("Your Lightning address for receiving zaps as ecash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lightning Gateway")
                        .font(.headline)
                    
                    Button {
                        showingGatewayPicker = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(selectedGateway.isEmpty ? "Select Gateway" : gatewayName(for: selectedGateway))
                                    .foregroundColor(selectedGateway.isEmpty ? .secondary : .primary)
                                
                                if !selectedGateway.isEmpty {
                                    Text(selectedGateway)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Text("Gateway that converts Lightning payments to ecash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section {
                Button {
                    saveLightningSettings()
                } label: {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Saving...")
                        }
                    } else {
                        Text("Save Settings")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(isLoading || lightningAddress.isEmpty || selectedGateway.isEmpty)
            }
        }
        .navigationTitle("Lightning Integration")
        .sheet(isPresented: $showingGatewayPicker) {
            NavigationView {
                List(availableGateways, id: \.url) { gateway in
                    Button {
                        selectedGateway = gateway.lightningGateway ?? gateway.url
                        showingGatewayPicker = false
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(gateway.name)
                                .font(.headline)
                            
                            Text(gateway.url)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let lightningGateway = gateway.lightningGateway {
                                Label("Lightning Gateway", systemImage: "bolt.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("Select Gateway")
                .navigationBarItems(trailing: Button("Cancel") {
                    showingGatewayPicker = false
                })
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private func gatewayName(for url: String) -> String {
        availableGateways.first { $0.lightningGateway == url || $0.url == url }?.name ?? "Unknown Gateway"
    }
    
    private func loadCurrentSettings() {
        lightningAddress = wallet.lightningAddress ?? ""
        selectedGateway = wallet.lightningGateway ?? ""
    }
    
    private func saveLightningSettings() {
        guard !lightningAddress.isEmpty, !selectedGateway.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                // Update wallet properties
                wallet.lightningAddress = lightningAddress
                wallet.lightningGateway = selectedGateway
                
                // Save wallet event
                guard let author = currentUser.author else {
                    throw WalletError.noAuthor
                }
                
                let walletEvent = try wallet.createWalletEvent(author: author)
                
                // Publish the event
                // Note: In real implementation, this would use RelayService
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
                crashReporting.report(error)
            }
        }
    }
}

enum WalletError: LocalizedError {
    case noAuthor
    
    var errorDescription: String? {
        switch self {
        case .noAuthor:
            return "No author found. Please ensure you're logged in."
        }
    }
}