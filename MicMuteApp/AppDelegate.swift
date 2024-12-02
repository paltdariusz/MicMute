//
//  AppDelegate.swift
//  MicMuteApp
//
//  Created by Dariusz Palt on 02/12/2024.
//

import Cocoa
import CoreAudio
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem?
    private let statusMenu = NSMenu()
    private let muteUnmuteItem = NSMenuItem(title: "Mute", action: #selector(toggleMicrophoneMute), keyEquivalent: "")
    private let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "")

    /// Called when the application has finished launching.
    /// Sets up the application by removing the Dock icon and requesting microphone access.
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Remove the Dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Request microphone access
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.setupStatusBarItem()
                } else {
                    print("Microphone access denied.")
                    NSApp.terminate(nil)
                }
            }
        }
    }
    
    /// Sets up the status bar item with the appropriate microphone icon and actions.
    func setupStatusBarItem() {
        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Set the microphone icon based on the current mute state
            let isMuted = isMicrophoneMuted()
            let iconName = isMuted ? "mic.slash.fill" : "mic.fill"
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Mic")
            
            button.action = #selector(toggleMute(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp]) // Enable both left and right clicks
        }
        setupStatusBarMenu()
    }
    
    /// Sets up the status bar menu with mute/unmute and quit options.
    private func setupStatusBarMenu() {
        statusMenu.delegate = self
        
        muteUnmuteItem.target = self
        quitItem.target = self
        
        statusMenu.addItem(muteUnmuteItem)
        statusMenu.addItem(NSMenuItem.separator())
        statusMenu.addItem(quitItem)
    }
    
    /// Handles the status bar button click event.
    /// If it's a right-click, shows the menu; otherwise, toggles the microphone mute state.
    @objc func toggleMute(_ sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent {
            if event.type == .rightMouseUp {
                // Show the menu
                statusItem?.popUpMenu(statusMenu)
            } else {
                // Toggle mute
                toggleMicrophoneMute()
            }
        }
    }
    
    /// Toggles the microphone mute state and updates the status bar icon accordingly.
    @objc func toggleMicrophoneMute() {
        let inputDeviceID = getInputDevice()
        if inputDeviceID == kAudioObjectUnknown {
            print("Unable to get any input device")
            return
        }
        
        let (canSet, status) = canSetMute(for: inputDeviceID)
        if status != noErr || !canSet {
            print("Mute property is not settable on the master element, status: \(status)")
            return
        }
        
        let (muteState, getStatus) = getMicrophoneMuteState(for: inputDeviceID)
        if getStatus != noErr {
            print("Unable to get mute state on master element, status: \(getStatus)")
            return
        }
        
        let newMuteState: UInt32 = muteState == 0 ? 1 : 0
        let setStatus = setMicrophoneMuteState(newMuteState, for: inputDeviceID)
        if setStatus == noErr {
            print("Set mute state on master element to \(newMuteState)")
            updateStatusBarIcon(isMuted: newMuteState == 1)
        } else {
            print("Unable to set mute state on master element, status: \(setStatus)")
        }
    }
    
    /// Returns the default input device ID.
    /// - Returns: The `AudioDeviceID` of the default input device, or `kAudioObjectUnknown` if not found.
    func getInputDevice() -> AudioDeviceID {
        var defaultDeviceID = AudioDeviceID(kAudioObjectUnknown)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )
        
        var deviceIDSize = UInt32(MemoryLayout.size(ofValue: defaultDeviceID))
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &deviceIDSize,
            &defaultDeviceID
        )
        
        if status != noErr {
            print("Error getting default input device: \(status)")
            return kAudioObjectUnknown
        }
        
        return defaultDeviceID
    }
    
    /// Checks if the microphone is currently muted.
    /// - Returns: `true` if the microphone is muted; otherwise, `false`.
    func isMicrophoneMuted() -> Bool {
        let inputDeviceID = getInputDevice()
        if inputDeviceID == kAudioObjectUnknown {
            print("Unable to get any input device")
            return false
        }
        
        let (muteState, status) = getMicrophoneMuteState(for: inputDeviceID)
        if status != noErr {
            print("Unable to get mute state on master element, status: \(status)")
            return false
        }
        
        return muteState == 1
    }
    
    /// Updates the status bar icon based on the microphone mute state.
    /// - Parameter isMuted: A `Bool` indicating whether the microphone is muted.
    func updateStatusBarIcon(isMuted: Bool) {
        if let button = statusItem?.button {
            let iconName = isMuted ? "mic.slash.fill" : "mic.fill"
            if let icon = NSImage(systemSymbolName: iconName, accessibilityDescription: "Mic") {
                button.image = icon
            } else {
                print("Failed to load icon: \(iconName)")
            }
        }
    }
    
    /// Quits the application.
    @objc func quit() {
        NSApp.terminate(self)
    }
    
    /// NSMenuDelegate method to update the menu before it's displayed.
    /// Updates the mute/unmute menu item title based on the current microphone mute state.
    func menuNeedsUpdate(_ menu: NSMenu) {
        let muteUnmuteTitle = isMicrophoneMuted() ? "Unmute" : "Mute"
        muteUnmuteItem.title = muteUnmuteTitle
    }
    
    /// Returns the property address for the microphone mute property.
    /// - Returns: An `AudioObjectPropertyAddress` configured for the mute property.
    private func getMutePropertyAddress() -> AudioObjectPropertyAddress {
        return AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMaster
        )
    }
    
    /// Gets the microphone mute state for the specified device.
    /// - Parameter deviceID: The `AudioDeviceID` of the input device.
    /// - Returns: A tuple containing the mute state (`UInt32`, 0 or 1) and the status (`OSStatus`).
    private func getMicrophoneMuteState(for deviceID: AudioDeviceID) -> (muteState: UInt32, status: OSStatus) {
        var mute: UInt32 = 0
        var muteSize = UInt32(MemoryLayout.size(ofValue: mute))
        var muteAddress = getMutePropertyAddress()
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &muteAddress,
            0,
            nil,
            &muteSize,
            &mute
        )
        return (muteState: mute, status: status)
    }
    
    /// Sets the microphone mute state for the specified device.
    /// - Parameters:
    ///   - muteState: The desired mute state (`UInt32`, 0 or 1).
    ///   - deviceID: The `AudioDeviceID` of the input device.
    /// - Returns: The status (`OSStatus`) of the operation.
    private func setMicrophoneMuteState(_ muteState: UInt32, for deviceID: AudioDeviceID) -> OSStatus {
        var mute = muteState
        let muteSize = UInt32(MemoryLayout.size(ofValue: mute))
        var muteAddress = getMutePropertyAddress()
        
        return AudioObjectSetPropertyData(
            deviceID,
            &muteAddress,
            0,
            nil,
            muteSize,
            &mute
        )
    }
    
    /// Checks if the mute property is settable for the specified device.
    /// - Parameter deviceID: The `AudioDeviceID` of the input device.
    /// - Returns: A tuple containing a `Bool` indicating if the mute property is settable, and the status (`OSStatus`).
    private func canSetMute(for deviceID: AudioDeviceID) -> (canSet: Bool, status: OSStatus) {
        var muteAddress = getMutePropertyAddress()
        var canSetMute: DarwinBoolean = false
        let status = AudioObjectIsPropertySettable(deviceID, &muteAddress, &canSetMute)
        return (canSet: canSetMute.boolValue, status: status)
    }
}
