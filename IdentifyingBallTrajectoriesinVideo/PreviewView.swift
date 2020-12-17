//
//  PreviewView.swift
//  IdentifyingBallTrajectoriesinVideo
//
//  Created by AM1820 on 2020/12/17.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
        
    }
        
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
        
    }
}
