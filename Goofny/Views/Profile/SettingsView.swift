import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var showSignOutConfirm = false

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
                    LabeledContent("Version", value: "2.0.0")
                    Link("Terms of Service", destination: URL(string: "https://goofny.com/terms")!)
                    Link("Privacy Policy", destination: URL(string: "https://goofny.com/privacy")!)
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        showSignOutConfirm = true
                    }
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
        }
    }
}
