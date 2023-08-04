//
//  Page4.swift
//  eyeSPY
//
//  Created by Noah Virani on 4/17/23.
//
//
//  Page1.swift
//  eyeSPY
//
//  Created by Noah Virani on 4/17/23.
//

import SwiftUI

struct Page4: View {
    
    var body: some View {
        VStack {
            VStack{
                Text("Introducing EyeSpy")
                    .bold()
                    .font(.largeTitle)
                    .multilineTextAlignment(.leading)
            }
            .padding((40))
            Image("im2")
                .resizable()
                .scaledToFit()
                .frame(width: 550.0, height: 550.0)
  
            
    
                Text("Using Eye Spy is simple, we'll give you a list of everyday objects (either inside or outside) and your job is to walk and find them and earn a point every time you do so. ")
                    .font(.system(size: 20))
                    .padding(.horizontal,90)
                    .multilineTextAlignment(.leading)
                    .padding(.vertical,10)
            Text("Take as much time as you need. There's no timer and no pressure. We'll even play some relaxing sounds.")
                    .font(.system(size: 20))
                    .padding(.horizontal,80)
                    .multilineTextAlignment(.leading)
        }
    }
}
