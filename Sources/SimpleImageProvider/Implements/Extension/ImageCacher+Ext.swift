//
//  ImageCacher+Ext.swift
//  SimpleImageProvider
//
//  Created by choijunios on 2/7/25.
//

import Foundation

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
