//
//  Page7.swift
//  eyeSPY
//
//  Created by Noah Virani on 4/18/23.
//
import SwiftUI
import AVFoundation

struct Page7: View {
    
    @State var personCount: Int = 0
    @State var points: Int = 0
    @State var currObject: String = "Apple"
    @State var seObject: String
    @State var flag: Int = 0
    @State var won: Bool = false
    
    init(seObject: String) {
        self.seObject = inside.randomElement()!
       }
    
    
    let inside = ["person", "bicycle", "car", "stop-sign", "bench", "dog", "backpack", "tie", "bottle", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple", "sandwich", "bed", "sofa", "diningtable", "laptop", "mouse", "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "book", "clock", "vase", "scissors", "toothbrush", "pottedplant", "chair", "orannge", "pizza" ]
   
    @State var musicFlag = false
    @State var audioPlayer: AVAudioPlayer!
    
    
    func tts(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    
    var body: some View {
        
        ZStack(alignment: .top) {
            CameraView(score: $points, lObject: $currObject, sObject: $seObject, win: $won)
                .frame(maxWidth: .infinity, maxHeight: 1050, alignment: .top)
                .cornerRadius(30)
            
            VStack {
                Text("Go out and Eye Spy! when you are ready feel free to hit next")
                    .font(.system(size: 25))
                    .bold()
                Button(action: {
                    withAnimation {
                        if (musicFlag == false){
                            musicFlag = true
                            self.audioPlayer.play()
                        }
                        else{
                            self.audioPlayer.pause()
                            musicFlag = false
                        }
                        
                        
                    }
                }) {
                    Text(musicFlag ? "Stop Forrest Sounds" : "Play Forrest Sounds")
                }
                .foregroundColor(Color.white)
                .padding(.vertical, 7)
                .padding(.horizontal)
                .background(Color.blue)
                .cornerRadius(17)
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
                .onAppear(){
                    let sound = Bundle.main.path(forResource: "stream", ofType: "mp3")
                    self.audioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
                    
                }
                
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(25)
            .frame(alignment: .top)
            .padding(.top, 20)
            
            ZStack(alignment: .bottomLeading) {
                
                VStack {
                    Text("Searching For: \(seObject)")
                        .font(.system(size: 25))
                        .bold()
                    Text("Currently in Camera: \(currObject)")
                        .font(.system(size: 18))
                        .bold()

                    
                    HStack{
                        Button(action: {
                            withAnimation {
                                seObject = inside.randomElement()!
                            }
                        }) {
                            Text("I can't find this")
                        }
                        .foregroundColor(Color.white)
                        .padding(.vertical, 7)
                        .padding(.horizontal)
                        .background(Color.gray)
                        .cornerRadius(17)
                        .padding(.horizontal, 10)
                        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
                        
                        
                        
                        Button(action: {
                            withAnimation {
                                seObject = inside.randomElement()!
                                won = true
                                points = points + 1
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
                                                   // To change the time, change 0.2 seconds above
                                won = false
                                }
                                
                            }
                        }) {
                            Text("Found it! the Model's Wrong")
                        }
                        .foregroundColor(Color.white)
                        .padding(.vertical, 7)
                        .padding(.horizontal)
                        .background(Color.blue)
                        .cornerRadius(17)
                        .padding(.horizontal, 10)
                        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
                        
                    }
                    .padding(.vertical, 7)
                    
                }
                .padding(.horizontal, 35)
                .padding(.vertical, 55)
                .background(.ultraThinMaterial)
                .cornerRadius(15)
            }
            .padding(.leading, 20)

            
            .frame(maxWidth: .infinity, maxHeight: 1020, alignment: .bottomLeading)
            
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    Text("Score")
                        .font(.system(size: 25))
                        .bold()
                        .padding(.horizontal)
                    Text("\(points)")
                        .bold()
                        .font(.system(size: 50))
                        .padding(.horizontal)
                }
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .padding(.trailing, 30)
                .padding(.bottom, 130)
            if(won == true){
                ZStack{
                    Color.green
                    VStack{
                        Text("Awesome! You Got One!")
                            .bold()
                            .font(.system(size: 60))
                        .foregroundColor(.white)
                        Text("🥳")
                            .bold()
                            .font(.system(size: 60))
                        
                    }
                }
                    .cornerRadius(40)
            }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            
        }
            
            
    }
}
