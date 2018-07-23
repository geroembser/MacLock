//
//  AppDelegate.swift
//  MacLock
//
//  Created by Gero Embser on 13.07.18.
//  Copyright © 2018 Gero Embser. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    //MARK: - instance variables
    ///The application's default status item
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    ///The lock :-)
    private let lock = Lock()
    
    //MARK: - application lifecycle
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        //setup status items
        setupStatusItem()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your applicationa
    }
    
    
}

//MARK: - status item appearance
extension AppDelegate {
    ///Configures the UI of the status item
    private func setupStatusItem() {
        guard let button = statusItem.button else {
            //nothing to setup
            return
        }
        
        //image setup
        button.image = #imageLiteral(resourceName: "StatusBarItems/Default")
        button.imageScaling = .scaleProportionallyDown //scaling the image
        
        //action (on click)
        button.target = self
        button.action = #selector(statusItemTapped(_:))
        
        
        //THIS IS JUST A WORKAROUND, BECAUSE NOBODY IN THE WORLD KNOWS HOW APPLE'S STATUS BAR IS WORKING – I think it has some bugs...
        if let window = button.window { //should always be the case...
            let layer = CALayer() // create a new layer ...
            layer.backgroundColor = .clear //... with transparent background ...
            window.contentView?.superview?.layer = layer //... make it the window's root-view's layer ...
            window.contentView?.wantsLayer = true //... and say the hierarchy needs layers ...
            
            //... and also register a notification whenever switched to another monitor, re-display the button, because without there are layout issues (in High Sierra at least...)
            NotificationCenter.default.addObserver(forName: NSWindow.didMoveNotification, object: window, queue: .main) { (notification) in
                button.display()
            }
        }
    }
    
    ///A method called when the User taps on the status bar item
    @objc private func statusItemTapped(_ sender: NSStatusBarButton?) {
        //turn button off as long as lock isn't finished (so that double clicks does not result in strange behaviour)
        sender?.isEnabled = false
        
        do {
            try self.lock.lock()
        }
        catch {
            sender?.shake2()
        }
        
        //turn on button again after locked or locked failed.
        sender?.isEnabled = true
        
        
        //discard all events (like mouse clicks that may occur in the time the application was waiting for an answer of AppleScript) -> Important to prevent multiple locks following each other...
        NSApplication.shared.discardEvents(matching: .any, before: nil)
    }
}

