//
//  VideoPreview.swift
//  Voice Instructions
//
//

import SwiftUI

struct VideoPreview: View {
    @Environment(\.dismiss) private var dismiss
    @State private var rangeDuration: ClosedRange<Double>
    @StateObject private var viewModel = VideoPreviewViewModel()
    @StateObject private var playerManager = VideoPlayerManager()
    private var video: Video?
    
    init(video: Video?){
        self.video = video
        self._rangeDuration = State(wrappedValue: video?.rangeDuration ?? 0...1)
    }

    var body: some View {
        ZStack{
            if let video{
                GeometryReader { proxy in
                    VStack(spacing: 0) {
                        if playerManager.loadState == .loaded{
                            PlayerRepresentable(size: .constant(.zero), player: playerManager.videoPlayer)
                        }else{
                            Spacer()
                        }
                        controlsSection(proxy)
                    }
                    .onAppear{
                        viewModel.setVideo(video: video, size: proxy.size)
                        playerManager.loadVideo(video)
                    }
                }
            }
            if viewModel.showLoader{
                loaderView
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            header
        }
        .preferredColorScheme(.dark)
    }
}

struct VideoPreview_Previews: PreviewProvider {
    static var previews: some View {
        VideoPreview(video: nil)
    }
}

extension VideoPreview{
    private var header: some View{
        Text("Video preview")
            .font(.title3.bold())
            .padding()
    }
    
    private func controlsSection(_ proxy: GeometryProxy) -> some View{
        VStack{
            
            if let video = viewModel.video, playerManager.loadState == .loaded {
                VideoTrimBarView(videoRange: video.rangeDuration,
                                 thumbnailsImages: viewModel.thumbnailsImages,
                                 editedRange: $rangeDuration,
                                 currentTime: $playerManager.currentTime,
                                 onTapTrim: {
                    playerManager.action(rangeDuration)
                }, seek: playerManager.seek)
                .padding(.horizontal)
                .padding(.top)
            }
            
            Button {
                playerManager.action(rangeDuration)
            } label: {
                Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 25)
                    .foregroundColor(.white)
            }
            .hCenter()
            .padding(.top, 5)
            .overlay {
                HStack{
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                    Spacer()
                    Button {
                        Task{
                            await viewModel.save(rangeDuration)
                        }
                    } label: {
                        Text("Save")
                    }
                }
                .foregroundColor(.white)
                .font(.title3.weight(.medium))
            }
            
        }
        .padding([.horizontal, .top])
    }
    
    private func setOnChangeTrim(_ video: Video){
        playerManager.currentTime = video.rangeDuration.upperBound
        playerManager.seek(playerManager.currentTime)
    }
    
    @ViewBuilder
    private func thumbnailsImagesSection(_ proxy: GeometryProxy) -> some View{
        HStack(spacing: 0){
            ForEach(viewModel.thumbnailsImages) { trimData in
                if let image = trimData.image{
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 70)
                        .clipped()
                }
            }
        }
        .cornerRadius(5)
        .onTapGesture {
            playerManager.action(rangeDuration)
        }
    }
        
    @ViewBuilder
    private var loaderView: some View{
        Color.black.opacity(0.2)
        VStack{
            Text("Saving video")
            ProgressView()
        }
        .padding()
        .background(Color(uiColor: .systemGray5), in: RoundedRectangle(cornerRadius: 10))
    }
}

