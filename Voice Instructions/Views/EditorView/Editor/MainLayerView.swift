//
//  MainLayerView.swift
//  Voice Instructions
//
//

import SwiftUI

struct MainLayerView: View {
    @ObservedObject var playerManager: VideoPlayerManager
    @EnvironmentObject var layerManager: VideoLayerManager

    var body: some View {
    
        GeometryReader { proxy in
            let newLayerSize = getSize(proxy)
            ZStack{
                PlayerRepresentable(size: $layerManager.layerSize, player: playerManager.videoPlayer)
                DrawVideoLayer(playerManager: playerManager, layerSize: newLayerSize)
                    .environmentObject(layerManager)
            }
            .maskOptionally(isActive: layerManager.layerSize != .zero) {
                Rectangle()
                    .frame(size: newLayerSize)
                    .blendMode(.destinationOver)
            }
        }
        .ignoresSafeArea()
    }
}

struct MainLayerView_Previews: PreviewProvider {
    static var previews: some View {
        MainLayerView(playerManager: VideoPlayerManager())
            .environmentObject(VideoLayerManager())
    }
}

extension MainLayerView{
    
    
    private func getSize(_ proxy: GeometryProxy) -> CGSize{
        .init(
            width: layerManager.layerSize.width > proxy.size.width ? proxy.size.width : layerManager.layerSize.width,
            height: layerManager.layerSize.height > proxy.size.height ? proxy.size.height : layerManager.layerSize.height
        )
    }
}

