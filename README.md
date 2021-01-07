#  【Swift】動画からリアルタイムにボールの軌道を検出するアプリを作りました

## はじめに
撮影している動画に対して、リアルタイムでボールの軌道を検出し、動画に軌道を重ね合わせるアプリを作成しました（下記のgifは作成したアプリでゴルフボールの軌道を検出したデモです） 。  
画像処理を目的とした[Visionフレームワーク（顔検出、文字検出、バーコード検出、...）](https://developer.apple.com/documentation/vision)の中の１つの機能として、軌道検出がiOS14から使用できるようになりました。
しかし、Vsionフレームワーク関係、特に軌道検出についての情報がほとんどネットに無かったので、記事を書きました。  
私自身もVisionフレームワークを使い始めたばかりなので、アドバイスをいただけると幸いです。  
ソースコードは[こちら](https://github.com/MIZUNO-CORPORATION/IdentifyingBallTrajectoriesinVideo)になります。  
![デモ動画](Demo/golf.gif)


## 利用用途
球技スポーツ（ゴルフ、野球、サッカー等）のボールの軌道検出のため  
iOS14以降でのiPhone/iPadに対応


## 軌道検出の流れ
軌道検出をするには「リクエスト」と「リクエストハンドラ」、「オブザベーション」を使います。
1. リクエストで、Visionフレームワーク中の使用したい機能とパラメタを設定します（今回は、軌道検出機能の `VNDetectTrajectoriesRequest` を使用）
1. リクエストハンドラに、処理したい画像と設定したリクエストを渡すことで検出処理が行われます
1. オブザベーションで、検出結果が取得できます（今回は、軌道検出用途の `VNTrajectoryObservation` で取得）

## 軌道検出で取得できる情報
オブザベーションから下記のような情報が取得できます
1. `detectedPoints`
   - 検出された軌道の座標：リクエストで設定したフレーム数過去に遡り、フレーム数分の軌道の[0,1.0]に正規化されたx,y座標が取得される
   - `[VNPoint]`  ：画像におけるx,y座標の配列
   - アウトプット例：[[0.027778; 0.801562], [0.073618; 0.749221], [0.101400; 0.752338], [0.113900; 0.766406], [0.119444; 0.767187], [0.122233; 0.774219], [0.130556; 0.789063], [0.136111; 0.789063], [0.144444; 0.801562], [0.159733; 0.837897]]
1. `projectedPoints`
   - 予測された軌道の座標：過去の5フレーム分遡り、5点分の2次方程式に変換された軌道の[0,1.0]に正規化されたx,y座標が取得される
   - `[VNPoint]`：画像におけるx,y座標の配列
   - アウトプット例：[[0.122233; 0.771996], [0.130556; 0.782801], [0.136111; 0.791214], [0.144444; 0.805637], [0.159733; 0.837722]]
1. `equationCoefficients`
   - 予測された軌道の2次方程式：projectedPointで変換された軌道の2次方程式が取得される
   - `simd_float3`：2次方程式の係数
   - アウトプット例：SIMD3<Float>(15.573865, -2.6386108, 0.86183345)
1. `uuid`
    - 軌道のID：各軌道でIDが与えられる。次のフレームで検出した軌道が前のフレームで検出した軌道に含まれると判定された場合は、同じIDが与えられる
    - `UUID`：一意のID
    - アウトプット例：E5256430-439E-4B0F-91B0-9DA6D65C22EE
1. `timeRange`
    - ：
    - `CMTimeRange`：
    - アウトプット例：{{157245729991291/1000000000 = 157245.730}, {699938542/1000000000 = 0.700}}
1. `confidence`
    - 軌道の信頼度：[0,1.0]に正規化された検出された軌道の信頼度
    - `VNConfidence`：[0,1.0]に正規化された観測物の精度の信頼水準
    - アウトプット例：0.989471

## 実装方法
### 開発環境
  - XCode 12.2
  - Swift 5
### 使用フレームワーク
  1. UIKit
  1. Vision
  1. AVFoundation

### 軌道検出に関係するクラスの説明
```
request = VNDetectTrajectoriesRequest(frameAnalysisSpacing: .zero, trajectoryLength: 10, completionHandler: completionHandler)
```

```swift: ViewController.swift
func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    do {
        let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer)
        try requestHandler.perform([request])
    } catch {
        // Handle the error.
    }
}
```

1. VNDetectTrajectoriesRequest
    - インスタンスを生成する際に、引数で下記を与えます
    - frameAnalysisSpacing: CMTime
        - 軌道の分析の時間間隔を設定します
        - この値を大きくすると、分析にかけるフレームを間引くことができ、スペックの低いデバイスで有効だそうです
        - .zeroに設定すると全てのフレームを分析にかけることができます（今回は.zeroにしました）
    - trajectoryLength: Int
        - 軌道に乗っている点に必要な数です
        - 最低は5点ですが、点数が少ないとたくさんの軌道を誤認識してしまいます（個人的には、10点くらいにするとちょうど良くゴルフボールを捉えることができました）
     - completionHandler: VNRequestCompletionHandler?
        - 検出が完了した際に呼ばれるクロージャです　※今回、completionHandlerというメソッドを作成し、それが呼ばれるようにしました
    - プロパティ
     - objectMaximumNormalizedRadius: Float　※今回、設定値が反映されなかったので、機能していないように思います
       - トラッキングしたいモノ（ボール）の半径の最大を設定します
       - セットすることにより、大きな動くモノをフィルタにかけることができます
       - 設定範囲は、フレームのサイズを正規化した[0.0, 1.0]で、デフォルトが1.0になっています
       - 同様のプロパティmaximumObjectSizeは非推奨になりました
    - objectMinimumNormalizedRadius: Float　※今回、設定値が反映されなかったので、機能していないように思います
      - トラッキングしたいモノ（ボール）の半径の最小を設定します
      - セットすることにより、ノイズや小さな動くモノをフィルタにかけることができます
      - 設定範囲は、フレームのサイズを正規化した[0.0, 1.0]で、デフォルトが0.0になっています
      - 同様のプロパティminimumObjectSizeは非推奨になりました
    - regionOfInterest: CGRect（今回、設定値が反映されなかったので、機能していないように思います）
      - 軌道検出をする範囲を設定します
      - 設定範囲は、フレームのサイズを正規化した[0.0, 1.0]で、CGRectで原点と幅、高さを設定をします
    - results: [VNTrajectoryObservation]?
      - 軌道検出が完了した際に結果として返される変数です
1. VNTrajectoryObservation
      - detectedPoints
        - 
      - projectedPoints
        - 
      - equationCoefficients
      - uuid
        - 各軌道でユニークなIDが与えられます
        - ex) 
      - timeRange
      - confidence
        - 軌道の信頼度が与えられます
        - ほとんどの場合で0.9を超えています
        - ex) 

![軌道検出の説明](images/rendered2x-1591650146.png)
[Identifying Trajectories in Video | Apple Developer Documentation](https://developer.apple.com/documentation/vision/identifying_trajectories_in_video)より引用しました
  
  

### 実装のポイント

## さいごに
間違いがありましたら、ご指摘いただけるとありがたいです。


## 参考文献
- [Building a Feature-Rich App for Sports Analysis | Apple Developer Documentation](https://developer.apple.com/documentation/vision/building_a_feature-rich_app_for_sports_analysis)
- [Identifying Trajectories in Video | Apple Developer Documentation](https://developer.apple.com/documentation/vision/identifying_trajectories_in_video)
- [Setting Up a Capture Session | Apple Developer Documentation](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/setting_up_a_capture_session)
- [](https://nn-hokuson.hatenablog.com/entry/2019/07/25/212153)


