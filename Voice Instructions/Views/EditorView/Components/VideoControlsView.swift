//
//  VideoControlsView.swift
//  Voice Instructions
//
//

import SwiftUI

struct VideoControlsView: View {
    @ObservedObject var playerManager: VideoPlayerManager
    var video: Video
    private let thumbRadius: CGFloat = 30
    var body: some View {
        VStack(spacing: 0){
            timeSlider
                .padding(.horizontal, Constants.horizontalPrimaryPadding)
            HStack(spacing: 16) {
                ScrubbingBarView(duration: playerManager.video?.totalDuration ?? 60, time: $playerManager.currentTime, onChangeTime: seek)
                    .padding(.horizontal, 40)
                    .onTapGesture {
                        playerManager.action()
                    }
            }
            .padding(.horizontal, Constants.horizontalPrimaryPadding)
            .padding(.trailing)
            .overlay {
                HStack{
                    playPauseButton
                    Spacer()
                }
            }
        }
    }
}

struct VideoControlsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack{
            Color.secondary
            VideoControlsView(playerManager: VideoPlayerManager(), video: .mock)
        }
    }
}

extension VideoControlsView{
    
    
    private var playPauseButton: some View{
        Button {
            playerManager.action()
        } label: {
            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(.white)
        }
        .padding(.horizontal)
    }
    
    private func seek(_ time: Double){
        playerManager.scrubState = .scrubEnded(time)
    }
    
    private var timeSlider: some View{
        
        GeometryReader { proxy in
            CustomSlider(value: Binding(get: {
                playerManager.currentTime
            }, set: { newValue in
                playerManager.currentTime = newValue
                seek(newValue)
            }),
                         in: video.rangeDuration,
                         step: 0.003,
                         onEditingChanged: { started in
                if started{
                    playerManager.scrubState = .scrubStarted
                }
            }, track: {
                Capsule()
                    .foregroundColor(.init(red: 0.9, green: 0.9, blue: 0.9))
                    .frame(width: proxy.size.width, height: 5)
            }, fill: {
                Capsule()
                    .foregroundColor(.red)
            }, thumb: {
                Circle()
                    .foregroundColor(.white)
                    .overlay {
                        Text(playerManager.currentTime.humanReadableLongTime())
                            .font(.system(size: 14))
                            .fixedSize()
                            .foregroundColor(.white)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 4)
                            .monospaced()
                            .background(Color.black.opacity(0.25), in: Capsule())
                            .offset(y: -30)
                    }
            }, thumbSize:
                    .init(width: 20, height: 20)
            )
        }
        .frame(height: 30)
    }
}





