import AppKit
import SwiftUI
import ServiceManagement

final class AppModel: ObservableObject {
    @Published var status = OverlayStatus.disabled
    @Published var launchAtLogin = false

    func refreshLoginState() {
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            nbLog("\(AppInfo.name): 登录项设置失败 \(error.localizedDescription)")
            let alert = NSAlert()
            alert.messageText = enabled ? "无法开启开机启动" : "无法关闭开机启动"
            alert.informativeText = "系统未允许修改登录项：\(error.localizedDescription)\n可以稍后在「系统设置 → 通用 → 登录项与扩展」中手动调整。"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "好")
            alert.runModal()
        }
        refreshLoginState()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = AppSettings.shared
    private let model = AppModel()
    private let overlay = OverlayController()
    private let corners = CornerController()
    private lazy var panel = PanelWindowController(model: model, settings: settings)
    private let quick = StatusPanelController()

    private var statusItem: NSStatusItem?
    private var statusMenu = NSMenu()
    private var timer: Timer?
    private var tick = 0
    private var probe = ResourceProbe()

    private let showNotification = Notification.Name("com.gripet.notchblack.show")

    func applicationDidFinishLaunching(_ notification: Notification) {
        if terminateIfAlreadyRunning() { return }

        NSApp.setActivationPolicy(settings.showInDock ? .regular : .accessory)
        buildMainMenu()
        applyStatusItemVisibility()
        model.refreshLoginState()
        observeSystem()
        refresh()

        settings.didChange = { [weak self] in
            guard let self else { return }
            self.applyDockPolicy()
            self.applyStatusItemVisibility()
            self.refresh()
        }

        if !settings.showInStatusBar && !settings.showInDock {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.panel.show()
            }
        }

        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(handleShowNotification),
            name: showNotification, object: nil)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.refresh()
            self.tick += 1
            if ProcessInfo.processInfo.environment["NB_DEBUG"] != nil, self.tick % 5 == 0 {
                let sample = self.probe.sample()
                nbLog(String(format: "[NB] tick %d cpu %.2f%% rss %.1fMB",
                             self.tick, sample.cpuPercent, sample.residentMB))
            }
        }

        if CommandLine.arguments.contains("--show-window") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.panel.show()
            }
        }

        if CommandLine.arguments.contains("--show-quick") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.quick.toggle()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        overlay.hideAll()
        corners.hideAll()
        DistributedNotificationCenter.default().removeObserver(self)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panel.show()
        return true
    }

    private func terminateIfAlreadyRunning() -> Bool {
        let me = ProcessInfo.processInfo.processIdentifier
        let others = NSRunningApplication
            .runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "com.gripet.notchblack")
            .filter { $0.processIdentifier != me }
        guard !others.isEmpty else { return false }
        DistributedNotificationCenter.default().postNotificationName(
            showNotification, object: nil, userInfo: nil, deliverImmediately: true)
        others.first?.activate()
        NSApp.terminate(nil)
        return true
    }

    private func observeSystem() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(systemChanged),
                           name: NSApplication.didChangeScreenParametersNotification, object: nil)

        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(self, selector: #selector(systemChanged),
                              name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        workspace.addObserver(self, selector: #selector(systemChanged),
                              name: NSWorkspace.didWakeNotification, object: nil)
        workspace.addObserver(self, selector: #selector(systemChanged),
                              name: NSWorkspace.screensDidSleepNotification, object: nil)
        workspace.addObserver(self, selector: #selector(systemChanged),
                              name: NSWorkspace.screensDidWakeNotification, object: nil)
    }

    @objc private func systemChanged() { refresh() }

    @objc private func handleShowNotification() {
        DispatchQueue.main.async { [weak self] in self?.panel.show() }
    }

    private func refresh() {
        let status = overlay.refresh()
        corners.refresh()
        if status != model.status {
            model.status = status
            buildStatusItemMenu()
        }
    }

    private func applyDockPolicy() {
        let target: NSApplication.ActivationPolicy = settings.showInDock ? .regular : .accessory
        if NSApp.activationPolicy() != target {
            NSApp.setActivationPolicy(target)
        }
    }

    private func buildMainMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        let about = NSMenuItem(title: "关于 \(AppInfo.name)",
                               action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                               keyEquivalent: "")
        about.target = NSApp
        appMenu.addItem(about)
        appMenu.addItem(.separator())
        let prefs = NSMenuItem(title: "设置…", action: #selector(openPanel), keyEquivalent: ",")
        prefs.target = self
        appMenu.addItem(prefs)
        appMenu.addItem(.separator())
        let hide = NSMenuItem(title: "隐藏 \(AppInfo.name)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        hide.target = NSApp
        appMenu.addItem(hide)
        appMenu.addItem(.separator())
        let quitItem = NSMenuItem(title: "退出 \(AppInfo.name)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        appMenu.addItem(quitItem)
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        let windowItem = NSMenuItem()
        let windowMenu = NSMenu(title: "窗口")
        let closeItem = NSMenuItem(title: "关闭", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        closeItem.target = nil
        windowMenu.addItem(closeItem)
        windowItem.submenu = windowMenu
        mainMenu.addItem(windowItem)

        NSApp.mainMenu = mainMenu
        NSApp.windowsMenu = windowMenu
    }

    private func applyStatusItemVisibility() {
        if settings.showInStatusBar {
            if statusItem == nil { buildStatusItem() }
        } else if let item = statusItem {
            quick.dismiss()
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    private func buildStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        if let button = item.button {
            button.image = AppGlyph.statusBarIcon()
            button.imagePosition = .imageOnly
            button.toolTip = AppInfo.name
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])

            quick.attach(button: button,
                         model: model,
                         settings: settings,
                         openSettings: { [weak self] in self?.openPanel() },
                         quit: { NSApp.terminate(nil) })
        }
        buildStatusItemMenu()
    }

    private func buildStatusItemMenu() {
        let menu = NSMenu()
        let open = NSMenuItem(title: "打开主界面…", action: #selector(openPanel), keyEquivalent: ",")
        open.target = self
        menu.addItem(open)

        let toggle = NSMenuItem(title: settings.enabled ? "停用" : "启用",
                                action: #selector(toggleEnabled), keyEquivalent: "")
        toggle.target = self
        toggle.isEnabled = model.status.level != .noNotch
        menu.addItem(toggle)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "退出 \(AppInfo.name)", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusMenu = menu
    }

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            if let button = statusItem?.button {
                buildStatusItemMenu()
                statusMenu.popUp(positioning: nil,
                                 at: NSPoint(x: 0, y: button.bounds.height + 4),
                                 in: button)
            }
        } else {
            quick.toggle()
        }
    }

    @objc private func openPanel() {
        quick.dismiss()
        panel.show()
    }

    @objc private func toggleEnabled() {
        settings.enabled.toggle()
    }

    @objc private func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
if CommandLine.arguments.contains("--selftest") {
    SelfTest.run()
    exit(0)
}
if let index = CommandLine.arguments.firstIndex(of: "--render"),
   CommandLine.arguments.count > index + 1 {
    DebugRender.run(directory: CommandLine.arguments[index + 1])
    exit(0)
}
let delegate = AppDelegate()
app.delegate = delegate
app.run()
