//
//  AppDelegate.swift
//  Bar
//
//  Created by Pavlo Denysiuk on 4/20/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, StatusTextReceiver {
    @IBOutlet weak var menu: NSMenu!
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    var statusItemButton: NSButton?
    
    let textProvider = StatusTextProvider(pathToFolder: NSBundle.mainBundle().resourcePath!)
    var menuHandler: MenuHandler!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        statusItemButton = statusItem.button
        guard statusItemButton != nil else {
            NSLog("Can't get menuButton")
            return
        }
        
        //statusItemButton?.title = "Hello"
        statusItem.menu = menu
        
        menuHandler = MenuHandler(pathToFolder: NSBundle.mainBundle().resourcePath!, menu: menu)
        
        textProvider.setTextReceiver(self)
        textProvider.start()
    }
    
    @IBAction func onQuit(sender: NSMenuItem) {
        menuHandler.walkDir()
        menuHandler.dump()
        //NSApplication.sharedApplication().terminate(self)
    }
    
    // StatusTextReceiver impl.
    func textDidUpdate(text: String) {
        let trimmed = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        let lines = trimmed.componentsSeparatedByString("\n")
        for line in lines {
            if let command = CommandFactory.createFromLine(line) {
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.handleCommand(command)
                }
            } else {
                NSLog("Can't parse input: '\(line)'")
            }
        }
    }
    
    private func handleCommand(command: Command) {
        switch command.type() {
        case .Notify:
            guard let cmd = command as? NotifyCommand else {
                NSLog("Invalid command: \(command)")
                return
            }
            
            NotifyHandler.notify(cmd)
        case .Ask:            
            guard let cmd = command as? AskCommand else {
                NSLog("Invalid command: \(command)")
                return
            }
            
            AskHandler.ask(cmd)
        case .Text:
            statusItemButton?.title = command.text
        }
    }
}

