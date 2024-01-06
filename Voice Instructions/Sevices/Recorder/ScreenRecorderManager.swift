//
//  ScreenRecorderManager.swift
//  Voice Instructions
//
//

import AVFoundation
import ReplayKit
import Photos
import Combine


class ScreenRecorderManager: ObservableObject{
    
    /// Show final video preview screen
    @Published var showPreview: Bool = false
    
    /// State recorder at least once tapped
    @Published private(set) var recorderIsActive: Bool = false
    
    /// Recording state
    @Published private(set) var isRecord: Bool = false
    
    /// Loader state
    @Published private(set) var showLoader: Bool = false
    
    /// Finale video publisher
    private(set) var finalVideo = CurrentValueSubject<Video?, Never>(nil)
    
    /// All recorded videos urls for merged logic
    private(set) var videoURLs = [URL]()
    
    /// The number of finished videos needed to determine video rendering
    private var videoCounter: Int = 0
    
    /// RPScreenRecorder class
    private let recorder = RPScreenRecorder.shared()
    
    private var assetWriter: AVAssetWriter!
    private var videoInput: AVAssetWriterInput!
    private var audioMicInput: AVAssetWriterInput!
    private var cancelBag = CancelBag()
    private let fileManager = FileManager.default
    
    
    init(){
        startCreatorSubs()
    }
    
