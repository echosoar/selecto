//
//  SettingsWindowController.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import Cocoa
import SwiftUI

/// 设置窗口控制器
/// Settings window controller
class SettingsWindowController: NSWindowController {
    
    convenience init() {
        // 创建设置视图
        // Create settings view
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        // 创建窗口
        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Selecto 设置 (Settings)"
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("SettingsWindow")
        
        self.init(window: window)
    }
}
