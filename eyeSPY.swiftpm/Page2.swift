//
//  Page2.swift
//  eyeSPY
//
//  Created by Noah Virani on 4/17/23.
//
import SwiftUI

struct Page2: View {
    
    var body: some View {
        
            VStack {
                Text("😨")
                    .padding(.bottom)
                    .font(.system(size: 100))
                Text("According to the ADAA, anxiety and traumatic stress affect 40 million adults. Whether it be daily stress or even being on the verge of panic attacks, we can always find it hard to calm down.")
                    .font(.system(size: 25))
                    .padding(.horizontal, 90)
                    .multilineTextAlignment(.center)
            }
    }
}
