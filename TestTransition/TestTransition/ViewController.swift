//
//  ViewController.swift
//  TestTransition
//
//  Created by oren shalev on 12/06/2023.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {
    
    var playerController: AVPlayerViewController!
    var coinsAsset: AVAsset!
    var newsAsst: AVAsset!
    var composition: AVMutableComposition!
    var videoComposition: AVMutableVideoComposition!
    var transition: AVMutableVideoCompositionInstruction!
    var context: CIContext!
    var currentFilter: CIFilter!
    
    var playerHeight: CGFloat!
    var playerWidth: CGFloat!
    var videoSize: CGSize!

    var textEditorView: UIView!
    var testLabel: UILabel!
    var labelPosition: CGPoint!
    var fontSize = 17.0
    var videoRatio: CGFloat!
    var labelFontScale: CGFloat = 1
    var labelRotation: CGFloat = 0
    
    let labelStartingHeight = 20.0
    let labelStartingWidth = 100.0
    
    override func viewDidLoad() {
        let coinsUrl = Bundle.main.url(forResource: "Coins", withExtension: "mov")!
        let newsUrl = Bundle.main.url(forResource: "News", withExtension: "mov")!

        coinsAsset = AVAsset(url: coinsUrl)
        newsAsst = AVAsset(url: newsUrl)
        
        context = CIContext()
        currentFilter = CIFilter(name: "CIPhotoEffectMono")

        Task {
            self.composition = AVMutableComposition(urlAssetInitializationOptions: nil)

            let compositionTrack = self.composition.addMutableTrack(withMediaType: .video, preferredTrackID: .random(in: 1...4))!
            let compositionNewsTrack = self.composition.addMutableTrack(withMediaType: .video, preferredTrackID: 10)!
            
            let coinsFilterComposition = try! await AVMutableVideoComposition.videoComposition(with: self.coinsAsset) { [weak self] request in
                guard let self = self else {return}
                self.currentFilter.setValue(request.sourceImage.clampedToExtent(), forKey: kCIInputImageKey)
//                self.currentFilter.setValue(0.7, forKey: kCIInputIntensityKey)
//                let output = self.currentFilter.outputImage!.cropped(to: request.sourceImage.extent)

                request.finish(with: self.currentFilter.outputImage!, context: nil)
            }
            let exportSession = AVAssetExportSession(asset: self.coinsAsset, presetName: AVAssetExportPreset1280x720)
            let documentDirectory = FileManager.default.urls(for: .documentDirectory,
                                                            in: .userDomainMask)[0]

            let coinsTrack = try! await coinsAsset.loadTracks(withMediaType: .video)[0]
            let videoDuration = try! await coinsAsset.load(.duration)
            
            compositionTrack.preferredTransform = try! await coinsTrack.load(.preferredTransform)
            let naturalSize = try! await coinsTrack.load(.naturalSize)

            videoSize = CGSize(width: naturalSize.width, height: naturalSize.height)
            print("videoSize", videoSize!)
            let temp_url = documentDirectory.appendingPathComponent("coin_asset_8.mov")
            try? FileManager.default.removeItem(at: temp_url)

            exportSession?.outputURL = temp_url
            exportSession?.outputFileType = .mov
            exportSession?.timeRange = CMTimeRange(start: .zero, duration: videoDuration)
            exportSession?.videoComposition = coinsFilterComposition
            await exportSession?.export()
            let exportedAsset = AVAsset(url: temp_url)
            let exportedAssetTrack = try! await exportedAsset.loadTracks(withMediaType: .video)[0]

            try? compositionTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoDuration),
                                                                    of: exportedAssetTrack,
                                                                    at: CMTime.invalid)
            
            let oneSecond = CMTime(value: 1, timescale: 1)
            let newsTrack = try! await newsAsst.loadTracks(withMediaType: .video)[0]
            let newsDuration = try! await newsAsst.load(.duration)
            try? compositionNewsTrack.insertTimeRange(CMTimeRange(start: .zero, duration: newsDuration),
                                                                    of: newsTrack,
                                                                    at: videoDuration - oneSecond)
            let compositionDuration = videoDuration + newsDuration
            let compositionTimeRange = CMTimeRange(start: .zero, duration: compositionDuration)
