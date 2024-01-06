//
//  EditorView.swift
//  Voice Instructions
//
//

import SwiftUI
import PhotosUI
import AVKit

struct EditorView: View {
    @Environment(\.undoManager) var undoManager
    @StateObject var layerManager = VideoLayerManager()
    @StateObject var playerManager = VideoPlayerManager(fromStorage: true)
    @StateObject var recorderManager = ScreenRecorderManager()
    var body: some View {
        ZStack{
            Color.black.ignoresSafeArea()
            switch playerManager.loadState{
            case .loading:
                ProgressView()
            case .loaded:
                playerLayers
            case .unknown, .failed:
                pickerButton
            }
            loaderView
        }
        .fullScreenCover(isPresented: $recorderManager.showPreview) {
            VideoPreview(video: recorderManager.finalVideo.value)
        }
        .onChange(of: playerManager.selectedItem, perform: setVideo)
        .onAppear{
            layerManager.undoManager = undoManager
        }
    }
}

struct EditorView_Previews: PreviewProvider {
    @StateObject static var playerManager = VideoPlayerManager()
    static var previews: some View {
        EditorView(playerManager: playerManager)
    }
}


extension EditorView{
    
    
    
    private var playerLayers: some View{
        VStack(spacing: 0) {
            navBarView
            MainLayerView(playerManager: playerManager)
                .environmentObject(layerManager)
                .padding(.horizontal, Constants.toolWidth + Constants.horizontalPrimaryPadding)
                .padding(.bottom, Constants.bottomVideoPadding)
            bottomControlsView
        }
        .overlay {
            TopLayerControlsView(layerManager: layerManager, playerManager: playerManager)
                .padding(.vertical, 20)
                .padding(.top)
        }
    }
    
    private var pickerButton: some View{
        PhotosPicker("Pick Video",
                     selection: $playerManager.selectedItem,
                     matching: .videos,
                     photoLibrary: .shared())
        .foregroundColor(.white)
    }

}


extension EditorView{
    
    @ViewBuilder
    private var navBarView: some View{
        if playerManager.loadState == .loaded{
            TopBarView(layerManager: layerManager, recorderManager: recorderManager, playerManager: playerManager)
        }
    }
    
    @ViewBuilder
    private var bottomControlsView: some View{
        if let video = playerManager.video, playerManager.loadState == .loaded{
            VideoControlsView(playerManager: playerManager, video: video)
        }
    }
}

extension EditorView{
    private func setVideo(_ item: PhotosPickerItem?){
         Task{
            await playerManager.loadVideoItem(item)
         }
     }
    
    @ViewBuilder
    private var loaderView: some View{
        if recorderManager.showLoader{
            ZStack{
                Color.black.opacity(0.2)
                VStack{
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.black)
                }
                .frame(width: 100, height: 100)
                .background(Color(uiColor: .systemGray))
                .cornerRadius(12)
            }
        }
    }
}