    /// start record session, initializing the record alert
    /// setup AssetWriters
    /// save audio and video buffer
    func startRecoding(){
        AVAudioSession.sharedInstance().playAndRecord()
        recorder.isMicrophoneEnabled = true
        recorder.startCapture { [weak self] (cmSampleBuffer, rpSampleBufferType, err) in
            guard let self = self else {return}
            if let err = err {
                print(err.localizedDescription)
                return
            }
            if CMSampleBufferDataIsReady(cmSampleBuffer) {
                DispatchQueue.main.async {
                    
                    switch rpSampleBufferType {
                    case .video:
                        
                        if self.assetWriter?.status == AVAssetWriter.Status.unknown {
                            print("Started writing")
                            self.assetWriter?.startWriting()
                            self.assetWriter?.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(cmSampleBuffer))
                        }
                        
                        if self.assetWriter.status == AVAssetWriter.Status.failed {
                            print("StartCapture Error Occurred, Status = \(self.assetWriter.status.rawValue), \(self.assetWriter.error!.localizedDescription) \(self.assetWriter.error.debugDescription)")
                            return
                        }
                        
                        if self.assetWriter.status == AVAssetWriter.Status.writing {
                            if self.videoInput.isReadyForMoreMediaData {
                                if self.videoInput.append(cmSampleBuffer) == false {
                                    print("problem writing video")
                                }
                            }
                        }
                        
                    case .audioMic:
                        if self.audioMicInput.isReadyForMoreMediaData {
                            self.audioMicInput.append(cmSampleBuffer)
                        }
                        
                    default: break
                    }
                }
            }
        } completionHandler: { [weak self] error in
            guard let self = self else {return}
            if let error {
                print(error.localizedDescription)
            }else{
                self.createFileAndSetupAssetWriters()
                self.isRecord = true
                self.recorderIsActive = true
            }
        }
    }
    
    private func createFileAndSetupAssetWriters(){
        let name = "record_\(Date().ISO8601Format()).mp4"
        let url = fileManager.temporaryDirectory.appendingPathComponent(name)
        videoURLs.append(url)
        setupAssetWriters(url)
    }
    
    

    
    /// Remove all video and reset state
    func removeAll(){
        if recorder.isRecording{
            recorder.stopRecording()
        }
        isRecord = false
        recorderIsActive = false
        videoURLs.forEach { url in
            fileManager.removeFileIfExists(for: url)
        }
        if let finalURl = finalVideo.value?.fullPath{
            fileManager.removeFileIfExists(for: finalURl)
        }
        videoURLs = []
        resetVideoCounter()
    }
    
    /// Pause
    /// stop capture and finish writing
    func pause(){
        recorder.stopCapture { error in
            self.videoInput.markAsFinished()
            self.audioMicInput.markAsFinished()
            self.assetWriter.finishWriting {
                DispatchQueue.main.async {
                    self.isRecord = false
                }
            }
        }
    }
    
    /// Stop
    /// If we record stop and create video otherwise we create a video
    func stop(videoFrameSize: CGSize){
        showLoader = true
        if recorder.isRecording{
            recorder.stopCapture { (error) in
                if let error{
                    print(error.localizedDescription)
                    self.isRecord = false
                    self.showLoader = false
                    return
                }
                guard let videoInput = self.videoInput,
                      let assetWriter = self.assetWriter else {
                    self.isRecord = false
                    self.showLoader = false
                    return
                }
                
                videoInput.markAsFinished()
                
                if let audioMicInput = self.audioMicInput {
                    audioMicInput.markAsFinished()
                }
               
                assetWriter.finishWriting {
                    
                    DispatchQueue.main.async {
                        self.isRecord = false
                    }
                    
                    Task {
                        await self.createVideoIfNeeded(self.videoURLs, baseSize: videoFrameSize)
                    }
                }
            }
        }else{
            Task {
                await self.createVideoIfNeeded(self.videoURLs, baseSize: videoFrameSize)
            }
        }
    }
    
    /// Subscription to create a video
    private func startCreatorSubs(){
        finalVideo
            .receive(on: RunLoop.main)
            .sink { video in
                guard video != nil else {return}
                self.showLoader = false
                self.showPreview = true
            }
            .store(in: cancelBag)
    }
    
    private var isNotAddedNew: Bool{
        finalVideo.value != nil && videoCounter == videoURLs.count
    }
    
    
    /// Create video
    /// Merge and render videos
    private func createVideoIfNeeded(_ urls: [URL], baseSize: CGSize) async {
        guard !urls.isEmpty else {
            return
        }
        
        if isNotAddedNew{
            finalVideo.send(finalVideo.value)
            return
        }
        
        let composition = AVMutableComposition()
        
        print("Merged video urls:", urls)
        
        do{
            try await mergeVideos(to: composition, from: urls, audioEnabled: recorder.isMicrophoneEnabled)
            
            ///Remove all cash videos
            urls.forEach { url in
                fileManager.removeFileIfExists(for: url)
            }
            self.videoURLs.removeAll(keepingCapacity: false)
            
        }catch{
            print(error.localizedDescription)
        }
        
        
        let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        let exportUrl = URL.documentsDirectory.appending(path: "merged_video.mp4")
        fileManager.removeFileIfExists(for: exportUrl)
        
        exporter?.outputURL = exportUrl
        exporter?.outputFileType = .mp4
        exporter?.shouldOptimizeForNetworkUse = false

        await exporter?.export()

        if exporter?.status == .completed {
            
            if fileManager.fileExists(atPath: exportUrl.path) {
                
                print("baseSize", baseSize)
                /// CropVideo
                let finishVideoUrl = try? await rotateAndCrop(
                    url: exportUrl,
                    cropSize:
                            .init(width: baseSize.width * UIScreen.main.scale, height: baseSize.height * UIScreen.main.scale))
                
                if let finishVideoUrl{
                    ///create video
                    self.createVideo(finishVideoUrl)
                    /// append original non croped video
                    self.videoURLs.append(finishVideoUrl)
                    
                    self.videoCounter = videoURLs.count
                }
            }
        }else if let error = exporter?.error{
            print(error.localizedDescription)
        }
    }
    
    
    private func createVideo(_ url: URL){
        Task{
            let video = await Video(url: url)
            finalVideo.send(video)
        }
    }
    
    func resetVideoCounter(){
        videoCounter = 0
    }
}


