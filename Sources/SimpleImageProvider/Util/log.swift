//
//  log.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

func log(_ items: Any...) {
    
    if Config.presentLog {
        print(items)
    }
}
