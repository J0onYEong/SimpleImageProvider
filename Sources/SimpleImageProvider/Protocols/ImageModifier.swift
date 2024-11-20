//
//  ImageModifier.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import UIKit

protocol ImageModifier {
    
    func downSamplingImage(dataBuffer: Data, size: CGSize) async -> UIImage?
    
    
    func convertDataToUIImage(data: Data) -> UIImage?
}
