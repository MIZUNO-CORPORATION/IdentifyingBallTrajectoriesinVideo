<<<<<<< HEAD
#  Identifying Ball Trajectories in Video

## Overview
This is an app that detects the trajectory of a ball in real time from a video using the Vision framework. I assume that it capture in ball game sports where the background does not move. The gif below is a demo that detected the trajectory of a golf ball with the app. Starting in iOS 14, tvOS 14, and macOS 11, the framework provides the ability to detect the trajectories of objects in a video sequence. See the [Apple document: Identifying Trajectories in Video](https://developer.apple.com/documentation/vision/identifying_trajectories_in_video) for more details.

![Demo movie](Demo/golf_swing.gif)

## Motivation
A function that detects the trajectory  is now available from iOS 14 as one of the features of the Vision framework for image processing. Therefore, I have implemented this function by referring to the document. The result of detecting the trajectory has been magically wonderful!
I have shared the source code here and [the article on the Qiita in japanese](https://qiita.com/viendfig/items/66946618988e08592f4c) because there was little information on the internet about the function, other than the documentation.
I have just started using the Vision framework, so I would appreciate any advice. 


## Flow of the trajectory detection
The function use "Request", "Request Hander", and "Observation" to detect the trajectory.
1. Request: You configure the `VNDetectTrajectoriesRequest` and its parameters you want to use in the Vision framework. 
1. Request Handler: You pass the capturing movie and the request you configured. Then the detection process is performed.
1. Observation: You can get the result from `VNTrajectoryObservation`.

## Properties of the Observation Result
The following properties can be obtained from the observation.
1. `detectedPoints` (red line in gif)
   - `[VNPoint]`: Array of x, y coordinates in the image frame
   - You can get the x and y coordinates normalized to [0,1.0] of the trajectory for the number of frames that you configure as `trajectoryLength` in the request.
   - Output example: [[0.027778; 0.801562], [0.073618; 0.749221], [0.101400; 0.752338], [0.113900; 0.766406], [0.119444; 0.767187], [0.122233; 0.774219], [0.130556; 0.789063], [0.136111; 0.789063], [0.144444; 0.801562], [0.159733; 0.837897]]
1. `projectedPoints` (green line in gif)
   - `[VNPoint]`: Array of x, y coordinates in the image frame
   - Going back 5 frames in the past, you can get the x, y coordinates normalized to [0,1.0] of the trajectory converted into a quadratic equation for 5 points.
   - Output example: [[0.122233; 0.771996], [0.130556; 0.782801], [0.136111; 0.791214], [0.144444; 0.805637], [0.159733; 0.837722]]
=======
#  【Swift】Visionフレームワークを用いた動画からリアルタイムにボールの軌道を検出するアプリ

## はじめに
撮影している動画に対して、リアルタイムでボールの軌道を検出し、動画に軌道を重ね合わせるアプリを作成しました（下記のgifは作成したアプリでゴルフボールの軌道を検出したデモです） 。  
画像処理を目的とした[Visionフレームワーク（顔検出、文字検出、バーコード検出、...）](https://developer.apple.com/documentation/vision)の中の１つの機能として、軌道検出がiOS14から使用できるようになりました。
そこで、[Appleのドキュメント：Identifying Trajectories in Video](https://developer.apple.com/documentation/vision/identifying_trajectories_in_video)を参考に軌道検出機能を実装しました。  
しかし、Vsionフレームワーク関係、特に軌道検出についての情報が、ドキュメント以外にほとんどネットに無かったので、記事を書きました。  
私自身もVisionフレームワークを使い始めたばかりなので、アドバイスをいただけると幸いです。  
Qiitaの記事は[こちら](https://qiita.com/viendfig/items/66946618988e08592f4c)になります。  
![デモ動画](Demo/golf_swing.gif)


## 利用用途
球技スポーツ（ゴルフ、野球、サッカー等）のボールの軌道検出のため  
iOS14以降でのiPhone/iPadに対応


## 軌道検出の流れ
軌道検出をするには「リクエスト」と「リクエストハンドラ」、「オブザベーション」を使います。
1. リクエストで、Visionフレームワーク中の使用したい機能とパラメタを設定します（今回は、軌道検出機能の `VNDetectTrajectoriesRequest` を使用）
1. リクエストハンドラに、処理したい画像と設定したリクエストを渡すことで検出処理が行われます
1. オブザベーションで、検出結果が取得できます（今回は、軌道検出用途の `VNTrajectoryObservation` で取得）

## 軌道検出で取得できる情報
オブザベーションから下記のような情報が取得できます。
1. `detectedPoints`（gifの赤色の線）
   - 検出された軌道の座標：リクエストで設定したフレーム数過去に遡り、フレーム数分の軌道の[0,1.0]に正規化されたx,y座標が取得される
   - `[VNPoint]`  ：画像におけるx,y座標の配列
   - アウトプット例：[[0.027778; 0.801562], [0.073618; 0.749221], [0.101400; 0.752338], [0.113900; 0.766406], [0.119444; 0.767187], [0.122233; 0.774219], [0.130556; 0.789063], [0.136111; 0.789063], [0.144444; 0.801562], [0.159733; 0.837897]]
1. `projectedPoints`（gifの緑色の線）
   - 予測された軌道の座標：過去の5フレーム分遡り、5点分の2次方程式に変換された軌道の[0,1.0]に正規化されたx,y座標が取得される
   - `[VNPoint]`：画像におけるx,y座標の配列
   - アウトプット例：[[0.122233; 0.771996], [0.130556; 0.782801], [0.136111; 0.791214], [0.144444; 0.805637], [0.159733; 0.837722]]
>>>>>>> c03f8594d07b37e8d6f6ba18ab3e670b7de121fc
1. `equationCoefficients`
   - `simd_float3`: the equation coefficients for the quadratic equation
   - You can get the quadratic equation, f(x) = ax2 + bx + c, converted from projectedPoint
   - Output example: SIMD3<Float>(15.573865, -2.6386108, 0.86183345)
1. `uuid`
    - `UUID`: Universally unique value
    - You can get the ID of the each trajectory. If the trajectory detected in the next frame is included in one in the previous frame, the same ID is given.
    - Output example: E5256430-439E-4B0F-91B0-9DA6D65C22EE
1. `timeRange`
    - `CMTimeRange`: Timestamp of the period from when the trajectory was detected (Trajectory start) to when it continued to be detected (from Detected trajectory).
    - You can get the timestamp when the each trajectory detected.
    - Output example: {{157245729991291/1000000000 = 157245.730}, {699938542/1000000000 = 0.700}}
1. `confidence`
    - `VNConfidence`: Confidence level of accuracy of the detected trajectory
    - You can get the confidence level normalized to [0,1.0] of the trajectory.
    - Output example: 0.989471
    
![Explanation of detecting the trajectory](images/rendered2x-1591650146.png)  
Cited from [Identifying Trajectories in Video | Apple Developer Documentation](https://developer.apple.com/documentation/vision/identifying_trajectories_in_video).


## Implementation
### Development Environment
  - XCode 12.2
  - Swift 5
### Framework
  1. UIKit
  1. Vision
  1. AVFoundation

### Implement a Trajectory Detection
#### Configure a Device Orientation
With my implementation, if I set the device orientation to `Landscape`, the video playback screen will rotate 90 degrees, so it is set to `Portrait`.  
![Explanation of setting the device orientation](images/orientation_setting.png)

#### Display a Camera Preview
Use `AVCaptureVideoPreviewLayer`. This layer is `CALayer`'s subclass that displays the video captured in the input device. This layer is combined with the capture session.
```swift: PreviewView.swift
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
```
#### Connect a Storyboard
Associate the above PreviewView.swift with the Storyboard.
![Explanation of assciating with Storyboard](images/storyboard_setting.png)

#### Framework
```swift: ViewController.swift
import UIKit
import AVFoundation
import Vision
```

#### Create a Request
Declare `VNDetectTrajectoriesRequest` to detect the trajectory, and the arguments are the following three.  
1. `frameAnalysisSpacing: CMTime`
    - Set time interval of analysing the trajectory.
    - Increasing this value will thin out the frames to be analyzed, which will be effective for devices with low spec.  If set to `.zero`, all frames can be analyzed, but the load will be large. 
  
1. `trajectoryLength: Int`
    - Set the number of the point that compose with the trajectory.
    - The minimum number is 5 points. If it is set a little number, it mis detect many trajactories. (I have set 10 points to catch a golf ball just right.)  
  
1. `completionHandler: VNRequestCompletionHandler?`
    - Set the closure called when detection is complete. (I have implemented the original method (completionHandler) and call it.)  
  
```swift: ViewController.swift
var request: VNDetectTrajectoriesRequest = VNDetectTrajectoriesRequest(frameAnalysisSpacing: .zero, trajectoryLength: 10, completionHandler: completionHandler)
```
#### Applying Filtering Criteria
Set the following three properties that are prepared for the request as needed.
1. `objectMaximumNormalizedRadius: Float` (In my implementation, the setting has not been reflected for unknown reasons.)
   - Set a size that’s slightly larger than the object (ball) you want to detect.
   - If setting it, you can filter moving large things.
   - The setting range is [0.0, 1.0], which is the normalized frame size. The default is 1.0.
   - The similar property `maximumObjectSize` has been deprecated.
1. `objectMinimumNormalizedRadius: Float`
<<<<<<< HEAD
    - Set a size that’s slightly smaller than the object (ball) you want to detect.
    - If setting it, you can filter moving small things and noises.
    - The setting range is [0.0, 1.0], which is the normalized frame size. The default is 0.0.
    - The similar property `minimumObjectSize` has been deprecated.
1. `regionOfInterest: CGRect`  (The setting range is a blue line in gif.)
    - Set a range for trajectory detection.
    - The setting range is [0.0, 1.0], which is the normalized frame size. Set an origin, width, and height with `CGRect`. The default is `CGRect (x: 0, y: 0, width: 1.0, height: 1.0)`.
=======
    - トラッキングしたいモノ（ボール）の半径の最小を設定する
    - セットすることにより、ノイズや小さな動くモノをフィルタにかけることができる
    - 設定範囲は、フレームのサイズを正規化した[0.0, 1.0]で、デフォルトが0.0になっている
    - 同様のプロパティminimumObjectSizeは非推奨になっている
1. `regionOfInterest: CGRect`　※gifの青色の線が設定範囲になります
    - 軌道検出をする範囲を設定する
    - 設定範囲は、フレームのサイズを正規化した[0.0, 1.0]で、CGRectで原点と幅、高さを設定をし、デファルトは`CGRect(x: 0, y: 0, width: 1.0, height: 1.0)`になっている
>>>>>>> c03f8594d07b37e8d6f6ba18ab3e670b7de121fc

```swift: ViewController.swift
request.objectMaximumNormalizedRadius = 0.5
request.objectMinimumNormalizedRadius = 0.1
request.regionOfInterest = CGRect(x: 0, y: 0, width: 0.5, height: 1.0)
```

#### Call a Handler
Set `orientation` to `.right`. because if you do not set it, captured images will be sent to the request handler with a 90 degree rotation, and you will have to rerotate it 90 degrees when drawing the trajectory from the acquired observations.
```swift: ViewController.swift
func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    do {
        let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .right, options: [:])
        try requestHandler.perform([request])
    } catch {
        // Handle the error.
    }
}
```

#### Process the Results
Convert the coordinates of the acquired trajectories to the coordinate system of UIView of the origin in the upper because one of Vision of the origin is the lower left.
```swift: ViewController.swift
func completionHandler(request: VNRequest, error: Error?) {
    if let e = error {
        print(e)
        return
    }
    
    guard let observations = request.results as? [VNTrajectoryObservation] else { return }
    
    for observation in observations {
        // Convert the coordinates of the bottom-left to ones of the upper-left
        let detectedPoints: [CGPoint] = observation.detectedPoints.compactMap {point in
            return CGPoint(x: point.x, y: 1 - point.y)
        }
        let projectedPoints: [CGPoint] = observation.projectedPoints.compactMap { point in
            return CGPoint(x: point.x, y: 1 - point.y)
        }
        let equationCoefficients: simd_float3 = observation.equationCoefficients
        
        let uuid: UUID = observation.uuid
        let timeRange: CMTimeRange = observation.timeRange
        let confidence: VNConfidence = observation.confidence
    }
    
    //Call a method to draw the trajectory
}
```

#### Match the Results to UIView
Convert to the UIView angle of view in order to draw the trajectories correctly because the converted coordinates are normalized values.
```
func convertPointToUIViewCoordinates(normalizedPoint: CGPoint) -> CGPoint {
    // Convert normalized coordinates to UI View's ones
    let convertedX: CGFloat
    let convertedY: CGFloat
    
    if let rect = panGestureRect {
        // If ROI is setting
        convertedX = rect.minX + normalizedPoint.x*rect.width
        convertedY = rect.minY + normalizedPoint.y*rect.height
    }else {
        let videoRect = previewView.videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0))
        convertedX = videoRect.origin.x + normalizedPoint.x*videoRect.width
        convertedY = videoRect.origin.y + normalizedPoint.y*videoRect.height
    }
    
    return CGPoint(x: convertedX, y: convertedY)
}
```

<<<<<<< HEAD
## How to Use the App
1. Fix a device (iPhone or iPad) with a tripod.
2. Launch the app and the recorded video will be displayed.
3. When trajectories are detected in the video, the curves are drawn.
4. Specify a trajectory detection range by dragging with your finger.
5. Tap with your finger to cancel the detection range.
=======
## アプリの使い方
1. 三脚等でデバイスを固定する
2. アプリを起動し、撮影された動画が表示される
3. 動画内で軌道を検出すると、曲線が描画される
4. 軌道の検出範囲は、指でドラッグをすると指定できる
5. 指でタップをすると、検出範囲が解除される

## さいごに
軌道検出の実装の流れについては、Visionフレームワークの他の機能と同様なため、理解しやすかったです。  
ただ、動画撮影の設定と座標変換は、AVFoundationとUIKitのフレームワークについてもある程度理解しておかなくてはいけなく、実装が大変でした。
下記の参考文献がとても参考になりました。  
間違いがありましたら、ご指摘いただけるとありがたいです。
>>>>>>> c03f8594d07b37e8d6f6ba18ab3e670b7de121fc

## In Closing
The flow of the trajectory detection implementation is similar to other features of the Vision framework, so it is easy to understand.
However, it is difficult to implement the video recording settings and coordinate conversion because it is also necessary to understand the framework of AVFoundation and UIKit to some extent.
The following references were very helpful.
If this document make a mistake, I would appreciate it if you could point it out.

## References
- [Building a Feature-Rich App for Sports Analysis | Apple Developer Documentation](https://developer.apple.com/documentation/vision/building_a_feature-rich_app_for_sports_analysis)
- [Identifying Trajectories in Video | Apple Developer Documentation](https://developer.apple.com/documentation/vision/identifying_trajectories_in_video)
- [Setting Up a Capture Session | Apple Developer Documentation](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/setting_up_a_capture_session)
- [【iOS12対応】Visionを使って顔検出を行う - おもちゃラボ](https://nn-hokuson.hatenablog.com/entry/2019/07/25/212153)
- [【Vision・Core ML・iOS・Swift】リアルタイム映像のオブジェクトを識別する - Qiita](https://qiita.com/chino_tweet/items/da91690ef0143c9e8e9c)


