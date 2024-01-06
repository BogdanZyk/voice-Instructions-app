//
//  CustomSlider.swift
//  Voice Instructions
//

//

import SwiftUI

struct CustomSlider<Value, Track, Fill, Thumb>: View
where Value: BinaryFloatingPoint, Value.Stride: BinaryFloatingPoint, Track: View, Fill: View, Thumb: View {
    // the value of the slider, inside `bounds`
    @Binding var value: Value
    // range to which the thumb offset is mapped
    let bounds: ClosedRange<Value>
    // tells how discretely does the value change
    let step: Value
    // left-hand label
    let minimumValueLabel: Text?
    // right-hand label
    let maximumValueLabel: Text?
    // called with `true` when sliding starts and with `false` when it stops
    let onEditingChanged: ((Bool) -> Void)?
    // the track view
    let track: () -> Track
    // the fill view
    let fill: (() -> Fill)?
    // the thumb view
    let thumb: () -> Thumb
    // tells how big the thumb is. This is here because there's no good
    // way in SwiftUI to get the thumb size at runtime, and its an important
    // to know it in order to compute its insets in the track overlay.
    let thumbSize: CGSize
    
    let isAnimate: Bool
    
    // x offset of the thumb from the track left-hand side
    @State private var xOffset: CGFloat = 0
    // last moved offset, used to decide if sliding has started
    @State private var lastOffset: CGFloat = 0
    // the size of the track view. This can be obtained at runtime.
    @State private var trackSize: CGSize = .zero
    
    @State private var isChange: Bool = false
    
    // initializer allows us to set default values for some view params
    init(value: Binding<Value>,
         in bounds: ClosedRange<Value> = 0...1,
         step: Value = 0.001,
         minimumValueLabel: Text? = nil,
         maximumValueLabel: Text? = nil,
         onEditingChanged: ((Bool) -> Void)? = nil,
         track: @escaping () -> Track,
         fill: (() -> Fill)?,
         thumb: @escaping () -> Thumb,
         thumbSize: CGSize,
         isAnimate: Bool = true) {
        _value = value
        self.bounds = bounds
        self.step = step
        self.minimumValueLabel = minimumValueLabel
        self.maximumValueLabel = maximumValueLabel
        self.onEditingChanged = onEditingChanged
        self.track = track
        self.fill = fill
        self.thumb = thumb
        self.thumbSize = thumbSize
        self.isAnimate = isAnimate
    }
    
    // where does the current value sit, percentage-wise, in the provided bounds
    private var percentage: Value {
        1 - (bounds.upperBound - value) / (bounds.upperBound - bounds.lowerBound)
    }

    var body: some View {

        HStack {
            minimumValueLabel
            
            // Represent the custom slider. ZStack overlays `fill` on top of `track`,
            // while the `thumb` is in their `overlay`.
            ZStack(alignment: .leading) {
                track()
                // get the size of the track at runtime as it
                // defines all the other functionality
                    .getSize {
                        // if this is the first time trackSize is computed,
                        // update the offset to reflect the current `value`
                        let firstInit = (trackSize == .zero)
                        trackSize = $0
                        if firstInit {
                            initOffset(isAnimation: false)
                        }
                    }
                fill?()
                // `fill` changes both its position and frame as its
                // anchor point is in its middle (at (0.5, 0.5)).
                    .frame(width: abs(xOffset) + abs(thumbSize.width), height: trackSize.height)
            }
            // make sure the entire ZStack is the same size as `track`
            .frame(width: trackSize.width, height: trackSize.height)
            // the thumb lives in the ZStack overlay
            .overlay(thumb()
                     // adjust the insets so that `thumb` doesn't sit outside the `track`
                .position(x: thumbSize.width / 2,
                          y: thumbSize.height / 2)
                     // set the size here to make sure it's really the same as the
                     // provided `thumbSize` parameter
                .frame(width: thumbSize.width, height: thumbSize.height)
                     // set the offset to, well, the stored xOffset
                .offset(x: xOffset)
                     // use the DragGesture to move the `thumb` around as adjust xOffset
                .gesture(DragGesture(minimumDistance: 0).onChanged({ gestureValue in
                    // make sure at least some dragging was done to trigger `onEditingChanged`
                    if abs(gestureValue.translation.width) < 0.1 {
                        isChange = true
                        lastOffset = xOffset
                        onEditingChanged?(isChange)
                    }
                    // update xOffset by the gesture translation, making sure it's within the view's bounds
                    let availableWidth = trackSize.width - thumbSize.width
                    xOffset = max(0, min(lastOffset + gestureValue.translation.width, availableWidth))
                    // update the value by mapping xOffset to the track width and then to the provided bounds
                    // also make sure that the value changes discretely based on the `step` para
                    let newValue = (bounds.upperBound - bounds.lowerBound) * Value(xOffset / availableWidth) + bounds.lowerBound
                    let steppedNewValue = (round(newValue / step) * step)
                    value = min(bounds.upperBound, max(bounds.lowerBound, steppedNewValue))
                }).onEnded({ _ in
                    isChange = false
                    // once the gesture ends, trigger `onEditingChanged` again
                    onEditingChanged?(isChange)
                })),
                     alignment: .leading)
            
            maximumValueLabel
        }
        // manually set the height of the entire view to account for thumb height
        .frame(height: max(trackSize.height, thumbSize.height))
        .onChange(of: value) { _ in
            if !isChange{
                initOffset(isAnimation: isAnimate)
            }
        }
        .onChange(of: trackSize) { _ in
            initOffset(isAnimation: false)
        }
    }
    
    private func initOffset(isAnimation: Bool){
        withAnimation(isAnimation ? .linear : nil){
            xOffset = (trackSize.width - thumbSize.width) * CGFloat(percentage)
        }
        lastOffset = xOffset
    }
}


struct CustomSlider_Previews: PreviewProvider {

    static var previews: some View {
        TextSliderView()
    }
}


struct TextSliderView: View{
    private let thumbRadius: CGFloat = 30
    @State private var value = 100.0
    var body: some View{
        VStack{
            Text("Custom slider: \(value)")
            CustomSlider(value: $value,
                         in: 10...255,
                         minimumValueLabel: Text("Min"),
                         maximumValueLabel: Text("Max"),
                         onEditingChanged: { started in
                print("started custom slider: \(started)")
            }, track: {
                Capsule()
                    .foregroundColor(.init(red: 0.9, green: 0.9, blue: 0.9))
                    .frame(width: 300, height: 5)
            }, fill: {
                Capsule()
                    .foregroundColor(.blue)
            }, thumb: {
                Circle()
                    .foregroundColor(.white)
                    .shadow(radius: thumbRadius / 1)
            }, thumbSize: CGSize(width: thumbRadius, height: thumbRadius))
        }
        
        .background(Color.black)
    }
}
