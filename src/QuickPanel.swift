import SwiftUI
import AppKit

struct QuickPanelView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var model: AppModel
    var openSettings: () -> Void
    var quit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 18, height: 18)
                Text(AppInfo.name)
                    .font(.system(size: 12, weight: .semibold))
                Spacer(minLength: 8)
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 5, height: 5)
                    Text(statusShort)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 9)

            Divider()
                .padding(.bottom, 5)

            toggleRow("干掉刘海", isOn: $settings.enabled)
            toggleRow("模拟屏幕圆角", isOn: $settings.cornerEnabled, disabled: !settings.enabled)
            if settings.cornerEnabled {
                radiusRow
            }
            toggleRow("显示在状态栏", isOn: settings.statusBarToggleBinding)
            toggleRow("显示在程序坞", isOn: settings.dockToggleBinding)
            toggleRow("全屏时自动隐藏", isOn: $settings.hideInFullScreen)
            toggleRow("登录时自动启动", isOn: Binding(
                get: { model.launchAtLogin },
                set: { model.setLaunchAtLogin($0) }
            ))

            Divider()
                .padding(.vertical, 6)

            HStack(spacing: 12) {
                Button("设置…") { openSettings() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("退出") { quit() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 2)
        }
        .padding(12)
        .frame(width: 272)
        .background(
            ZStack {
                VisualEffectBackground(material: .popover)
                Color(nsColor: .windowBackgroundColor).opacity(0.32)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.8)
        )
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>, disabled: Bool = false) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12))
            Spacer(minLength: 8)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
                .disabled(disabled)
        }
        .frame(height: 30)
        .opacity(disabled ? 0.45 : 1)
    }

    private var radiusRow: some View {
        HStack(spacing: 8) {
            Text("圆角半径")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
            Slider(value: $settings.cornerRadius, in: 8...48)
                .controlSize(.mini)
                .disabled(!settings.enabled)
            Text("\(Int(settings.cornerRadius))")
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 18, alignment: .trailing)
        }
        .frame(height: 26)
        .opacity(settings.enabled ? 1 : 0.45)
    }

    private var statusShort: String {
        guard settings.enabled else { return "已停用" }
        switch model.status.level {
        case .active: return "生效中"
        case .disabled: return "已停用"
        case .noNotch: return "无刘海"
        case .paused: return "已暂停"
        }
    }

    private var statusColor: Color {
        guard settings.enabled else { return .secondary }
        switch model.status.level {
        case .active: return Color(red: 0.20, green: 0.72, blue: 0.42)
        case .disabled: return .secondary
        case .noNotch, .paused: return Color(red: 0.85, green: 0.60, blue: 0.15)
        }
    }
}
