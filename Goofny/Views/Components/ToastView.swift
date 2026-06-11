import SwiftUI

/// Toast that slides up from the bottom and auto-dismisses.
/// Usage: `.toast(message: $viewModel.errorMessage)`
struct ToastModifier: ViewModifier {
    @Binding var message: String?
    var style: ToastStyle = .error
    var duration: TimeInterval = 3

    @State private var dismissTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    HStack(spacing: 10) {
                        Image(systemName: style.icon)
                        Text(message)
                            .multilineTextAlignment(.leading)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 13)
                    .background(style.color.gradient, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onTapGesture { dismiss() }
                    .onAppear { scheduleDismiss() }
                    .id(message) // restart timer if a new message replaces the current one
                }
            }
            .animation(.spring(duration: 0.4), value: message)
    }

    private func scheduleDismiss() {
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    private func dismiss() {
        dismissTask?.cancel()
        withAnimation(.spring(duration: 0.4)) { message = nil }
    }
}

enum ToastStyle {
    case error, success, info

    var color: Color {
        switch self {
        case .error: .red
        case .success: .green
        case .info: .blue
        }
    }

    var icon: String {
        switch self {
        case .error: "exclamationmark.triangle.fill"
        case .success: "checkmark.circle.fill"
        case .info: "info.circle.fill"
        }
    }
}

extension View {
    func toast(message: Binding<String?>, style: ToastStyle = .error, duration: TimeInterval = 3) -> some View {
        modifier(ToastModifier(message: message, style: style, duration: duration))
    }
}
