//
//  ViewController.swift
//  VideoEditing
//
//  Created by oren shalev on 09/06/2023.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {
    
    var playerController: AVPlayerViewController!
    var asset: AVAsset!
    var coinsAsset: AVAsset!
    var audioAsset: AVAsset!
    var tempAsset: AVAsset!
    
    var composition: AVMutableComposition!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = Bundle.main.url(forResource: "IMG_4919", withExtension: "MOV")!
        let coinsUrl = Bundle.main.url(forResource: "Coins", withExtension: "mov")!
        let audioUrl = Bundle.main.url(forResource: "song", withExtension: "mp3")!
        
        asset = AVAsset(url: url);
        coinsAsset = AVAsset(url: coinsUrl)
        audioAsset = AVAsset(url: audioUrl)
        


        
        Task {
//            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality)
//            let documentDirectory = FileManager.default.urls(for: .documentDirectory,
//                                                             in: .userDomainMask)[0]
//            let temp_url = documentDirectory.appendingPathComponent("asset_trim.mov")
//            exportSession?.outputURL = temp_url
//            exportSession?.outputFileType = .mov
//            exportSession?.timeRange = getTimeRange(start: 0, end: 2)
//            await exportSession?.export()
//            self.tempAsset = AVAsset(url: temp_url)

//            let exportSessionTwo = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality)
//            let temp_url_two = documentDirectory.appendingPathComponent("coins_trim.mov")
//            exportSessionTwo?.outputURL = temp_url_two
//            exportSessionTwo?.outputFileType = .mov
//            exportSessionTwo?.timeRange = getTimeRange(start: 0, end: 10)
//            await exportSessionTwo?.export()
//            self.coinsAsset = AVAsset(url: temp_url_two)
            
            await createComposition()
        }
        

        
        
//        let playerItem = AVPlayerItem(asset: self.composition)
//        let player = AVPlayer(playerItem: playerItem)
//        playerController = AVPlayerViewController()
//        playerController.player = player
//        addPlayerToTop()
    }

    func getTrack(asset: AVAsset, type: AVMediaType) async -> AVAssetTrack {
        let tracks = try! await asset.loadTracks(withMediaType: .video)
        return tracks.first!
    }
    
    func getTimeRange(start: Int64, end: Int64) -> CMTimeRange {
        let startTime = CMTimeMake(value: start, timescale: 1)
        let endTime = CMTimeMake(value: end, timescale: 1)
        return CMTimeRange(start: startTime, end: endTime)
    }
    
    func createComposition() async {
        self.composition = AVMutableComposition(urlAssetInitializationOptions: nil)
        let compositionTrack = self.composition.addMutableTrack(withMediaType: .video, preferredTrackID: .random(in: 1...4))

        
        let coinTracks = try? await coinsAsset.loadTracks(withMediaType: .video)
        if let coinTracks = coinTracks {
            let coinsTrack = coinTracks[0]
            let coinTrackTimeRange = try! await coinsTrack.load(.timeRange)
            try? compositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: try! await coinsAsset.load(.duration)), of: coinsTrack, at: .zero)
            print("successful load of track to composition")

        }
        else {
            print("error loading of tracks to composition")
        }
        
        let duration = CMTimeMake(value: 2, timescale: 1)
        let tracks = try? await asset.loadTracks(withMediaType: .video)
        print("tracks", tracks ?? "")

        guard let videoTrack = tracks?[0] else { return }
        try? compositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: videoTrack, at: CMTime.invalid)
        
       
        
        
        
        
        
        let zeroTime = CMTime(value: 0, timescale: 1)
        let audiotracks = try? await audioAsset.loadTracks(withMediaType: .audio)
        guard let audiotrack = audiotracks?[0] else { return }

        let compositionCommentaryTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: audiotrack.trackID)
        try! await compositionCommentaryTrack?
            .insertTimeRange(compositionTime()!,of: audiotrack, at: zeroTime)
        var trackMixArray = [AVMutableAudioMixInputParameters]()
        let trackMix = AVMutableAudioMixInputParameters(track: audiotrack)
        trackMix.setVolume(0.05, at: zeroTime)
