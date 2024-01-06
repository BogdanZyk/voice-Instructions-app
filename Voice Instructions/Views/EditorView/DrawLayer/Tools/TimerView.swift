//
//  TimerView.swift
//  Voice Instructions
//
//

import SwiftUI

struct TimerView: View {
    @GestureState private var startLocation: CGPoint? = nil
    var currentTime: Double
    @Binding var timer: TimerModel
    private var timerTime: Double{
        currentTime - timer.activateTime
    }
    let onSelected: () -> Void
    let onRemove: (UUID) -> Void
    var body: some View {
        
        HStack(spacing: 2){
            if timerTime < 0{
                Text("–")
            }
            Text(timerTime.timerTime())
                .monospaced()
        }
        .font(.title3)
        .foregroundColor(timer.color)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 5))
        .overlay(alignment: .top) {
            if timer.isSelected{
                RemoveShapeButton {
                    onRemove(timer.id)
                }
                .offset(y: -46)
            }
        }
        .position(timer.location)
        .gesture(positionDrag)
        .onTapGesture {
            timer.setNewTime(currentTime)
        }
        .onLongPressGesture(minimumDuration: 1){
            if !timer.isSelected{
                onSelected()
                timer.isSelected = true
            }
        }
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TimerView(currentTime: 3.45, timer: .constant(.init(location: .init(x: 100, y: 100), activateTime: 2.34, color: .red)), onSelected: {}, onRemove: {_ in})
            TimerView(currentTime: 3.45, timer: .constant(.init(location: .init(x: 150, y: 150), activateTime: 5.34, color: .green)), onSelected: {}, onRemove: {_ in})
        }
    }
}


extension TimerView{
    
    private var positionDrag: some Gesture {
        DragGesture()
            .updating($startLocation) { (value, startLocation, transaction) in
                startLocation = startLocation ?? timer.location
            }
            .onChanged { value in
                var newLocation = startLocation ?? timer.location
                newLocation.x += value.translation.width
                newLocation.y += value.translation.height
                timer.location = newLocation
                timer.isSelected = false
            }
    }
    
}