//            let compositioTrackTimeRange = try! await compositionTrack.load(.timeRange)
            
            transition = AVMutableVideoCompositionInstruction()
            transition.timeRange = compositionTimeRange
            

            let startTime = videoDuration - oneSecond
            let fromLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
            fromLayer.setOpacityRamp(fromStartOpacity: 1,
                                     toEndOpacity: 0,
                                     timeRange: CMTimeRange(start: startTime, duration: oneSecond))

            
            let toLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionNewsTrack)
            toLayer.setOpacity(1, at: startTime)
            
            let layerInstructions = [fromLayer, toLayer]
            transition.layerInstructions = layerInstructions
            
            videoComposition = AVMutableVideoComposition()

//            func transformVideo(item: AVPlayerItem, cropRect: CGRect) {
//
//              let videoComposition = AVMutableVideoComposition(asset: item.asset, applyingCIFiltersWithHandler: {request in
//
//                let cropFilter = CIFilter(name: "CICrop")! //1
//                cropFilter.setValue(request.sourceImage, forKey: kCIInputImageKey) //2
//                cropFilter.setValue(CIVector(cgRect: cropRect), forKey: "inputRectangle")
//
//
//                let imageAtOrigin = cropFilter.outputImage!.transformed(by: CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y)) //3
//
//                request.finish(with: imageAtOrigin, context: nil) //4
//                })
//
//                videoComposition.renderSize = cropRect.size //5
//              item.videoComposition = videoComposition  //6
//            }

            videoComposition.instructions = [transition]
//            videoComposition.renderSize = CGSizeMake(720, 1280)
            videoComposition.renderSize = videoSize
            videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
//            videoComposition.renderScale = 0.5
//            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
//              postProcessingAsVideoLayer: videoLayer,
//              in: outputLayer)
            
            let playerItem = AVPlayerItem(asset: self.composition)
            playerItem.videoComposition = videoComposition
            let player = AVPlayer(playerItem: playerItem)
            let playerLayer = AVPlayerLayer(player: player)
            self.view.layer.addSublayer(playerLayer)
            videoRatio = naturalSize.width / naturalSize.height
            
            playerHeight = view.frame.size.height * 0.5
            playerWidth = playerHeight * videoRatio
            playerLayer.frame = CGRect(x: (view.frame.size.width / 2) - (playerWidth / 2), y: 0, width: playerWidth, height: playerHeight)
            playerLayer.backgroundColor = UIColor.black.cgColor
            player.play()
            
            textEditorView = UIView(frame: CGRect(x: (view.frame.size.width / 2) - (playerWidth / 2), y: 0, width: playerWidth, height: view.frame.size.height * 0.5))
            self.view.addSubview(textEditorView)
//            testLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
            testLabel = UILabel(frame: CGRect(x: 0, y: 100, width: 100, height: 20))
            testLabel.adjustsFontSizeToFitWidth = true

            testLabel.text = "hello world"
            testLabel.backgroundColor = .green
            testLabel.font = UIFont(name: "ArialRoundedMTBold", size: 100)
            testLabel.textColor = .white
            testLabel = addPanGestureToView(view: testLabel) as? UILabel
            let _ = addPinchGestureToView(view: testLabel)
//            let _ = addRotatehGestureToView(view: label)
            let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate(_:)))
    //        view.isUserInteractionEnabled = true
            testLabel.addGestureRecognizer(rotationGestureRecognizer)
            textEditorView.addSubview(testLabel)
            
