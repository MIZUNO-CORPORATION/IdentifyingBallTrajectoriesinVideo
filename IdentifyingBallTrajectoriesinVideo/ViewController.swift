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
    let captureSessionQueue = DispatchQueue(label: "IdentifyingBallTrajectoriesinVideo.CaptureSessionQueue")
    
    var videoDataOutput = AVCaptureVideoDataOutput()
    let videoDataOutputQueue = DispatchQueue(label: "IdentifyingBallTrajectoriesinVideo.VideoDataOutputQueue")
    
    var request: VNDetectTrajectoriesRequest!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        request = VNDetectTrajectoriesRequest(frameAnalysisSpacing: .zero, trajectoryLength: 10, completionHandler: completionHandler)
        
        previewView.videoPreviewLayer.session = captureSession
        previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        panGestureRectLayer.strokeColor = UIColor.blue.cgColor
        panGestureRectLayer.lineWidth = 3.0
        panGestureRectLayer.fillColor = UIColor.clear.cgColor
        panGestureRectLayer.lineCap = .round
        panGestureRectLayer.opacity = 0.2
        
        captureSessionQueue.async {
            self.setupCamera()
            
//            DispatchQueue.main.async {
            // This method does not work??
//                // Figure out initial ROI.
//                //self.request.regionOfInterest = CGRect(x: 0, y: 0, width: 0.2, height: 0.2)
//                print(self.request.regionOfInterest)
//            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        captureSession.stopRunning()
        request = nil
        super.viewWillDisappear(animated)
    }
    
    var panGestureRect: CGRect?
    var panGestureBeganPoint: CGPoint?
    var panGestureEndedPoint: CGPoint?
    var panGestureRectLayer: CAShapeLayer = CAShapeLayer()
    
    @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
        switch sender.state {
        case .ended:
            panGestureRect = nil
            panGestureRectLayer.removeFromSuperlayer()
        default:
            break
        }
        
    }
    
    @IBAction func panGesture(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            print("began")
            let location = sender.location(in: previewView)
            panGestureBeganPoint = CGPoint(x: location.x, y: location.y)
            panGestureRectLayer.removeFromSuperlayer()
        case .ended:
            print("ended")
            let location = sender.location(in: previewView)
            panGestureEndedPoint = CGPoint(x: location.x, y: location.y)
            
            if let p0 = panGestureEndedPoint, let p1 = panGestureBeganPoint {
                panGestureRect = previewView.videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: CGRect(x: p0.x, y: p0.y, width: p1.x-p0.x, height: p1.y-p0.y))
            } else {
                break
            }
            
            if let rect = self.panGestureRect {
                let convertedRect = previewView.videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: rect)
                let panGestureRectPath: UIBezierPath = UIBezierPath(rect: convertedRect)
                panGestureRectLayer.path = panGestureRectPath.cgPath
                self.previewView.videoPreviewLayer.addSublayer(panGestureRectLayer)
            }
            
        case .changed:
            panGestureRectLayer.removeFromSuperlayer()
            
            let location = sender.location(in: previewView)
            panGestureEndedPoint = CGPoint(x: location.x, y: location.y)
            
            if let p0 = panGestureEndedPoint, let p1 = panGestureBeganPoint {
                panGestureRect = previewView.videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: CGRect(x: p0.x, y: p0.y, width: p1.x-p0.x, height: p1.y-p0.y))
            } else {
                break
            }
            
            if let rect = self.panGestureRect {
                let convertedRect = previewView.videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: rect)
                let panGestureRectPath: UIBezierPath = UIBezierPath(rect: convertedRect)
                panGestureRectLayer.path = panGestureRectPath.cgPath
                self.previewView.videoPreviewLayer.addSublayer(panGestureRectLayer)
            }
            
        default:
            break
        }
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
        guard let observations = request.results as? [VNTrajectoryObservation] else { return }
        
        for observation in observations {
            
            let uuid: UUID = observation.uuid
            let detectedPoints: [CGPoint] = observation.detectedPoints.compactMap {point in
                return CGPoint(x: point.x, y: 1 - point.y)
            }
            let projectedPoints: [CGPoint] = observation.projectedPoints.compactMap { point in
                return CGPoint(x: point.x, y: 1 - point.y)
            }
            
            let roi: CGRect = CGRect(x: 0.9, y: 0.25, width: 0.1, height: 0.5)
            if let rect = panGestureRect {
                if !isROI(detectedPoints: detectedPoints, roi: rect) {
                    continue
                }
            }
            
            
            if trajectoriesDict.keys.contains(uuid){
                trajectoriesDict[uuid]!.detectedPoints.append(detectedPoints.last!)
                trajectoriesDict[uuid]!.projectedPoints = projectedPoints
                trajectoriesDict[uuid]!.equationCoefficients = observation.equationCoefficients
                trajectoriesDict[uuid]!.confidence = observation.confidence
                trajectoriesDict[uuid]!.count = 0
            }else {
                trajectoriesDict[uuid] = TrajectoryProperty(detectedPoints: detectedPoints, projectedPoints: projectedPoints, equationCoefficients: observation.equationCoefficients, confidence: observation.confidence)
            }
        }
        drawTrajectories()
    }
    
    // MARK: - Trajectory drawing
    
    // Draw a Trajectory on screen. Must be called from main queue.
    var trajectoryLayer = [CAShapeLayer]()
    var trajectoriesDict: [UUID: TrajectoryProperty] = [:]
    
    // Remove all drawn trajectories. Must be called on main queue.
    func removeTrajectoryLayers() {
        for layer in trajectoryLayer {
            layer.removeFromSuperlayer()
        }
        trajectoryLayer.removeAll()
    }
    
    // Draws trajectories.
    func drawTrajectories() {
        DispatchQueue.main.async {
            self.removeTrajectoryLayers()
            if self.trajectoriesDict.count == 0 {
                return
            }
            
            let videoPreviewLayer = self.previewView.videoPreviewLayer
            let detectedPointPath = UIBezierPath()
            let projectedPointPath = UIBezierPath()
            
            for trajectoryProperty in self.trajectoriesDict {
                detectedPointPath.move(to: videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: trajectoryProperty.value.detectedPoints[0]))
                for point in trajectoryProperty.value.detectedPoints {
                    let convertedPoint = videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: point)
                    detectedPointPath.addLine(to: convertedPoint)
                }
                
                projectedPointPath.move(to: videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: trajectoryProperty.value.projectedPoints[0]))
                for point in trajectoryProperty.value.projectedPoints {
                    let convertedPoint = videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: point)
                    projectedPointPath.addLine(to: convertedPoint)
                }
                detectedPointPath.move(to: CGPoint())
            }
            detectedPointPath.close()
            projectedPointPath.close()
            
            let detectedPointLayer = CAShapeLayer()
            detectedPointLayer.path = detectedPointPath.cgPath
            detectedPointLayer.strokeColor = UIColor.red.cgColor
            detectedPointLayer.lineWidth = 3.0
            detectedPointLayer.fillColor = UIColor.clear.cgColor
            detectedPointLayer.lineCap = .round
            detectedPointLayer.opacity = 0.3
            self.trajectoryLayer.append(detectedPointLayer)
            
            let projectedPointLayer = CAShapeLayer()
            projectedPointLayer.path = projectedPointPath.cgPath
            projectedPointLayer.strokeColor = UIColor.green.cgColor
            projectedPointLayer.lineWidth = 3.0
            projectedPointLayer.fillColor = UIColor.clear.cgColor
            projectedPointLayer.lineCap = .round
            projectedPointLayer.opacity = 0.3
            self.trajectoryLayer.append(projectedPointLayer)
            
            self.previewView.videoPreviewLayer.addSublayer(detectedPointLayer)
            self.previewView.videoPreviewLayer.addSublayer(projectedPointLayer)
        }
    }
}


// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        for key in trajectoriesDict.keys {
            trajectoriesDict[key]!.count += 1
            //If the trajectory with the same key(UUID) is not added after 5 frames, delete it.
            if trajectoriesDict[key]!.count > 5 {
                trajectoriesDict[key] = nil
            }
        }
        
        // These methods do not work??
        // Set the normalized (0.0 to 1.0) minimum and maximum object sizes.
        //request.objectMinimumNormalizedRadius = 0.0
        //request.objectMaximumNormalizedRadius = 0.2
        // Set the ROI to the left half of the image.
        //request.regionOfInterest = CGRect(x: 0.0, y: 0.0, width: 0.5, height: 1.0)
        
        do {
            let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer)
            try requestHandler.perform([request])
        } catch {
            // Handle the error.
        }
    }
}

struct TrajectoryProperty {
    var detectedPoints: [CGPoint]
    var projectedPoints: [CGPoint]
    var equationCoefficients: simd_float3
    var confidence: Float
    var count: Int = 0
}

// MARK: - Apply business logic
extension ViewController {
    func isROI(detectedPoints: [CGPoint], roi: CGRect) -> Bool {
        let l0 = CGPoint(x: detectedPoints[0].x, y: detectedPoints[0].y)
        let l4 = CGPoint(x: detectedPoints[4].x, y: detectedPoints[4].y)
        let p: [CGPoint] = [CGPoint(x: roi.minX, y: roi.minY), CGPoint(x: roi.maxX, y: roi.minY), CGPoint(x: roi.maxX, y: roi.maxY), CGPoint(x: roi.minX, y: roi.maxY)]
        
        for i in 0 ... 3 {
            let determinant: CGFloat = (l4.x - l0.x)*(-p[(i+1)%4].y + p[i].y) - (l4.y - l0.y)*(-p[(i+1)%4].x + p[i].x)
            if determinant == 0 {
                continue
            }
            let s: CGFloat = 1/determinant * ((-p[(i+1)%4].y + p[i].y)*(p[i].x - l0.x) + (p[(i+1)%4].x - p[i].x)*(p[i].y - l0.y))
            let t: CGFloat = 1/determinant * ((-l4.y + l0.y)*(p[i].x - l0.x) + (l4.x - l0.x)*(p[i].y - l0.y))
            if s <= 0 && 0 <= t && t <= 1 {
                return true
            }
        }
        return false
    }
}
