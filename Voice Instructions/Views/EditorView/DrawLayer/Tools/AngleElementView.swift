//
//  AngleElementView.swift
//  Voice Instructions
//
//

import SwiftUI

struct AngleElementView: View {
    @GestureState private var startLocation: CGPoint? = nil
    @State private var dragLocation: CGPoint? = nil
    @Binding var angleModel: AngleModel
    
    let onSelected: () -> Void
    let onRemove: (UUID) -> Void
    
    var angleBetweenLines: Double{
        let degree = angleModel.angleBetweenLines().rad2deg()
        
        return degree > 181 ? degree - 360 : degree
    }
    
    var degFirstLine: Double{
        atan2(angleModel.endPointFirstLine.y - angleModel.location.y, angleModel.endPointFirstLine.x - angleModel.location.x).rad2deg()
    }
    
    var degSecondLine: Double{
        atan2(angleModel.endPointSecondLine.y - angleModel.location.y, angleModel.endPointSecondLine.x - angleModel.location.x).rad2deg()
    }
    
    var body: some View {
        ZStack{
            LineShape(startPoint: angleModel.location, endPoint: angleModel.endPointFirstLine, isArrow: false)
                .stroke(angleModel.color, lineWidth: angleModel.lineWeight)
                .overlay {
                    dragView(isFirstLine: true)
                }
            
            LineShape(startPoint: angleModel.location, endPoint: angleModel.endPointSecondLine, isArrow: false)
                .stroke(angleModel.color, lineWidth: angleModel.lineWeight)
                .overlay {
                    dragView(isFirstLine: false)
                }
            
            AngledCircle(angle: angleBetweenLines)
                .stroke(angleModel.color, style: .init(lineWidth: 3))
                .rotationEffect(.degrees(angleBetweenLines < 0 ? degSecondLine : degFirstLine), anchor: .center)
                .frame(width: 35, height: 35)
                .overlay(alignment: .top) {
                    if angleModel.isSelected{
                        RemoveShapeButton {
                           onRemove(angleModel.id)
                        }
                        .offset(y: -25)
                    }
                }
                .position(angleModel.location)
                .overlay {
                    Text("\(Int(abs(angleBetweenLines)))°")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(Color.black.opacity(0.6), in: Capsule())
                        .position(.init(x: (angleModel.location.x + angleModel.endPointFirstLine.x + angleModel.endPointSecondLine.x) / 3, y:  (angleModel.location.y + angleModel.endPointFirstLine.y + angleModel.endPointSecondLine.y) / 3))
                    
                }
        }
        .positionOptionally(dragLocation)
        .gesture(locationDrag)
        .onTapGesture {
            if !angleModel.isActive{
                onSelected()
                angleModel.isActive = true
            }
        }
        .onLongPressGesture(minimumDuration: 1){
            if !angleModel.isSelected{
                onSelected()
                angleModel.isSelected = true
            }
        }
    }
}

struct AngleElementView_Previews: PreviewProvider {
    static var previews: some View {
        AngleElementView(angleModel: .constant(AngleModel(location: .init(x: 150, y: 150), color: .green)), onSelected: {}, onRemove: {_ in})
    }
}




extension AngleElementView{
    
    @ViewBuilder
    private func dragView(isFirstLine: Bool) -> some View{
        if angleModel.isActive{
            DragCircle(color: angleModel.color)
                .position(isFirstLine ? angleModel.endPointFirstLine : angleModel.endPointSecondLine)
                .gesture(dragForPoint(isFirstLine: isFirstLine))
        }
    }
    
    
    private func dragForPoint(isFirstLine: Bool) -> some Gesture{
        DragGesture()
            .onChanged { value in
                if isFirstLine{
                    angleModel.endPointFirstLine = value.location
                }else{
                    angleModel.endPointSecondLine = value.location
                }
            }
    }
    
    private var locationDrag: some Gesture {
        DragGesture()
            .updating($startLocation) { (value, startLocation, transaction) in
                if !angleModel.isActive {return}
                startLocation = startLocation ?? value.location
            }
            .onChanged { value in
                if !angleModel.isActive {return}
                var newLocation = startLocation ?? value.location
                newLocation.x += value.translation.width
                newLocation.y += value.translation.height
                dragLocation = newLocation
            }
    }
}

extension AngleElementView{
    struct AngledCircle: Shape {
        var angle: Double
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = max(rect.width, rect.height) / 2
            let newDegrees = angle > 0 ? 360 - angle : angle
            path.addArc(center: center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(newDegrees), clockwise: true)
            
            return path
        }
    }
}