//            viewLayer.backgroundColor = .green
//            viewLayer.layer.opacity = 0.3
            
            
//            playerController = AVPlayerViewController()
//            playerController.player = player
//            addPlayerToTop()
        }

        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    func exportedVideoComposition() -> AVVideoComposition {
        let exportedVideoComposition = AVMutableVideoComposition()
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
//        overlayLayer.backgroundColor = UIColor.green.cgColor

        add(text: testLabel.text!, to: overlayLayer, videoSize: videoSize)
//        addView(to: overlayLayer, videoSize: videoSize)

        let outputLayer = CALayer()
        outputLayer.frame = CGRect(origin: .zero, size: videoSize)
        outputLayer.addSublayer(videoLayer)
        outputLayer.addSublayer(overlayLayer)

        

        exportedVideoComposition.instructions = [transition]
        exportedVideoComposition.renderSize = videoSize
        exportedVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        exportedVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
              postProcessingAsVideoLayer: videoLayer,
              in: outputLayer)
        
        return exportedVideoComposition
    }
    
    @IBAction func generateVideo(_ sender: Any) {
        let theComposition = composition.copy() as! AVComposition
        let videoComposition = exportedVideoComposition()
        
        guard let exportSession = AVAssetExportSession(
          asset: theComposition,
          presetName: AVAssetExportPresetHighestQuality)
          else {
            print("Cannot create export session.")
            return
        }
        
        let videoName = UUID().uuidString
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
          .appendingPathComponent(videoName)
          .appendingPathExtension("mov")
        
        exportSession.videoComposition = videoComposition
        exportSession.outputFileType = .mov
        exportSession.outputURL = exportURL
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
              switch exportSession.status {
              case .completed:
                print("completed export with url: \(exportURL)")
                  guard UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(exportURL.relativePath) else { return }
                   
                   // 3
                  UISaveVideoAtPathToSavedPhotosAlbum(exportURL.relativePath, self, #selector(self.video(_:didFinishSavingWithError:contextInfo:)),nil)
                  
              default:
                print("Something went wrong during export.")
                print(exportSession.error ?? "unknown error")
                break
              }
            }

        }
    }
    
    @objc func video(
      _ videoPath: String,
      didFinishSavingWithError error: Error?,
      contextInfo info: AnyObject
    ) {
      let title = (error == nil) ? "Success" : "Error"
      let message = (error == nil) ? "Video was saved" : "Video failed to save"

      let alert = UIAlertController(
        title: title,
        message: message,
        preferredStyle: .alert)
      alert.addAction(UIAlertAction(
        title: "OK",
        style: UIAlertAction.Style.cancel,
        handler: nil))
      present(alert, animated: true, completion: nil)
    }

    private func add(text: String, to layer: CALayer, videoSize: CGSize) {
      let attributedText = NSAttributedString(
        string: text,
        attributes: [
          .font: UIFont(name: "ArialRoundedMTBold", size: 60) as Any,
          .foregroundColor: UIColor.blue,
          .strokeColor: UIColor.white,
          .strokeWidth: -3])
      
      let textLayer = CATextLayer()
      textLayer.string = attributedText
      textLayer.shouldRasterize = true
      textLayer.rasterizationScale = UIScreen.main.scale
      textLayer.backgroundColor = UIColor.green.cgColor
      textLayer.alignmentMode = .center
        
        let labelHeight = labelStartingHeight * labelFontScale
        let labelWidth = labelStartingWidth * labelFontScale
        
        let labelWidthRatio = labelWidth / textEditorView.frame.width
        let labelHeightRatio = labelHeight / textEditorView.frame.height
        let labelNewYPoint = (labelPosition.y / textEditorView.frame.height) * videoSize.height
        let labelNewXPoint = (labelPosition.x / textEditorView.frame.width) * videoSize.width
        
//        let widthMultiplyer = textEditorView.frame.width / testLabel.frame.size.width
//        let heightMultiplyer = textEditorView.frame.height / testLabel.frame.size.height

        
        let newLabelHeight = videoSize.height * labelHeightRatio
        let newLabelWidth = videoSize.width * labelWidthRatio

//        textLayer.frame = CGRect(
//            x: videoSize.width / 2,
//            y: videoSize.height - labelNewYPoint - (newLabelHeight / 2),
//          width: newLabelWidth,
//          height: newLabelHeight)
        
        textLayer.frame = CGRect(
            x: labelNewXPoint - (newLabelWidth / 2),
            y: videoSize.height - labelNewYPoint - (newLabelHeight / 2),
          width: newLabelWidth,
          height: newLabelHeight)

//        textLayer.anchorPoint = CGPoint(x: 0.5, y: -0.5)
        
//        textLayer.frame = CGRect(
//            x: labelNewXPoint,
//            y: videoSize.height - newLabelHeight - labelNewYPoint,
//          width: newLabelWidth,
//          height: newLabelHeight)
        
        
        let degrees = 60 * labelRotation
        print("degrees", degrees)
        let radians = CGFloat(degrees * Double.pi / 180)

        textLayer.transform = CATransform3DMakeRotation(radians, 0, 0, -1)


//        textLayer.frame = CGRect(
//            x: labelNewXPoint,
//            y: videoSize.height - newLabelHeight - labelNewYPoint,
//          width: newLabelWidth,
//          height: newLabelHeight)
        
//      textLayer.frame = CGRect(
//        x: ((labelPosition.x - (testLabel.frame.size.width / 2)) / videoRatio),
//        y: ((labelPosition.y - (testLabel.frame.size.height / 2)) / videoRatio),
//        width: videoSize.width * labelWidthRatio,
//        height: videoSize.height * labelHeightRatio)
      textLayer.displayIfNeeded()
      
      layer.addSublayer(textLayer)
    }
    
    private func addView(to layer: CALayer, videoSize: CGSize) {
//      let image = UIImage(named: "overlay")!
      let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
      view.backgroundColor = .blue
      
      let imageLayer = CALayer()
        let aspect: CGFloat = view.frame.size.width / view.frame.size.height
      let width = videoSize.width
      let height = width / aspect
      imageLayer.frame = CGRect(
        x: 0,
        y: 0,
        width: view.frame.size.width * 4,
        height: view.frame.size.height * 4)
      
  //    imageLayer.contents = image.cgImage
       imageLayer.contents = view
       imageLayer.contentsGravity = .resizeAspectFill
       layer.addSublayer(imageLayer)
    }
    func addPanGestureToView(view: UIView) -> UIView {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(panGestureRecognizer)
        return view
    }
    
    func addPinchGestureToView(view: UIView) -> UIView {
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(pinchGestureRecognizer)
        return view
    }
    
    func addRotatehGestureToView(view: UIView) -> UIView {
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate(_:)))
//        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(rotationGestureRecognizer)
        return view
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
      // 1
        guard let gestureView = gesture.view as? UILabel else {
          return
        }

