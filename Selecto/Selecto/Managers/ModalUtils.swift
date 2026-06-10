//
//  ModalUtils.swift
//
//  通用 Modal 弹窗工具
//

import SwiftUI

struct ModalContext<Data> {
    let data: Data
    let close: () -> Void
    let appState: AppState
}

enum ModalActionType {
    case cancel
    case normal
    case primary
}

struct ModalActionItem: Identifiable {
    let id = UUID()
    let title: String
    let type: ModalActionType
    let onClick: () -> Void
    let isDisabled: Bool

    init(title: String, type: ModalActionType, onClick: @escaping () -> Void, isDisabled: Bool = false) {
        self.title = title
        self.type = type
        self.onClick = onClick
        self.isDisabled = isDisabled
    }
}

@MainActor
final class ModalBottomActionsRegistry: ObservableObject {
    @Published var actions: [ModalActionItem] = []

    func register(_ actions: [ModalActionItem]) {
        self.actions = actions
    }

    func clear() {
        actions = []
    }
}

@MainActor
final class ModalPresenter: ObservableObject {
    // 共享实例
    static var shared: ModalPresenter?

    fileprivate struct ModalPayload {
        let id = UUID()
        let title: String
        let renderContent: (AppState, @escaping () -> Void) -> AnyView
    }

    @Published fileprivate var currentModal: ModalPayload?

    func open<Data, Content: View>(
        title: String,
        data: Data,
        @ViewBuilder content: @escaping (ModalContext<Data>) -> Content
    ) {
        currentModal = ModalPayload(
            title: title,
            renderContent: { appState, close in
                AnyView(content(ModalContext(data: data, close: close, appState: appState)))
            }
        )
    }

    func close() {
        currentModal = nil
    }

    func closeAll() {
        currentModal = nil
    }
}

private struct ModalPresenterKey: EnvironmentKey {
    static let defaultValue: ModalPresenter? = nil
}

extension EnvironmentValues {
    var modalPresenter: ModalPresenter? {
        get { self[ModalPresenterKey.self] }
        set { self[ModalPresenterKey.self] = newValue }
    }
}

private struct ModalBottomActionsKey: EnvironmentKey {
    static let defaultValue: ModalBottomActionsRegistry? = nil
}

extension EnvironmentValues {
    var modalBottomActions: ModalBottomActionsRegistry? {
        get { self[ModalBottomActionsKey.self] }
        set { self[ModalBottomActionsKey.self] = newValue }
    }
}

private struct ModalHostModifier: ViewModifier {
    @ObservedObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var modalPresenter = ModalPresenter()
    @StateObject private var bottomActionsRegistry = ModalBottomActionsRegistry()

    private let maxModalHeight: CGFloat = 500
    private let minScrollableHeight: CGFloat = 200
    private let modalWidth: CGFloat = 620
    private let headerHeight: CGFloat = 56

    private var currentColorScheme: ColorScheme {
        switch appState.theme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return colorScheme
        }
    }

    func body(content: Content) -> some View {
        content
            .environment(\.modalPresenter, modalPresenter)
            .environment(\.modalBottomActions, bottomActionsRegistry)
            .onAppear {
                // 设置共享实例，以便在静态上下文中访问
                ModalPresenter.shared = modalPresenter
            }
            .overlay {
                if let modal = modalPresenter.currentModal {
                    ZStack {
                        Color.black.opacity(0.18)
                            .ignoresSafeArea()

                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                Text(modal.title)
                                    .font(.system(size: 16, weight: .medium))
                                    .lineLimit(1)

                                Spacer()

                                Button(action: {
                                    modalPresenter.close()
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12, weight: .semibold))
                                        .frame(width: 24, height: 24)
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.secondary)
                                .help("关闭")
                            }
                            .padding(.horizontal, 20)
                            .frame(height: headerHeight)
                            .background(currentColorScheme == .dark ? Color.black : Color.white)

                            Divider()

                            ScrollView(.vertical, showsIndicators: true) {
                                modal.renderContent(appState) {
                                    modalPresenter.close()
                                }
                                .environment(\.modalBottomActions, bottomActionsRegistry)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                            .frame(
                                minHeight: minScrollableHeight,
                                maxHeight: maxModalHeight - headerHeight - (bottomActionsRegistry.actions.isEmpty ? 1 : 50)
                            )

                            if !bottomActionsRegistry.actions.isEmpty {
                                Divider()

                                HStack(spacing: 12) {
                                    Spacer()

                                    ForEach(bottomActionsRegistry.actions) { action in
                                        actionButton(action)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .frame(height: 49)
                                .background(currentColorScheme == .dark ? Color.black : Color.white)
                            }
                        }
                        .frame(width: modalWidth)
                        .frame(maxHeight: maxModalHeight)
                        .background(currentColorScheme == .dark ? Color.black : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 8)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: modal.id)
                    .zIndex(9999)
                }
            }
            .onChange(of: modalPresenter.currentModal?.id) { _ in
                bottomActionsRegistry.clear()
            }
    }

    @ViewBuilder
    private func actionButton(_ action: ModalActionItem) -> some View {
        switch action.type {
        case .cancel, .normal:
            Button(action.title) {
                action.onClick()
            }
            .buttonStyle(.bordered)
            .disabled(action.isDisabled)
        case .primary:
            Button(action.title) {
                action.onClick()
            }
            .buttonStyle(.borderedProminent)
            .disabled(action.isDisabled)
        }
    }
}

private struct ModalBottomActionsModifier: ViewModifier {
    @Environment(\.modalBottomActions) private var modalBottomActions
    let actions: [ModalActionItem]

    func body(content: Content) -> some View {
        content
            .onAppear {
                modalBottomActions?.register(actions)
            }
    }
}

extension View {
    func withModal(appState: AppState) -> some View {
        modifier(ModalHostModifier(appState: appState))
    }

    func modalBottomActions(_ actions: [ModalActionItem]) -> some View {
        modifier(ModalBottomActionsModifier(actions: actions))
    }
}