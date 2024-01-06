//
//  SingleLineShape.swift
//  Voice Instructions
//
//

import SwiftUI

struct SingleLineShape: View {
    @GestureState private var startLocation: CGPoint? = nil
    @State var location: CGPoint? = nil
    @Binding var shape: DragShape
    let onSelected: () -> Void
    let onDelete: (UUID) -> Void
    var body: some View {
        
        LineShape(startPoint: shape.startLocation, endPoint: shape.endLocation, isArrow: shape.type == .arrow)
            .stroke(shape.color, lineWidth: shape.lineWeight)
            .overlay {
                if shape.isActive{
                    DragCircle(color: shape.color)
                        .position(shape.startLocation)
                        .gesture(dragForPoint(isStartPoint: true))
                    
                    DragCircle(color: shape.color)
                        .position(shape.endLocation)
                        .gesture(dragForPoint(isStartPoint: false))
                }
            }
            .overlay(alignment: .topTrailing) {
                if shape.isSelected{
                    RemoveShapeButton {
                        onDelete(shape.id)
                    }
                    .position(shape.endLocation)
                }
            }
            .padding(10)
            .gesture(locationDrag)
            .onTapGesture {
                if !shape.isActive{
                    onSelected()
                    shape.isActive = true
                }
            }
            .onLongPressGesture(minimumDuration: 1){
                if !shape.isSelected{
                    onSelected()
                    shape.isSelected = true
                }
            }
    }

}

struct SingleLineShape_Previews: PreviewProvider {
    static var previews: some View {
        
//        ShapesLayerView()
//            .environmentObject(VideoLayerManager())
        
        VStack {
            SingleLineShape(shape: .constant(.init(type: .line, location: .init(x: 50, y: 450), color: .red, endLocation: .init(x: 100, y: 100))), onSelected: {}, onDelete: {_ in})
            SingleLineShape(shape: .constant(.init(type: .arrow, location: .init(x: 50, y: 250), color: .red, endLocation: .init(x: 100, y: 100))), onSelected: {}, onDelete: {_ in})
        }
    }
}


extension SingleLineShape{
    
    private var locationDrag: some Gesture {
        DragGesture()
            .updating($startLocation) { (value, startLocation, transaction) in
                if !shape.isActive {return}
                startLocation = startLocation ?? value.location
            }
            .onChanged { value in
                if !shape.isActive {return}
                var newLocation = startLocation ?? .zero
                newLocation.x += value.translation.width
                newLocation.y += value.translation.height
                location = newLocation
            }
    }
    
    private func dragForPoint(isStartPoint: Bool) -> some Gesture{
        DragGesture()
            .onChanged { value in
                if isStartPoint{
                    shape.startLocation = value.location
                }else{
                    shape.endLocation = value.location
                }
            }
    }
}

struct LineShape: Shape {
    var startPoint: CGPoint
    var endPoint: CGPoint
    var isArrow: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        
        
        if isArrow{
            
            let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
            let arrowLength: CGFloat = 20
            let arrowWidth: CGFloat = 4

            let endPoint1 = CGPoint(x: endPoint.x - arrowLength * cos(angle) + arrowWidth * cos(angle + .pi/2), y: endPoint.y - arrowLength * sin(angle) + arrowWidth * sin(angle + .pi/2))
            let endPoint2 = CGPoint(x: endPoint.x - arrowLength * cos(angle) + arrowWidth * cos(angle - .pi/2), y: endPoint.y - arrowLength * sin(angle) + arrowWidth * sin(angle - .pi/2))

            path.addLine(to: endPoint1)
            path.move(to: endPoint)
            path.addLine(to: endPoint2)
        }

        return path
    }
}


struct Triangle: Shape {
    var angle: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tipPoint = CGPoint(x: rect.maxX, y: rect.midY)
        let basePoint1 = CGPoint(x: rect.minX, y: rect.minY)
        let basePoint2 = CGPoint(x: rect.minX, y: rect.maxY)
        
        path.move(to: tipPoint)
        path.addLine(to: basePoint1)
        path.addLine(to: basePoint2)
        path.addLine(to: tipPoint)
        path = path.applying(CGAffineTransform(rotationAngle: angle))
        return path
    }
}

