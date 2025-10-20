//
//  ControlPanelWindowController.swift
//  Selecto
//
//  Created by Gao Yang on 2024.
//  Copyright © 2024 Gao Yang. All rights reserved.
//

import Cocoa
import SwiftUI

/// 控制面板窗口控制器
/// Control panel window controller
class ControlPanelWindowController: NSWindowController {
    
    convenience init() {
        let controlPanelView = ContentView()
        let hostingController = NSHostingController(rootView: controlPanelView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Selecto 控制面板"
        window.isReleasedWhenClosed = false
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("ControlPanelWindow")
        window.tabbingMode = .disallowed
        
        self.init(window: window)
    }
}
