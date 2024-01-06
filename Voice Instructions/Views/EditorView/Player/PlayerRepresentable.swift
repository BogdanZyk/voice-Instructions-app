//
//  PlayerRepresentable.swift
//  Voice Instructions
//
//

import SwiftUI
import AVKit

struct PlayerRepresentable: UIViewControllerRepresentable {
    
    @Binding var size: CGSize
    var player: AVPlayer
    let view = AVPlayerViewController()
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        view.player = player
        view.showsPlaybackControls = false
        view.allowsVideoFrameAnalysis = false
        view.videoGravity = .resizeAspect
        return view
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject{
        
        let parent: PlayerRepresentable
        let keyPath = "videoBounds"
        
        init(_ parent: PlayerRepresentable) {
            self.parent = parent
            super.init()
            parent.view.addObserver(self, forKeyPath: keyPath, options: .new, context: nil)
        }
        
        deinit{
            parent.view.removeObserver(self, forKeyPath: keyPath)
        }
        
        ///Predefine the observer and set a new video frame size
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == keyPath {
                if let newBoundsValue = change?[.newKey] as? NSValue {
                    let newBounds = newBoundsValue.cgRectValue
                    DispatchQueue.main.async {
                        self.parent.size = newBounds.size
                    }
                }
            } else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            }
        }
    }
}
