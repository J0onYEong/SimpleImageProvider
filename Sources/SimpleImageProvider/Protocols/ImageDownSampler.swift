//
//  ImageDownSampler.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import UIKit

protocol ImageDownSampler {
    
    func downSamplingImage(dataBuffer: Data, size: CGSize) async -> UIImage?
}
