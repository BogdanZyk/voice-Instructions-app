//
//  ToolDropdownMenu.swift
//  Voice Instructions
//
//

import SwiftUI

struct ToolDropdownMenu: View {
    @State private var isOpenColor: Bool = false
    @State private var isOpenTool: Bool = false
    @State private var tools = ToolEnum.allCases.map({Tool(type: $0)})
    @Binding var selectedTool: ToolEnum?
    @Binding var selectedColor: Color
    @Namespace private var animation
    let colors: [Color] = [.red, .yellow, .green, .cyan, .blue, .white]
    
    var onOpen: ((Bool) -> Void)?
    
    private let buttonWidth: CGFloat = Constants.toolWidth
    
    var body: some View {
    
        HStack(alignment: .top){
            if isOpenColor{
                toolColor
            }
            toolView
        }
        .animation(.spring(), value: isOpenColor)
        .onChange(of: isOpenTool) { newValue in
            onOpen?(newValue)
            if isOpenColor && !isOpenTool{
                isOpenColor = false
            }
        }
    }
}

struct ToolDropdownMenu_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.secondary
            ToolDropdownMenu(selectedTool: .constant(.angle), selectedColor: .constant(.red))
                .vTop()
        }
    }
}

extension ToolDropdownMenu{
    
    
    private var toolView: some View{
        VStack(spacing: 10) {
            Image(systemName: isOpenTool || selectedTool != nil ? "xmark" : "pencil")
                .font(.title3.weight(.bold))
                .onTapGesture {
                    if selectedTool != nil{
                        selectedTool = nil
                        isOpenColor = false
                    }else{
                        isOpenTool.toggle()
                    }
                }
            
            if let selectedTool, !isOpenTool{
                toolCell(selectedTool)
                    .onTapGesture {
                        isOpenColor.toggle()
                    }
                chevronDownButton
            }
            if isOpenTool{
                ForEach(tools) { tool in
                    toolCell(tool.type)
                        .onTapGesture {
                            if selectedTool == tool.type{
                                isOpenColor.toggle()
                            }else{
                                selectedTool = tool.type
                            }
                        }
                }
                chevronDownButton
            }
        }
        .frame(width: buttonWidth)
        .padding(.vertical, 15)
        .background{
            Capsule()
                .fill(Color.toolBg)
        }
        .foregroundColor(.white)
        .animation(.spring(), value: isOpenTool)
        .animation(.spring(), value: selectedTool)
    }
    
    private var toolColor: some View{
        HStack{
            ForEach(colors, id: \.self) { color in
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                    .onTapGesture {
                        selectedColor = color
                        isOpenColor = false
                    }
            }
        }
        .frame(height: buttonWidth)
        .padding(.horizontal, 15)
        .background{
            Capsule()
                .fill(Color.toolBg)
        }
    }
    
    private func toolCell(_ toolType: ToolEnum) -> some View{
        Image(systemName: toolType.image)
            .font(.title3.bold())
            .foregroundColor(toolType.iconColor)
            .padding(.vertical, 4)
            .hCenter()
            .overlay(alignment: .leading) {
                if toolType == selectedTool{
                    Image(systemName: "arrowtriangle.left.fill")
                        .matchedGeometryEffect(id: "CellIcon", in: animation)
                        .font(.system(size: 10))
                }
            }
    }
    
    private var chevronDownButton: some View{
        Image(systemName: isOpenTool ? "chevron.up" : "chevron.down")
            .font(.body.bold())
            .padding(.top, 10)
            .onTapGesture {
                isOpenTool.toggle()
            }
    }
    
    struct Tool: Identifiable{
        var id: Int { type.rawValue }
        var type: ToolEnum
        var isAnimate: Bool = false
    }
    
    enum ToolState: Int{
        case open, openFold, closeFolder
    }
}
