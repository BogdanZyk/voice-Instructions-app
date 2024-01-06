//
//  InfinityScrollViewData.swift
//  Voice Instructions
//
//

import SwiftUI

struct InfinityHScrollView<Content>: View where Content: View {
    var alignment: HorizontalAlignment = .center

    @GestureState var dragOffset: CGFloat = 0.0
    @State var rowWidth: CGFloat = 0.0
    @State var outerWidth: CGFloat = 0.0
    @State var xOffset: CGFloat = 0.0

    @State private var contentMultiplier = 2

    var onChange: ((CGFloat) -> Void)?
    var onEnded: ((CGFloat, CGFloat) -> Void)?

    @ViewBuilder var content: () -> Content
    
    var body: some View {
        ZStack {
            
            InnerHView(xOffset: xOffset + dragOffset, outerWidth: outerWidth, rowWidth: $rowWidth, contentMultiplier: $contentMultiplier, content: content)
                .fixedSize(horizontal: true, vertical: false)
                .frame(width: outerWidth, alignment: contentMultiplier > 1 ? .center : Alignment(horizontal: alignment, vertical: .center))
                .clipped()
                .gesture(
                    DragGesture()
                        .updating($dragOffset, body: { dragValue, dragOffset, transaction in
                            dragOffset = dragValue.translation.width
                        })
                        .onEnded({ dragValue in
                            guard contentMultiplier == 2 else {
                                return
                            }
                            let width = dragValue.translation.width
                            let projectedWidth = dragValue.predictedEndTranslation.width
                            xOffset = xOffset + width
                            let duration = projectedWidth / (4 * width)
                            let dragValue = (projectedWidth - width)
                            
                            withAnimation(.easeOut(duration: duration)) {
                                xOffset = xOffset + dragValue
                            }
                            onEnded?(dragValue, duration)
                        })
                )
                .onChange(of: contentMultiplier) { newValue in
                    //TODO: fix issue when aligning in infinite mode, only center works now
                    // alignment does work when not enough content to scroll
                    if newValue == 1 {
                        switch alignment {
                            case .leading:
                                xOffset = contentMultiplier > 1 ? -(outerWidth / 2) : 0
                            case .trailing:
                                xOffset = contentMultiplier > 1 ? (outerWidth / 2) : 0
                            default:
                                xOffset = 0
                        }
                    }
                }

            // never seen, just to grab the width of the outer view
            HStack {
                GeometryReader { proxy in
                    let _ = setWidth(proxy.size.width)
                    Color.clear
                }
                Spacer()
            }
            .onChange(of: dragOffset) { newValue in
                onChange?(newValue)
            }
        }
    }

    func setWidth(_ width: CGFloat) -> Bool {
        if width != self.outerWidth {
            DispatchQueue.main.async {
                self.outerWidth = width
            }
        }
        return true
    }
    

    private struct InnerHView: View, Animatable {
        var xOffset: CGFloat
        var outerWidth: CGFloat
        @Binding var rowWidth: CGFloat
        @Binding var contentMultiplier: Int
        @ViewBuilder var content: Content

        var animatableData: CGFloat {
            get { xOffset }
            set { xOffset = newValue}
        }

        var body: some View {
            HStack(spacing: 0) {
                ForEach (0..<contentMultiplier, id: \.self) { _ in
                    content
                }
            }
            .background(GeometryReader { proxy in
                let _ = setWidth(proxy.size.width)
                Color.clear
            })
            .offset(x: contentMultiplier > 1 ? xOffset.remainder(dividingBy: 1600 / 2) : xOffset, y: 0)
        }

        func setWidth(_ width: CGFloat) -> Bool {
            if outerWidth > 0, width > 0 {
                DispatchQueue.main.async {
                    self.rowWidth = width
                    self.contentMultiplier = outerWidth < (rowWidth / CGFloat(contentMultiplier)) ? 2 : 1
                }
            }
            return true
        }
    }
}

struct InfinteHScrollView_Previews: PreviewProvider {
    static var previews: some View {
        
        
        InfinityHScrollView {
            ForEach(0..<8, id: \.self) { index in
                PersonView(index: index)
            }
        }
    }

    struct PersonView: View {
        static let colors: [Color] = [.yellow, .green, .red, .blue, .purple, .orange, .gray, .indigo]
        let index: Int

        var body: some View {
            Image(systemName: "person")
                .resizable()
                .padding(20)
                .frame(width: 100, height: 100)
                .background(Self.colors[index % Self.colors.count])
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

