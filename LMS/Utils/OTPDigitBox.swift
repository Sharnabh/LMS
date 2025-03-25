//
//  OTPDigitBox.swift
//  LMS
//
//  Created by Sharnabh on 25/03/25.
//

import SwiftUI

struct OTPDigitBox: View {
    let index: Int
    @Binding var otp: String
    var onTap: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                .frame(width: 45, height: 55)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground)))
            
            if index < otp.count {
                let digit = String(Array(otp)[index])
                Text(digit)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(index < otp.count ? Color.blue : Color.clear, lineWidth: 1.5)
        )
        .animation(.spring(response: 0.2), value: otp.count)
        .onTapGesture {
            onTap()
        }
    }
}
