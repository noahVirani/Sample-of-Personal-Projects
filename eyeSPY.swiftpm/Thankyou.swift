//
//  Thankyou.swift
//  eyeSPY
//
//  Created by Noah Virani on 4/18/23.
//
import SwiftUI

struct Thankyou: View {
    
    var body: some View {
        VStack {
            VStack{
                Text("Thank You for using")
                    .bold()
                    .font(.largeTitle)
                    .multilineTextAlignment(.leading)
                Text("Eye Spy")
                    .bold()
                    .font(.largeTitle)
                    .multilineTextAlignment(.leading)
                Text("😁")
                    .font(.system(size: 80))
                    .padding(.bottom)
            }
            .padding((40))
            Image("im3")
                .resizable()
                .scaledToFit()
                .frame(width: 550.0, height: 550.0)
  
                Text("Thank You for Using Eye Spy! I hope you have had a wonderful experience, and have relieved some stress and anxiety while using this app. Feel Free to use this app anytime you feel anxious or the mood strikes. ")
                    .font(.system(size: 20))
                    .padding(.horizontal,90)
                    .padding(.vertical, 70)
                    .multilineTextAlignment(.leading)
        }
    }
}
