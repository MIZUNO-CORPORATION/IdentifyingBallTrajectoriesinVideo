//
//  ViewController.swift
//  IdentifyingBallTrajectoriesinVideo
//
//  Created by AM1820 on 2020/12/17.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var previewView: PreviewView!
    private let drawOverlay = CAShapeLayer()
    
    private let captureSession = AVCaptureSession()
    let captureSessionQueue = DispatchQueue(label: "com.example.apple-samplecode.CaptureSessionQueue")
    
    var videoDataOutput = AVCaptureVideoDataOutput()
    let videoDataOutputQueue = DispatchQueue(label: "com.example.apple-samplecode.VideoDataOutputQueue")
    
    var request: VNDetectTrajectoriesRequest!
//    private lazy var request: VNDetectTrajectoriesRequest = {
//        return VNDetectTrajectoriesRequest(frameAnalysisSpacing: .zero,
//                                           trajectoryLength: 10,
//                                           completionHandler: completionHandler)
//    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        request = VNDetectTrajectoriesRequest(frameAnalysisSpacing: .zero, trajectoryLength: 10, completionHandler: completionHandler)
        
        previewView.videoPreviewLayer.session = captureSession
        previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        captureSessionQueue.async {
            self.setupCamera()
            
//            DispatchQueue.main.async {
//                // Figure out initial ROI.
//            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        captureSession.stopRunning()
        super.viewWillDisappear(animated)
    }

    // MARK: - Camera setup
    func setupCamera() {
        print("setupCamera")
        captureSession.beginConfiguration()
        
        //Configure video device input.
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                  for: .video, position: .unspecified)
        if let supportsSessionPreset = videoDevice?.supportsSessionPreset(.hd1920x1080), supportsSessionPreset == true {
            captureSession.sessionPreset = .hd1920x1080
        } else {
            captureSession.sessionPreset = .high
        }
        
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!), captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
        
        // Configure video data output.
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Could not add VDO output")
            return
        }
        let captureConnection = videoDataOutput.connection(with: .video)
        captureConnection?.preferredVideoStabilizationMode = .standard
        captureConnection?.isEnabled = true
        
        captureSession.commitConfiguration()
        
        captureSession.startRunning()
        print("Starting")
    }

// MARK: - Vision handler
    func completionHandler(request: VNRequest, error: Error?) {
        
        var redTrajectries = [[CGPoint]]()
        var greenTrajectries = [[CGPoint]]()
        
        guard let observations = request.results as? [VNTrajectoryObservation] else { return }
        
        for observation in observations {
            
            let detectedPoints: [CGPoint] = observation.detectedPoints.compactMap {point  in
                return CGPoint(x: point.x, y: 1 - point.y)
            }
            redTrajectries.append(detectedPoints)
            
            let projectedPoints: [CGPoint] = observation.projectedPoints.compactMap { point in
                return CGPoint(x: point.x, y: 1 - point.y)
            }
            greenTrajectries.append(projectedPoints)
        }
        
        show(trajectoryGroups: [(color: UIColor.red.cgColor, trajectories: redTrajectries), (color: UIColor.green.cgColor, trajectories: greenTrajectries)])
        
    }
    
    // MARK: - Trajectory drawing
    
    // Draw a Trajectory on screen. Must be called from main queue.
    var trajectoryLayer = [CAShapeLayer]()
    
    // Remove all drawn trajectories. Must be called on main queue.
    func removeTrajectories() {
        for layer in trajectoryLayer {
            layer.removeFromSuperlayer()
        }
        trajectoryLayer.removeAll()
    }
    
    typealias ColoredTrajectoryGroup = (color: CGColor, trajectories: [[CGPoint]])
    
    // Draws groups of colored trajectories.
    func show(trajectoryGroups: [ColoredTrajectoryGroup]) {
        DispatchQueue.main.async {
            self.removeTrajectories()
            let videoPreviewLayer = self.previewView.videoPreviewLayer
            for trajectoryGroup in trajectoryGroups {
                let color = trajectoryGroup.color
                let path = UIBezierPath()
                path.move(to: CGPoint())
                for trajectories in trajectoryGroup.trajectories {
                    var isStart: Bool = true
                    for trajectory in trajectories {
                        
                        let convertedTrajectory = videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: trajectory)
                        if isStart {
                            path.move(to: convertedTrajectory)
                            isStart = false
                        }
                        path.addLine(to: convertedTrajectory)
                    }
                }
                path.move(to: CGPoint())
                path.close()
                
                let shapeLayer = CAShapeLayer()
                shapeLayer.path = path.cgPath
                shapeLayer.strokeColor = color
                shapeLayer.lineWidth = 3.0
                shapeLayer.fillColor = UIColor.clear.cgColor
                shapeLayer.lineCap = .round
                shapeLayer.opacity = 0.5
                
                self.trajectoryLayer.append(shapeLayer)
                self.previewView.videoPreviewLayer.insertSublayer(shapeLayer, at: 1)
                
            }
        }
    }
}


// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // Set the normalized (0.0 to 1.0) minimum and maximum object sizes.
        //request.minimumObjectSize = 0.1//smallDiameter / width
        //request.objectMaximumNormalizedRadius = 0.0//largeDiameter / width
        // Set the ROI to the left half of the image.
        //request.regionOfInterest = CGRect(x: 0.3, y: 0, width: 0.7, height: 1.0)
        
        do {
            let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer)
            try requestHandler.perform([request])
        } catch {
            // Handle the error.
        }
    }
}


