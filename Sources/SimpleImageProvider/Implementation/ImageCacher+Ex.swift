//
//  ImageCacher+Ex.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import UIKit

extension ImageCacher {
    
    func createKey(url: String, size: CGSize?) -> String {
        
        var keyString = url
        
        if let size {
            
            let width = size.width
            let height = size.height
            
            keyString += "\(width)x\(height)"
        }
        
        return keyString
    }
}
