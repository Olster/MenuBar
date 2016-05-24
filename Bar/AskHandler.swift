//
//  AskHandler.swift
//  Bar
//
//  Created by Pavlo Denysiuk on 4/28/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Foundation
import Cocoa

class AskHandler: NSObject {    
    static func ask(cmd: AskCommand) -> NSModalResponse {
        let alert = NSAlert()
        alert.addButtonWithTitle("OK")
        alert.addButtonWithTitle("Cancel")
        alert.messageText = cmd.title
        alert.informativeText = cmd.informativeText ?? ""
        alert.alertStyle = .InformationalAlertStyle
        
        let rect = NSMakeRect(0, 0, 250, 25)
        let input = cmd.protected ? NSSecureTextField(frame: rect) : NSTextField(frame: rect)
        
        alert.accessoryView = input
        
        return alert.runModal()
    }
}
