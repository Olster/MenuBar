//
//  AppDelegate.swift
//  Bar
//
//  Created by Pavlo Denysiuk on 4/20/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, CommandProviderDelegate {
    @IBOutlet weak var menu: NSMenu!
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    
    // Reads commands from user.
    var textProvider: CommandProvider!
    
    // Handles menus created ny user.
    var menuHandler: MenuHandler!
    
    var appSupportDir: NSURL!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        statusItem.menu = menu
        guard statusItem.button != nil else {
            NSLog("Can't get menuButton")
            return
        }
        
        guard setUpApplicationSupportDir() else {
            return
        }
        
        textProvider = CommandProvider(pathToFolder: appSupportDir.path!)
        menuHandler = MenuHandler(pathToFolder: appSupportDir.path!, menu: menu)
        
        textProvider.delegate = self
        textProvider.start()
    }
    
    func setUpApplicationSupportDir() -> Bool {
        let bundleID = NSBundle.mainBundle().bundleIdentifier
        let appSupport = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        
        if bundleID != nil && appSupport.count > 0 {
            let dir = appSupport[0].URLByAppendingPathComponent(bundleID!)
            
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(dir, withIntermediateDirectories: true, attributes: nil)
                appSupportDir = dir
                return true
            } catch {
                NSLog("Can't create application support dir: \(dir). Err: \(error)")
            }
        }
        
        NSLog("Can't set up appSupportDir: '\(bundleID)', '\(appSupport)'")
        return false
    }
    
    @IBAction func onQuit(sender: NSMenuItem) {
        menuHandler.walkDir()
        menuHandler.dump()
        //NSApplication.sharedApplication().terminate(self)
    }
    
    // MARK: - CommandProviderDelegate impl.
    func commandReceived(text: String) {
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
            statusItem.button?.title = command.text
        }
    }
}

