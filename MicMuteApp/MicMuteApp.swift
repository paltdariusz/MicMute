//
//  MicMuteApp.swift
//  MicMuteApp
//
//  Created by Dariusz Palt on 02/12/2024.
//

import SwiftUI
import AppKit

@main
struct MicMuteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            // Empty settings to prevent a settings window from appearing
        }
    }
}