//        testLabel.font = testLabel.font.withSize(fontSize * gesture.scale)

        gestureView.transform = gestureView.transform.scaledBy(
          x: gesture.scale,
          y: gesture.scale
        )
        
        print(gesture.scale)
        
        labelFontScale *= gesture.scale
//        print("labelFontScal \(labelFontScale)")

//        let newHeight = labelStartingHeight * labelFontScale
//        let newWidth = labelStartingWidth * labelFontScale
//        print("(width,height) (\(newWidth),\(newHeight)")

        

        gesture.scale = 1
    }
    
    @objc func handleRotate(_ gesture: UIRotationGestureRecognizer) {
        guard let gestureView = gesture.view else {
          return
        }

        gestureView.transform = gestureView.transform.rotated(
          by: gesture.rotation
        )
        print("labelRotation", labelRotation)
        labelRotation += gesture.rotation
        gesture.rotation = 0


    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
      // 1
      let translation = gesture.translation(in: view)
//        print("translation", translation)
      // 2
      guard let gestureView = gesture.view else {
        return
      }

      gestureView.center = CGPoint(
        x: gestureView.center.x + translation.x,
        y: gestureView.center.y + translation.y
      )
        labelPosition = gestureView.center
        
//        print("x: ", gestureView.center.x)
//        print("y: ", gestureView.center.y)

      // 3
      gesture.setTranslation(.zero, in: view)
    }
    
    func addPlayerToTop() {
        //add as a childviewcontroller
        addChild(playerController)

         // Add the child's View as a subview
         self.view.addSubview(playerController.view)
        playerController.view.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height * 0.5)
        playerController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let viewLayer = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height * 0.5))
        self.view.addSubview(viewLayer)
        viewLayer.backgroundColor = .green
        viewLayer.layer.opacity = 0.3
         // tell the childviewcontroller it's contained in it's parent
        playerController.didMove(toParent: self)
        self.playerController.player?.play()
    }

}

extension UIView {
    func setAnchorPoint(_ point: CGPoint) {
        var newPoint = CGPoint(x: bounds.size.width * point.x, y: bounds.size.height * point.y)
        var oldPoint = CGPoint(x: bounds.size.width * layer.anchorPoint.x, y: bounds.size.height * layer.anchorPoint.y);

        newPoint = newPoint.applying(transform)
        oldPoint = oldPoint.applying(transform)

        var position = layer.position

        position.x -= oldPoint.x
        position.x += newPoint.x

        position.y -= oldPoint.y
        position.y += newPoint.y

        layer.position = position
        layer.anchorPoint = point
    }
}
