//
//  HorizontalDialPickerDemo.swift
//  Artin
//
//  Created by Alvin Phyo Htet on 17/11/26.
//

import SwiftUI

struct HorizontalDialPickerDemo: View {
    @State private var value: Double = 0
        
        var body: some View {
            NavigationStack {
                VStack(spacing: 24) {
                    Text("Selected Value: \(String(format: "%.2f", value))")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HorizontalDialPicker(value: $value, range: 0...100, step: 1.0)
                }
                .navigationTitle("Horizontal Dial!")
            }
        }
}

#Preview {
    HorizontalDialPickerDemo()
}


struct HorizontalDialPicker<V>: View where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {
    
    @Binding var value: V
    var range: ClosedRange<V>
    var step: V
    
    var tickSpacing: CGFloat = 8.0
    
    @State private var scrollPosition: Int? = nil
    
    var body: some View {
        ScrollView(.horizontal, content: {
            let totalTicks = Int((range.upperBound - range.lowerBound) / step) + 1

            HStack(spacing: tickSpacing) {

                ForEach(0..<totalTicks, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.gray)
                        .frame(width: 2, height: 24)
                        .id(index)
                }
                
            }
            .scrollTargetLayout()
            .padding(.vertical, 16) // to extend the scrollable area vertically

        })
        .onAppear {
            self.scrollPosition = Int(value / step - range.lowerBound)
        }
        // using initial: true cannot replace onAppear
        // ie: will not set the correct initial position
        .onChange(of: value) {
            self.scrollPosition = Int(value / step - range.lowerBound)
        }
        .scrollTargetBehavior(.viewAligned(anchor: .center))
        .scrollIndicators(.hidden)
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .defaultScrollAnchor(.center, for: .alignment)
        .defaultScrollAnchor(.center, for: .initialOffset)
        .defaultScrollAnchor(.center, for: .sizeChanges)
        .onChange(of: scrollPosition, {
            guard let scrollPosition = self.scrollPosition else { return }
            value = range.lowerBound + V(scrollPosition) * step
        })
    }
}


#Preview(body: {
    HorizontalDialPickerDemo()
})

