import SwiftUI
import AppKit

struct RootView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var model: AppModel
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            VStack(spacing: 12) {
                PreviewCard(settings: settings)
                mainCard
                optionsCard
            }
            .padding(.horizontal, Theme.hPadding)
            footer
        }
        .frame(width: Theme.windowWidth)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.09), lineWidth: 0.8)
        )
    }

    private var background: some View {
        ZStack {
            VisualEffectBackground(material: .popover)
            Color(nsColor: .windowBackgroundColor).opacity(0.42)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                .resizable()
                .interpolation(.high)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(AppInfo.name)
                    .font(.system(size: 13, weight: .semibold))
                HStack(spacing: 5) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 5, height: 5)
                    Text(statusText)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.primary.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
            .help("关闭")
        }
        .padding(.horizontal, 18)
        .padding(.top, 15)
        .padding(.bottom, 13)
    }

    private var mainCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("干掉刘海")
                    .font(.system(size: 13, weight: .medium))
                Text(mainSubtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: $settings.enabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(model.status.level == .noNotch)
        }
        .padding(.horizontal, 14)
        .frame(height: 58)
        .background(card)
    }

    private var optionsCard: some View {
        VStack(spacing: 0) {
            optionRow("模拟屏幕圆角", dimmed: !settings.enabled) {
                Toggle("", isOn: $settings.cornerEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .disabled(!settings.enabled)
            }
            if settings.cornerEnabled {
                divider
                optionRow("圆角半径", dimmed: !settings.enabled) {
                    HStack(spacing: 8) {
                        Slider(value: $settings.cornerRadius, in: 8...48)
                            .frame(width: 110)
                            .controlSize(.small)
                            .disabled(!settings.enabled)
                        Text("\(Int(settings.cornerRadius))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 20, alignment: .trailing)
                    }
                }
            }
            divider
            optionRow("显示在状态栏") {
                Toggle("", isOn: settings.statusBarToggleBinding)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            divider
            optionRow("显示在程序坞") {
                Toggle("", isOn: settings.dockToggleBinding)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            divider
            optionRow("全屏时自动隐藏") {
                Toggle("", isOn: $settings.hideInFullScreen)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            divider
            optionRow("登录时自动启动") {
                Toggle("", isOn: Binding(
                    get: { model.launchAtLogin },
                    set: { model.setLaunchAtLogin($0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
            }
        }
        .background(card)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Text("v\(AppInfo.version) · 为带刘海的 MacBook 设计")
                .font(.system(size: 10.5))
                .foregroundStyle(.tertiary)
            Spacer()
            Button("退出") { NSApp.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    private func optionRow<Content: View>(_ title: String, dimmed: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12.5))
            Spacer(minLength: 8)
            content()
        }
        .opacity(dimmed ? 0.45 : 1)
        .padding(.horizontal, 14)
        .frame(height: Theme.rowHeight)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.07))
            .frame(height: 0.7)
            .padding(.horizontal, 14)
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
            .fill(Color.primary.opacity(0.045))
    }

    private var statusText: String {
        guard settings.enabled else { return "已停用" }
        switch model.status.level {
        case .active:
            return model.status.displays > 1 ? "已生效 · \(model.status.displays) 台显示器" : "已生效"
        case .disabled:
            return "已停用"
        case .noNotch:
            return "当前显示器没有刘海"
        case .paused:
            return "菜单栏不可见，已暂停"
        }
    }

    private var statusColor: Color {
        guard settings.enabled else { return .secondary }
        switch model.status.level {
        case .active: return Color(red: 0.20, green: 0.72, blue: 0.42)
        case .disabled: return .secondary
        case .noNotch: return Color(red: 0.85, green: 0.60, blue: 0.15)
        case .paused: return Color(red: 0.85, green: 0.60, blue: 0.15)
        }
    }

    private var mainSubtitle: String {
        switch model.status.level {
        case .noNotch: return "这台显示器不需要处理"
        case .active: return "顶部整条已被填平"
        case .paused: return "退出全屏后自动恢复"
        case .disabled: return "当前没有生效"
        }
    }
}

struct PreviewCard: View {
    @ObservedObject var settings: AppSettings

    private let barHeight: CGFloat = 26
    private let leftWidths: [CGFloat] = [15, 21, 13]
    private let rightWidths: [CGFloat] = [10, 6, 13]

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.29, green: 0.35, blue: 0.57),
                                              Color(red: 0.53, green: 0.62, blue: 0.80)],
                                     startPoint: .topLeading,
                                     endPoint: .bottomTrailing))

            VStack(spacing: 7) {
                Spacer(minLength: 44)
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.white.opacity(0.13))
                    .frame(height: 34)
                    .padding(.horizontal, 26)
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 12)
                    .padding(.horizontal, 60)
                Spacer(minLength: 6)
            }

            Rectangle()
                .fill(Color.black)
                .frame(height: barHeight)

            menuMock
        }
        .frame(height: 112)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .opacity(settings.enabled ? 1 : 0.4)
        .animation(.easeOut(duration: 0.18), value: settings.enabled)
    }

    private var menuMock: some View {
        HStack(spacing: 5) {
            ForEach(Array(leftWidths.enumerated()), id: \.offset) { _, width in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.white.opacity(0.82))
                    .frame(width: width, height: 3)
            }
            Spacer(minLength: 12)
            ForEach(Array(rightWidths.enumerated()), id: \.offset) { _, width in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.white.opacity(0.82))
                    .frame(width: width, height: 3)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: barHeight)
    }
}
