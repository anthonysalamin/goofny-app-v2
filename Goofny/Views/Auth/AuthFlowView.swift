import SwiftUI

struct AuthFlowView: View {
    var body: some View {
        NavigationStack {
            LoginView()
        }
    }
}

// MARK: - Login

struct LoginView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }

                if let error = auth.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }

                Button {
                    Task { await auth.signIn(email: email, password: password) }
                } label: {
                    if auth.isBusy {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || password.isEmpty || auth.isBusy)

                NavigationLink("Forgot password?") { ForgotPasswordView() }
                    .font(.footnote)

                divider

                socialButtons

                NavigationLink {
                    RegisterView()
                } label: {
                    Text("New to Goofny? **Create an account**")
                        .font(.subheadline)
                }
            }
            .padding(24)
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("🐶 🐱")
                .font(.system(size: 56))
            Text("Goofny")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
            Text("Vote for the cutest pets on Earth")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 48)
    }

    private var divider: some View {
        HStack {
            Rectangle().frame(height: 1).foregroundStyle(.quaternary)
            Text("or").font(.caption).foregroundStyle(.secondary)
            Rectangle().frame(height: 1).foregroundStyle(.quaternary)
        }
    }

    private var socialButtons: some View {
        VStack(spacing: 10) {
            Button {
                Task { await auth.signInWithGoogle() }
            } label: {
                Label("Continue with Google", systemImage: "g.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                Task { await auth.signInWithFacebook() }
            } label: {
                Label("Continue with Facebook", systemImage: "f.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Register

struct RegisterView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var passwordsMatch: Bool { password == confirmPassword }
    private var isValid: Bool {
        !displayName.isEmpty && !email.isEmpty && password.count >= 8 && passwordsMatch
    }

    var body: some View {
        Form {
            Section("Your details") {
                TextField("Display name", text: $displayName)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            Section("Password (min. 8 characters)") {
                SecureField("Password", text: $password)
                SecureField("Confirm password", text: $confirmPassword)
                if !confirmPassword.isEmpty && !passwordsMatch {
                    Text("Passwords don't match").font(.footnote).foregroundStyle(.red)
                }
            }
            if let error = auth.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
            }
            if let info = auth.infoMessage {
                Text(info).foregroundStyle(.green).font(.footnote)
            }
            Button {
                Task { await auth.signUp(email: email, password: password, displayName: displayName) }
            } label: {
                if auth.isBusy { ProgressView() } else { Text("Create Account") }
            }
            .disabled(!isValid || auth.isBusy)
        }
        .navigationTitle("Create Account")
    }
}

// MARK: - Forgot Password

struct ForgotPasswordView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var email = ""

    var body: some View {
        Form {
            Section {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } footer: {
                Text("We'll send you a link to reset your password.")
            }
            if let error = auth.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
            }
            if let info = auth.infoMessage {
                Text(info).foregroundStyle(.green).font(.footnote)
            }
            Button("Send Reset Link") {
                Task { await auth.resetPassword(email: email) }
            }
            .disabled(email.isEmpty || auth.isBusy)
        }
        .navigationTitle("Reset Password")
    }
}
