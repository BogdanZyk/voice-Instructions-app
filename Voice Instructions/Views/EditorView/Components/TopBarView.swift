//
//  TopBarView.swift
//  Voice Instructions
//
//

import SwiftUI

struct TopBarView: View {
    @ObservedObject var layerManager: VideoLayerManager
    @ObservedObject var recorderManager: ScreenRecorderManager
    @ObservedObject var playerManager: VideoPlayerManager
    @State private var isPresentedAlert: Bool = false
    
    private var isIPad: Bool{
        UIDevice.current.isIPad
    }
    var body: some View {
        ZStack(alignment: .top){
            HStack{
                closeButton
                    .hLeading()
                    .overlay(alignment: .center) {
                        HStack(spacing: 30) {
                            if recorderManager.recorderIsActive{
                                removeRecordButton
                                stopButton
                            }
                            micButton
                        }
                    }
            }
            .padding(.top, isIPad ? 40 : 0)
            .padding(.horizontal, Constants.horizontalPrimaryPadding)
            .padding(.bottom, 20)
            .background(Color.black.opacity(0.25))
        }
        .alert("Remove video", isPresented: $isPresentedAlert) {
            Button("Cancel", role: .cancel, action: {})
            Button("Remove", role: .destructive, action: playerManager.removeVideo)
        } message: {
            Text("Are you sure you want to delete the video?")
        }
    }
}

struct NavigationBarView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.secondary.ignoresSafeArea()
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TopBarView(layerManager: VideoLayerManager(), recorderManager: ScreenRecorderManager(), playerManager: VideoPlayerManager())
        }
    }
}

extension TopBarView{
    
    @ViewBuilder
    private var closeButton: some View{
        Button {
            isPresentedAlert.toggle()
        } label: {
            buttonLabel("xmark")
        }
        .opacity(recorderManager.recorderIsActive ? 0 : 1)
        .disabled(recorderManager.recorderIsActive)
    }
    
    @ViewBuilder
    private var removeRecordButton: some View{
        Button {
            recorderManager.removeAll()
            layerManager.resetAll()
        } label: {
            buttonLabel("xmark")
        }
        .padding(.trailing, 30)
    }
    
    private var micButton: some View{
        Button {
            if recorderManager.isRecord{
                recorderManager.pause()
            }else{
                recorderManager.startRecoding()
            }
        } label: {
            buttonLabel(recorderManager.isRecord ? "pause.fill" : "mic.fill")
        }
    }
    
    private var stopButton: some View{
        Button {
            playerManager.pause()
            recorderManager.stop(videoFrameSize: layerManager.layerSize)
        } label: {
            buttonLabel("stop.fill", foregroundColor: .red)
        }
    }
    
    private func buttonLabel(_ image: String, foregroundColor: Color = .white) -> some View{
        Image(systemName: image)
            .resizable()
            .scaledToFit()
            .frame(width: 14, height: 14)
            .padding(12)
            .background(Color.white.opacity(0.1), in: Circle())
            .foregroundColor(foregroundColor)
            .bold()
        
    }
    
}