//MARK: - Helpers
extension ScreenRecorderManager{
    
    
    /// Setup AVAssetWriter
    /// Setup video and audio settings
    /// High quality video and audio
    private func setupAssetWriters(_ url: URL){
        do {
            try assetWriter = AVAssetWriter(outputURL: url, fileType: .mp4)
        } catch {
            print(error.localizedDescription)
        }
        
        let videoCodecType = AVVideoCodecType.h264
        let bitsPerSecond: Int = 25_000_000
        let profileLevel = AVVideoProfileLevelH264HighAutoLevel
        
        let compression: [String : Any] = [
            AVVideoAverageBitRateKey: bitsPerSecond,
            AVVideoProfileLevelKey: profileLevel,
            AVVideoExpectedSourceFrameRateKey: 30
        ]
        
        let videoOutputSettings: [String: Any] = [
            AVVideoCodecKey: videoCodecType,
            AVVideoWidthKey: UIScreen.main.nativeBounds.width,
            AVVideoHeightKey: UIScreen.main.nativeBounds.height,
            AVVideoCompressionPropertiesKey: compression,
        ]
        
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
        videoInput.expectsMediaDataInRealTime = true
        
        if assetWriter.canAdd(videoInput) {
            assetWriter.add(videoInput)
        }
        
        let audioSettings: [String: Any] = [
            AVFormatIDKey : kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey : 2,
            AVSampleRateKey : 44100.0,
            AVEncoderBitRateKey: 192000
        ]
        
        audioMicInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioMicInput.expectsMediaDataInRealTime = true
        if assetWriter.canAdd(audioMicInput) {
            assetWriter.add(audioMicInput)
        }
    }
    
    /// Merge videos
    /// Combining multiple videos for a composition
    /// audioEnabled:  Turning on the audio track
    private func mergeVideos(to composition: AVMutableComposition,
                             from urls: [URL], audioEnabled: Bool) async throws{
        
        let assets = urls.map({AVAsset(url: $0)})
        
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let compositionAudioTrack: AVMutableCompositionTrack? = audioEnabled ? composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) : nil
        
        var lastTime: CMTime = .zero
        
        for asset in assets {
            
            let videoTracks = try await asset.loadTracks(withMediaType: .video)
            let audioTracks = try? await asset.loadTracks(withMediaType: .audio)
            
            let duration = try await asset.load(.duration)
           
            let timeRange = CMTimeRangeMake(start: .zero, duration: duration)
            
            
            print("duration:", duration.seconds, "lastTime:", lastTime.seconds)
            
            if let audioTracks, !audioTracks.isEmpty, let audioTrack = audioTracks.first,
               let compositionAudioTrack {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: lastTime)
                let audioPreferredTransform = try await audioTrack.load(.preferredTransform)
                compositionAudioTrack.preferredTransform = audioPreferredTransform
            }
            
            guard let videoTrack = videoTracks.first else {return}
            try compositionVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: lastTime)
            let videoPreferredTransform = try await videoTrack.load(.preferredTransform)
            compositionVideoTrack?.preferredTransform = videoPreferredTransform
            
            lastTime = CMTimeAdd(lastTime, duration)
        }

        print("TotalTime:", lastTime.seconds)
    }
    

    /// Rotate recorder video
    /// Crop video for size
    private func rotateAndCrop(url: URL, cropSize: CGSize) async throws -> URL?{
        
        let asset = AVAsset(url: url)
        
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {return nil}
        
        /// Original video size
        let originalSize = try await videoTrack.load(.naturalSize)
        let duration = try await asset.load(.duration)
        
        let videoComposition = AVMutableVideoComposition()
        
        /// New size and scale
        let newVideoSize = CGSize(width: originalSize.height, height: originalSize.width)
        let scaleX = newVideoSize.width / originalSize.width
        let scaleY = newVideoSize.height / originalSize.height
        
        print("rotatedVideoSize", newVideoSize)
        
        
        ///Crop size
        let cropRect = CGRect(
            x: (newVideoSize.width - cropSize.width) / 2,
            y: (newVideoSize.height - cropSize.height) / 2,
            width: cropSize.width,
            height: cropSize.height
        ).integral
        
        ///Transform video
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            .translatedBy(x: -cropRect.origin.x * scaleY, y: -cropRect.origin.y - 45)
        transformer.setTransform(transform, at: .zero)
        
        
        ///Setup videoComposition
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        ///Set new crop rect size
        videoComposition.renderSize = cropRect.size
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        let exportUrl = URL.documentsDirectory.appending(path: "preview_video.mp4")
        fileManager.removeFileIfExists(for: exportUrl)
        
        exporter?.videoComposition = videoComposition
        exporter?.outputURL = exportUrl
        exporter?.outputFileType = .mp4
        exporter?.shouldOptimizeForNetworkUse = false
        
        await exporter?.export()
        
        if exporter?.status == .completed {
            if fileManager.fileExists(atPath: exportUrl.path) {
                fileManager.removeFileIfExists(for: url)
                return exportUrl
            }
        }else if let error = exporter?.error{
            throw error
        }
        return nil
    }
}