//        trackMix.setVolumeRamp(fromStartVolume: 1, toEndVolume: 0.2,
//                               timeRange: CMTimeRange(start: startTime, end: endTime))
        trackMixArray.append(trackMix)


        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = trackMixArray
        
        
    
        
        let videoComposition = AVMutableVideoComposition()
        let someTransition = await createVideoTransition()
        videoComposition.instructions = [someTransition]
        videoComposition.renderSize = CGSizeMake(720, 1280)
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderScale = 0.5
        
        let playerItem = AVPlayerItem(asset: self.composition)
        playerItem.audioMix = audioMix
        playerItem.videoComposition = videoComposition
        let player = AVPlayer(playerItem: playerItem)
        playerController = AVPlayerViewController()
        playerController.player = player
        addPlayerToTop()
    }
    
    
    func createVideoTransition() async -> AVMutableVideoCompositionInstruction {
        let coinsTrack = await getTrack(asset: coinsAsset, type: .video)
//        let tempTrack = await getTrack(asset: tempAsset, type: .video)

//        let assetTrack = await getTrack(asset: asset, type: .video)
        let timeRange = try! await coinsTrack.load(.timeRange)
//         let timeRange = await compositionTime()!

        print("coin video Track timeRange", timeRange)
        print("coinAsset duration",try! await coinsAsset.load(.duration))
        print("compositionTime", await compositionTime()!)
        let compositionTime = await compositionTime()!
        let compositionTrack = composition.tracks(withMediaType: .video).first
        let compositionTimeRange = try! await compositionTrack?.load(.timeRange)
        print("composition track TimeRange",compositionTimeRange!)

        let transition = AVMutableVideoCompositionInstruction()
        transition.timeRange = compositionTimeRange!
//        CMTimeRange(start: CMTime(value: 5, timescale: 1), duration: CMTime(value: 3, timescale: 1))
        

        let fromLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack!)
        fromLayer.setOpacityRamp(fromStartOpacity: 1,
                                 toEndOpacity: 0.2,
                                 timeRange: CMTimeRange(start: CMTime(value: 2, timescale: 1), duration: CMTime(value: 5, timescale: 1)))
        
//        let toLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: tempTrack)
//        fromLayer.setOpacityRamp(fromStartOpacity: 1,
//                                 toEndOpacity: 1,
//                                 timeRange: getTimeRange(start: 2, end: 4))
        
        let layerInstructions = [fromLayer]
        transition.layerInstructions = layerInstructions
        
        return transition
    }
    
    func compositionTime() async -> CMTimeRange?  {
        if let tracks = try? await composition.loadTracks(withMediaType: .video),
           let timeRange = try? await tracks[0].load(.timeRange) {
            return timeRange
        }
        return nil
    }
    
    func addPlayerToTop() {
        //add as a childviewcontroller
        addChild(playerController)

         // Add the child's View as a subview
         self.view.addSubview(playerController.view)
        playerController.view.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height * 0.5)
        playerController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

         // tell the childviewcontroller it's contained in it's parent
        playerController.didMove(toParent: self)
        self.playerController.player?.play()
    }
    
    func generateImage() {
       let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.generateCGImageAsynchronously(for: CMTimeMake(value: 1, timescale: 2)) { [weak self] cgImage, time, error in
            guard let self = self else {
                return
            }
            if let cgImage = cgImage {
                DispatchQueue.main.async {
                    let image = UIImage(cgImage: cgImage)
                    self.imageView.image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
                }
            }
            else if let error = error {
                print(error)
            }
        }
    }
    
    
    @IBAction func openVC(_ sender: Any) {
        generateImage()
    }

    
    
}

