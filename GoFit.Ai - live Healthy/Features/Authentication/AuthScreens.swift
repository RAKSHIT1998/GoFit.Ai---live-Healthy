import SwiftUI

// MARK: - Login Screen
struct LoginView: View {

    @EnvironmentObject var auth: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                Text("Welcome back")
                    .font(.largeTitle)
                    .bold()

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                if let error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                Button(action: login) {
                    if loading {
                        ProgressView()
                    } else {
                        Text("Login")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(loading)

                NavigationLink("Create account", destination: SignupView())
                    .padding(.top, 8)

                Spacer()
            }
            .padding()
            .navigationTitle("Login")
        }
    }

    // MARK: - Login Action
    private func login() {
        Task {
            loading = true
            error = nil

            do {
                try await auth.login(email: email, password: password)
            } catch let err {
                self.error = err.localizedDescription
            }

            loading = false
        }
    }
}

// MARK: - Signup Screen
struct SignupView: View {

    @EnvironmentObject var auth: AuthViewModel

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 16) {

            Text("Create account")
                .font(.largeTitle)
                .bold()

            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if let error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Button(action: signup) {
                if loading {
                    ProgressView()
                } else {
                    Text("Create account")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(loading)

            Spacer()
        }
        .padding()
        .navigationTitle("Create account")
    }

    // MARK: - Signup Action
    private func signup() {
        Task {
            loading = true
            error = nil

            do {
                try await auth.signup(
                    name: name,
                    email: email,
                    password: password
                )
            } catch let err {
                self.error = err.localizedDescription
            }

            loading = false
        }
    }
}
