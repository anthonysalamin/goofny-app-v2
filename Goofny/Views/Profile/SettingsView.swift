import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var showSignOutConfirm = false
    @State private var showDeleteAccountConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    LabeledContent("Email", value: auth.profile?.email ?? "—")
                    HStack {
                        TextField("Display name", text: $displayName)
                        Button("Save") {
                            Task { await auth.updateDisplayName(displayName) }
                        }
                        .disabled(displayName.isEmpty || displayName == auth.profile?.displayName)
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: AppConfig.appVersion)
                    Link("Terms of Service", destination: URL(string: "https://goofny.com/terms-of-service")!)
                    Link("Privacy Policy", destination: URL(string: "https://goofny.com/privacy-policy")!)
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        showSignOutConfirm = true
                    }
                }

                Section {
                    Button("Delete Account", role: .destructive) {
                        showDeleteAccountConfirm = true
                    }
                } footer: {
                    Text("Permanently deletes your account, your pets, votes, and all associated data. This cannot be undone.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { displayName = auth.profile?.displayName ?? "" }
            .confirmationDialog("Sign out of Goofny?", isPresented: $showSignOutConfirm) {
                Button("Sign Out", role: .destructive) {
                    Task { await auth.signOut() }
                }
            }
            .alert("Delete your account?", isPresented: $showDeleteAccountConfirm) {
                Button("Delete Everything", role: .destructive) {
                    Task { await auth.deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your account, pets, votes, and photos will be permanently deleted. This cannot be undone.")
            }
            .toast(message: $auth.errorMessage)
        }
    }
}
