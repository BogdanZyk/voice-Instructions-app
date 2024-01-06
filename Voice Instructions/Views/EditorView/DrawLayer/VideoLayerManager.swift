//
//  VideoLayerManager.swift
//  Voice Instructions
//
//

import SwiftUI

class VideoLayerManager: ObservableObject {
   
    ///Video layer size
    @Published var layerSize: CGSize = .zero
    
    ///Selected color for tool
    @Published var selectedColor: Color = .red
    @Published var selectedTool: ToolEnum?
    
    ///free lines
    @Published private(set) var strokes = [Stroke]()
    
    /// shapes circle and rectangle
    @Published var shapes = [DragShape]()
    private var currentShape: DragShape?
    
    /// timers
    @Published var timers = [TimerModel]()
    
    ///angles
    @Published var angles = [AngleModel]()
    
    var undoManager: UndoManager?
    
    
    var isActiveTool: Bool{
        selectedTool != nil
    }
  
    var undoIsActive: Bool{
        undoManager?.canUndo ?? false
    }
    
    var isEmptyLayer: Bool{
        strokes.isEmpty && shapes.isEmpty && timers.isEmpty && angles.isEmpty
    }
    
    /// undo method
    /// delete the last change
    func undo() {
        objectWillChange.send()
        undoManager?.undo()
    }
    
    /// Adding an shape object to a layer when onChanged gesture
    func onChangeDragLayer(value: DragGesture.Value){
        guard !isActiveAnyObject else {return}
        if selectedTool == .polyLine{
            createOrUpdatePolyLine(value)
        }else if selectedTool?.isShapeTool ?? false{
            createOrUpdateShape(value)
        }
    }
    
    /// Adding an shape object to a layer when onEnded gesture
    /// Deactivate all objects if needed
    /// Reset selected shape
    func onEndedDragLayer(value: DragGesture.Value, currentTime: Double){
        currentShape = nil
        if isActiveAnyObject{
            deactivateAllObjects()
            return
        }
        if selectedTool == .timer{
            addTimer(value, activateTime: currentTime)
        }else if selectedTool == .angle{
            addAngle(value)
        }
    }
    
    /// Delete all objects on layer
    func removeAll(){
        removeAllPolyLines()
        removeAllShapes()
        removeAllTimers()
        removeAllAngles()
    }
    
    /// Reset all states
    func resetAll(){
        removeAll()
        selectedTool = nil
        selectedColor = .red
    }
    
    /// At least one object in the layer is active
    var isActiveAnyObject: Bool{
        shapes.contains(where: {$0.isActive || $0.isSelected}) ||
        timers.contains(where: {$0.isActive || $0.isSelected}) ||
        angles.contains(where: {$0.isActive || $0.isSelected})
    }
    
    /// Deactivate all objects on the layer
    func deactivateAllObjects(){
        guard isActiveAnyObject else {return}
        shapes.indices.forEach({shapes[$0].deactivate()})
        timers.indices.forEach({timers[$0].deactivate()})
        angles.indices.forEach({angles[$0].deactivate()})
    }
}

//MARK: - PolyLine logic

extension VideoLayerManager{
    
    /// Create or update a polyLine
    private func createOrUpdatePolyLine(_ value: DragGesture.Value){
        let point = value.location
        
        if value.translation.width + value.translation.height == 0{
            addPolyLineWithUndo()
        }else{
            updatePolyLinePoints(point)
        }
    }
    
    private func removeAllPolyLines(){
        strokes.removeAll()
    }
    
    /// Add polyLine and register undo action
    private func addPolyLineWithUndo(){
        undoManager?.registerUndo(withTarget: self) { manager in
            manager.removeLastPolyLine()
        }
        strokes.append(Stroke(color: selectedColor))
    }
    
    private func removeLastPolyLine(){
        guard !strokes.isEmpty else {return}
        strokes.removeLast()
    }
    
    /// Update last polyLine points
    private func updatePolyLinePoints(_ point: CGPoint){
        guard !strokes.isEmpty else {return}
        strokes[strokes.count - 1].points.append(point)
    }
}

//MARK: - Shapes logic
extension VideoLayerManager{
    
    /// Create or update a shape (lines, rectangle circle, arrow)
    private func createOrUpdateShape(_ value: DragGesture.Value){
        
        let point = value.location
        
        let width = abs(value.translation.width * 1.5)
        let height = abs(value.translation.height * 1.5)
        let sum = width + height
        
        if sum > 0, currentShape == nil{
            addShapeWithUndo(point)
        }else{
            updateShape(width: width, height: height, point)
        }
    }
    
    func removeShape(_ id: UUID){
        shapes.removeAll(where: {$0.id == id})
    }
    
    /// Add shape and register undo action
    private func addShapeWithUndo(_ location: CGPoint){
        guard let type = selectedTool?.shapeType else {return}
        let newShape = DragShape(type: type,
                                 location: location,
                                 color: selectedColor,
                                 size: .init(width: 20, height: 20),
                                 endLocation: location)
        self.currentShape = newShape
        undoManager?.registerUndo(withTarget: self) { manager in
            manager.removeLastShape()
        }
        shapes.append(newShape)
    }
    
    /// Update shape if needed
    private func updateShape(width: CGFloat, height: CGFloat, _ location: CGPoint){
        guard !shapes.isEmpty, let index = shapes.firstIndex(where: {$0.id == currentShape?.id}) else {return}
        if shapes[index].isShapeType {
            if width > 10 && height > 10{
                shapes[index].size = .init(width: width, height: height)
            }
        }else{
            shapes[index].endLocation = location
        }
    }
    
    private func removeLastShape(){
        guard !shapes.isEmpty else {return}
        shapes.removeLast()
    }
    
    private func removeAllShapes(){
        shapes.removeAll()
    }
}

//MARK: - Timers logic
extension VideoLayerManager{
    
    /// Add timer for activate time
    private func addTimer(_ value: DragGesture.Value, activateTime: Double){
        let point = value.location
        let timer = TimerModel(location: point, activateTime: activateTime, color: selectedColor)
        undoManager?.registerUndo(withTarget: self) { manager in
            manager.removeLastTimer()
        }
        timers.append(timer)
    }
    
    func removeTimer(_ id: UUID){
        timers.removeAll(where: {$0.id == id})
    }
    
    private func removeLastTimer(){
        guard !timers.isEmpty else {return}
        timers.removeLast()
    }
    
    private func removeAllTimers(){
        timers.removeAll()
    }
}

//MARK: - Angles logic
extension VideoLayerManager{
    
    /// Create and angle in layer
    private func addAngle(_ value: DragGesture.Value){
        let point = value.location
        let angle = AngleModel(location: point, color: selectedColor)
        undoManager?.registerUndo(withTarget: self) { manager in
            manager.removeLastAngle()
        }
        angles.append(angle)
    }
    
    func removeAngle(_ id: UUID){
        angles.removeAll(where: {$0.id == id})
    }
    
    private func removeLastAngle(){
        guard !angles.isEmpty else {return}
        angles.removeLast()
    }
    
    private func removeAllAngles(){
        angles.removeAll()
    }
}
