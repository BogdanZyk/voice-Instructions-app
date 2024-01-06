//
//  SingleShapeView.swift
//  Voice Instructions
//
//

import SwiftUI

struct SingleShapeView: View {
    @GestureState private var startLocation: CGPoint? = nil
    @State private var angle: Angle = .degrees(0)
    @Binding var shapeModel: DragShape
    let onSelected: () -> Void
    let onDelete: (UUID) -> Void
    
    init(shapeModel: Binding<DragShape>, onSelected: @escaping () -> Void, onDelete: @escaping (UUID) -> Void){
        self._shapeModel = shapeModel
        self.onSelected = onSelected
        self.onDelete = onDelete
    }
    
    var body: some View {

        shapeView
            .foregroundColor(shapeModel.color)
            .overlay(alignment: shapeModel.type == .circle ? .trailing : .bottomTrailing) {
                if shapeModel.isActive{
                    DragCircle(color: shapeModel.color)
                        .offset(x: 18, y: 18)
                        .gesture(sizeDragForShape)
                }
            }
            .rotationEffect(angle, anchor: .bottomLeading)
            .frame(width: shapeModel.size.width, height: shapeModel.size.height)
            .overlay(alignment: .center) {
                if shapeModel.isSelected{
                    RemoveShapeButton {
                        onDelete(shapeModel.id)
                    }
                }
            }
            .position(shapeModel.location)
            .gesture(locationDrag)
            .onTapGesture {
                if !shapeModel.isActive{
                    onSelected()
                    shapeModel.isActive = true
                }
            }
            .onLongPressGesture(minimumDuration: 1){
                if !shapeModel.isSelected{
                    onSelected()
                    shapeModel.isSelected = true
                }
            }
        
    }
    
    private var shapeView: some View{
        Group{
            if shapeModel.type == .circle{
                Circle().stroke(lineWidth: shapeModel.lineWeight)
            }else if shapeModel.type == .rectangle{
                Rectangle().stroke(lineWidth: shapeModel.lineWeight)
            }
        }
    }
    
    private var locationDrag: some Gesture {
        DragGesture()
            .updating($startLocation) { (value, startLocation, transaction) in
                if !shapeModel.isActive {return}
                startLocation = startLocation ?? shapeModel.location
            }
            .onChanged { value in
                if !shapeModel.isActive {return}
                var newLocation = startLocation ?? .zero
                newLocation.x += value.translation.width
                newLocation.y += value.translation.height
                shapeModel.location = newLocation
            }
    }
    
    private var sizeDragForShape: some Gesture{
        DragGesture()
            .onChanged { value in
                shapeModel.size.width = max(10, shapeModel.size.width + value.translation.width)
                shapeModel.size.height = max(10,    shapeModel.size.height + value.translation.height)
            }
    }
    
    private var rotateDrag: some Gesture{
        DragGesture()
            .onChanged{ v in
                let vector = CGVector(dx: v.location.x, dy: v.location.y)
                let angle = Angle(radians: Double(atan2(vector.dy, vector.dx)))
                
                self.angle = angle
            }
           
    }
}

struct SingleShapeView_Previews: PreviewProvider {
    static var previews: some View {
        
        ShapesLayerView(playerManager: VideoPlayerManager())
            .environmentObject(VideoLayerManager())
//        SingleShapeView(shapeModel: .constant(.init(type: .circle, location: .init(x: 100, y: 100), color: .red, size: .init(width: 100, height: 100))), onSelected: { }, onDelete: {_ in})
    }
}


struct RemoveShapeButton: View{
    let onPress: () -> Void
    var body: some View{
        Button {
            onPress()
        } label: {
            Text("Delete")
                .foregroundColor(.black)
                .padding(10)
                .background{
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .shadow(radius: 3)
                }
                .fixedSize()
        }
    }
}

struct DragCircle: View{
    var color: Color
    var body: some View{
        Circle()
            .stroke(color, style: .init(lineWidth: 3, dash: [5]))
            .frame(width: 36, height: 36)
            .contentShape(Circle())
    }
}
