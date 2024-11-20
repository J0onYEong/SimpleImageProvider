//
//  UIImage+Extension.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import UIKit

public extension UIImageView {
    
    var simple: SimpleUIImageView {
        
        SimpleUIImageView(view: self)
    }
}
