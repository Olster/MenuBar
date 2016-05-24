//
//  NotifyHandler.swift
//  Bar
//
//  Created by Pavlo Denysiuk on 4/27/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Foundation

class NotifyHandler {
    static func notify(data: NotifyCommand) {
        let notification = NSUserNotification()
        notification.title = data.title
        notification.informativeText = data.informativeText
        
        if data.makeSound {
            notification.soundName = NSUserNotificationDefaultSoundName
        }
        
        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
    }
}
