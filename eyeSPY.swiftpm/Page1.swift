//
//  Page1.swift
//  eyeSPY
//
//  Created by Noah Virani on 4/17/23.
//

import SwiftUI

struct Page1: View {
    
    var body: some View {
        VStack {
            VStack{
                Text("Welcome to")
                    .bold()
                    .font(.largeTitle)
                    .multilineTextAlignment(.leading)
                Text("Eye Spy")
                    .bold()
                    .font(.largeTitle)
                    .multilineTextAlignment(.leading)
                Text("👀")
                    .font(.system(size: 80))
                    .padding(.bottom)
            }
            .padding((40))
            Image("im1")
                .resizable()
                .scaledToFit()
                .frame(width: 550.0, height: 550.0)
  
            
    
                Text("Eye Spy is an app that promotes mindfullness and presence through technology, using Machine Learning as a Game to help us all find our inner peace")
                    .font(.system(size: 20))
                    .padding(.horizontal,90)
                    .padding(.vertical, 70)
                    .multilineTextAlignment(.leading)
        }
    }
}
