//
//  ShapesLayerView.swift
//  Voice Instructions
//
//

import SwiftUI

struct ShapesLayerView: View {
    @ObservedObject var playerManager: VideoPlayerManager
    @EnvironmentObject var layerManager: VideoLayerManager
    var body: some View {
        ZStack{

            ///Needed to determine dragGesture
            Color.white.opacity(0.0001)
            
            /// shapes
            shapesLayer
            
            /// polyLines
            polyLineLayer
            
            /// angles
            anglesLayer

            /// timers
            timersLayer
            
        }
        .gesture(dragGesture)
    }
}


struct ShapesLayerView_Previews: PreviewProvider {
    static var previews: some View {
        ShapesLayerView(playerManager: VideoPlayerManager())
            .environmentObject(VideoLayerManager())
    }
}


extension ShapesLayerView{
    
    private var shapesLayer: some View{
        ForEach($layerManager.shapes) { shape in

            if shape.wrappedValue.isShapeType{

                SingleShapeView(shapeModel: shape,
                                onSelected:  layerManager.deactivateAllObjects,
                                onDelete: layerManager.removeShape)
            }else{
                SingleLineShape(shape: shape,
                                onSelected:  layerManager.deactivateAllObjects,
                                onDelete: layerManager.removeShape)
            }
        }
    }
    
    private var polyLineLayer: some View{
        ForEach(layerManager.strokes){ stroke in
            Path(curving: stroke.points)
                .stroke(style: .init(lineWidth: stroke.width, lineCap: .round, lineJoin: .round))
                .foregroundColor(stroke.color)
        }
    }
    
    private var anglesLayer: some View{
        ForEach($layerManager.angles){angle in
            AngleElementView(angleModel: angle, onSelected: layerManager.deactivateAllObjects, onRemove: layerManager.removeAngle)
        }
    }
    
    private var timersLayer: some View{
        ForEach($layerManager.timers) { timer in
            TimerView(currentTime: playerManager.currentTime, timer: timer, onSelected: layerManager.deactivateAllObjects, onRemove: layerManager.removeTimer)
        }
    }
    
    private var dragGesture: some Gesture{
        DragGesture(minimumDistance: 0)
            .onChanged(layerManager.onChangeDragLayer)
            .onEnded{
                layerManager.onEndedDragLayer(value: $0, currentTime: playerManager.currentTime)
            }
    }
}
