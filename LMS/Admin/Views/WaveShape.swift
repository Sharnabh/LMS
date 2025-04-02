//
//  Waveform.swift
//  LMS
//
//  Created by Utkarsh Raj Saxena on 01/04/25.
//

import SwiftUI

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Start from the left side
        let startHeight = height * 0.43
        path.move(to: CGPoint(x: 0, y: startHeight))
        
        // Final curve to right edge
        let finalControl1 = CGPoint(x: width * 0.25, y: startHeight - 100)
        let finalControl2 = CGPoint(x: width * 0.75, y: startHeight + 150)
        let finalEnd = CGPoint(x: width, y: startHeight)
        
        path.addCurve(
            to: finalEnd,
            control1: finalControl1,
            control2: finalControl2
        )
        
        // Complete the shape
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}


#Preview {
    ZStack {
        // Background color matching the image - softer pink shade
        Color(red: 247/255, green: 167/255, blue: 171/255)
            .ignoresSafeArea()
        
        
        VStack {
            Spacer()
            WaveShape()
                .fill(.white)
                .frame(height: UIScreen.main.bounds.height * 3.0)
        }
    }
}
