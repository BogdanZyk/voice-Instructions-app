//
//  VideoPlayerManager.swift
//  Voice Instructions
//
//

import Foundation
import Combine
import AVKit
import PhotosUI
import SwiftUI


/// A class for video management
final class VideoPlayerManager: ObservableObject{
    
    private(set) var videoPlayer = AVPlayer()
    
    /// PhotosPickerItem from PhotosPicker
    @Published var selectedItem: PhotosPickerItem?
    
    /// Current video time
    @Published var currentTime: Double = .zero
    
    /// Current video
    @Published var video: Video?
    
    /// Video load state
    @Published private(set) var loadState: LoadState = .unknown
    
    /// Player state
    @Published private(set) var isPlaying: Bool = false
    
    /// Video rate
    private var rate: Float = 1
    
    private var cancelBag = CancelBag()
    
    /// Observers
    private var timeObserver: Any?
    
    /// Current duration range for trim time logic
    private var currentDurationRange: ClosedRange<Double>?
    
    /// Seek state
    private var isSeekInProgress: Bool = false
    
    /// Reached the end time of the video
    private var isReachedEndTime: Bool = false
    
    /// Storage video from userDefaults
    private let videoStorageService = VideoStorageService.shared
    
    
    deinit{
        removeTimeObserver()
    }
    
    init(fromStorage: Bool = false){
        
        if fromStorage{
            loadState = .loading
            loadVideo(videoStorageService.load())
        }
    }

    /// Scrubbing state for seek video time
    var scrubState: PlayerScrubState = .reset {
        didSet {
            switch scrubState {
            case .scrubEnded(let seekTime):
                seek(seekTime)
            default : break
            }
        }
    }
    
    /// Play or pause video
    func action(){
        if isPlaying{
            pause()
        }else{
            play(rate)
        }
    }
    
    /// Play or pause video from range
    func action(_ range: ClosedRange<Double>){
        self.currentDurationRange = range
        if isPlaying{
            pause()
        }else{
            play(rate)
        }
    }
        
    /// Observing the change timeControlStatus
    private func startControlStatusSubscriptions(){
        videoPlayer.publisher(for: \.timeControlStatus)
            .sink { [weak self] status in
                guard let self = self else {return}
                switch status {
                case .playing:
                    self.startTimer()
                    self.isPlaying = true
                case .paused:
                    self.isPlaying = false
                case .waitingToPlayAtSpecifiedRate:
                    break
                @unknown default:
                    break
                }
            }
            .store(in: cancelBag)
    }
    
    
    func pause(){
        guard isPlaying else {return}
        videoPlayer.pause()
    }
    
    /// Set video volume
    func setVolume(_ value: Float){
        pause()
        videoPlayer.volume = value
    }

    /// Play for rate and durationRange
    private func play(_ rate: Float?){
        AVAudioSession.sharedInstance().configurePlaybackSession()
        if isReachedEndTime{
            seek(currentDurationRange?.lowerBound ?? 0)
            isReachedEndTime = false
        }else{
            seek(currentTime)
        }
        
        videoPlayer.play()
        
        if let rate{
            self.rate = rate
            videoPlayer.rate = rate
        }
    }
     
    /// Seek video time
     func seek(_ seconds: Double){
         if isSeekInProgress{ return }
         pause()
         isSeekInProgress = true
         videoPlayer.seek(to: CMTimeMakeWithSeconds(seconds, preferredTimescale: 600), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) {[weak self] isFinished in
             guard let self = self else {return}
             if isFinished{
                 self.handleReachedEndTime(seconds, withPause: false)
                 self.isSeekInProgress = false
             }else{
                 self.seek(seconds)
             }
         }
    }
    
    func setRateAndPlay(_ rate: Float){
        videoPlayer.pause()
        play(rate)
    }
        
    /// Start video timer
    private func startTimer() {
        
        let interval = CMTimeMake(value: 1, timescale: 100)
        timeObserver = videoPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            if self.isPlaying{

                let time = time.seconds
                
                self.handleReachedEndTime(time, withPause: true)

                switch self.scrubState {
                case .reset:
                    self.currentTime = time
                case .scrubEnded:
                    self.scrubState = .reset
                case .scrubStarted:
                    break
                }
            }
        }
    }
    
    /// Handle is reached end video time
    private func handleReachedEndTime(_ time: Double, withPause: Bool){
        if time.rounded(toPlaces: 2) >= currentDurationRange?.upperBound ?? 0{
            isReachedEndTime = true
            if withPause{
                pause()
            }
        }
    }
 
    /// Remove all time observers
    private func removeTimeObserver(){
        if let timeObserver = timeObserver {
            videoPlayer.removeTimeObserver(timeObserver)
        }
    }
    /// Set did finish playing observer
    private func setDidFinishPlayingObserver(){
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: videoPlayer.currentItem, queue: .main) { [weak self] _ in
            guard let self = self else {return}
            self.pause()
            self.isReachedEndTime = true
        }
    }
    
}

extension VideoPlayerManager{
    
    
    /// Load item from PhotosPicker
    @MainActor
    func loadVideoItem(_ selectedItem: PhotosPickerItem?) async{
        do {
            loadState = .loading
            if let item = try await selectedItem?.loadTransferable(type: VideoItem.self) {
                self.pause()
                
                /// Create video
                self.videoPlayer = AVPlayer(url: item.url)
                let video = await Video(url: item.url)
                self.video = video
                self.currentDurationRange = video.rangeDuration
                self.startControlStatusSubscriptions()
                
                print("AVPlayer set url:", item.url.absoluteString)
                
                self.setDidFinishPlayingObserver()
                
                /// save video to storage
                self.save()
                
                loadState = .loaded
                
                try await Task.sleep(for: .milliseconds(500))
                ///play
                self.action()
                
            } else {
                loadState = .failed
            }
        } catch {
            print(error.localizedDescription)
            loadState = .failed
        }
    }
}

extension VideoPlayerManager{
    
    enum LoadState: Int {
        case unknown, loading, loaded, failed
    }

    enum PlayerScrubState{
        case reset
        case scrubStarted
        case scrubEnded(Double)
    }
}






extension VideoPlayerManager{
    
    /// load storage video object
    func loadVideo(_ video: Video?){
        if let video{
            self.video = video
            self.videoPlayer = AVPlayer(url: video.fullPath)
            self.currentDurationRange = video.rangeDuration
            self.startControlStatusSubscriptions()
            self.setDidFinishPlayingObserver()
            self.loadState = .loaded
        }else{
            self.loadState = .unknown
        }
        
    }
    
    private func save(){
        guard let video else {return}
        videoStorageService.save(video)
    }
    
    ///remove copy video and storage video object
    func removeVideo(){
        if let video{
            FileManager.default.removeFileIfExists(for: video.fullPath)
            videoStorageService.remove()
            removeTimeObserver()
            selectedItem = nil
            currentTime = .zero
            loadState = .unknown
            self.videoPlayer = .init()
            self.video = nil
        }
    }
}
