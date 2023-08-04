//
//  CheckIn.swift
//  eyeSPY
//
//  Created by Noah Virani on 4/19/23.
//


import SwiftUI
import Speech
import AVFoundation
import Vision
import NaturalLanguage

struct CheckIn: View {
    @State var flag = false
    @StateObject var speechRecognizer = SpeechRecognizer()
    @State var count = 0
    @State var vibeFlag = false
    @State var vibe = false
    @State var currentSentiment: Double = 0;
    
    func processSentiment(text: String) {
        
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let sentiment = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore).0
        currentSentiment = Double(sentiment?.rawValue ?? "0") ?? 0;
        if (currentSentiment > 0.1){
            vibe = true
        } else {
            vibe = false
        }
    }
    
    var body: some View {
            VStack{
                Text("Check In Time!")
                    .bold()
                    .font(.largeTitle)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 60)
         
                Text("🧐")
                    .font(.system(size: 100))
                
                Text("Let's check in to see how you're doing! after you press the button, say something that you are grateful for! we will use a handy dandy NLP model to see if the vibes are good enough! Otherwise we reccomend you go back to Eye Spying (TM)")
                    .font(.system(size: 20))
                    .padding(.horizontal,90)
                    .multilineTextAlignment(.leading)
                    .padding(.vertical,10)
                Text("Feel feel to skip this section if it isn't your thing")
                    .font(.system(size: 20))
                    .padding(.horizontal,80)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                VStack{
                    Text("What You Are Grateful For:")
                        .bold()
                        .font(.largeTitle)
                        .multilineTextAlignment(.leading)
                        .padding(10)
                    
                    Text(count == 0 ? "What you say will go here!":speechRecognizer.transcript)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .padding(40)
                    
                    Button(action: {
                        withAnimation {
                            if flag == false{
                                self.flag = true
                                count += 1
                                speechRecognizer.resetTranscript()
                                speechRecognizer.startTranscribing()
                            }
                            else {
                                self.flag = false
                                       speechRecognizer.stopTranscribing()
                            }
                        }
                    }) {
                        if flag == false {
                            Text("Start Recording")}
                        else {
                            Text("Stop Recording")
                        }
                    }
                    .foregroundColor(Color.white)
                    .padding(.vertical, 7)
                    .padding(.horizontal)
                    .background(flag ? .gray : .red)
                    .cornerRadius(17)
                    .padding(.horizontal, 10)
                
                    
                }
                .frame(maxWidth: 650, maxHeight: 300, alignment: .center)
                .background(.thinMaterial)
                .cornerRadius(30)
                .padding(40)
                
                if (count != 0){
                    Button(action: {
                        withAnimation {
                            if (vibeFlag == false){
                                
                                vibeFlag = true
                            }
                            processSentiment(text: speechRecognizer.transcript)
                            
                        }
                    }) {
                        Text(vibeFlag ? (vibe ? "Vibe Check passed!": "Vibe Check failed, try again!") : "Press here for a Vibe Check!")
                            .bold()
                    }
                    .foregroundColor(Color.white)
                    .frame(maxWidth: 250, maxHeight: 50, alignment: .center)
                    .padding(.vertical, 7)
                    .padding(.horizontal)
                    .background(vibeFlag ? (vibe ? .green: .red) : .blue)
                    .cornerRadius(25)
                    .padding(.horizontal, 10)
                
                    
                }
                
               
                Spacer()
               Spacer()
         
            }
        }
}


