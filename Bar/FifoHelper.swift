//
//  FifoHelper.swift
//  Bar
//
//  Created by Pavlo Denysiuk on 7/9/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Foundation

class FifoHelper {
    static func isFifo(path: String) -> Bool {
        let cs = (path as NSString).UTF8String
        var statPtr = stat()
        let res = stat(cs, &statPtr)
        if res != 0 {
            NSLog("stat() returned \(res), errno: \(errno)")
            return false
        }
        
        return (statPtr.st_mode & S_IFMT) == S_IFIFO
    }
    
    static func createFifo(path: String) -> Bool {
        let cs = (path as NSString).UTF8String
        let res = mkfifo(cs, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)
        if res != 0 {
            NSLog("mkfifo returned \(res), errno: \(errno)")
            return false
        }
        
        return true
    }
}
