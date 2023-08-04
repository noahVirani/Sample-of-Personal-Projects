import SwiftUI

struct ContentView: View {
   
   
    
    
    @State var page = 0
    
    var body: some View {
        ZStack {
            Color.white
            ZStack {
                
                switch page {
                case 0:
                    Page1()
                        .frame(maxWidth: 800, alignment: .center)
                case 1:
                    Page2()
                        .frame(maxWidth: 800, alignment: .center)
                case 2:
                    Page3()
                        .frame(maxWidth: 800, alignment: .center)
                case 3:
                    Page4()
                        .frame(maxWidth: 800, alignment: .center)
                case 4:
                    Page7(seObject: "hi")
                        .frame(maxWidth: 800, alignment: .center)
                case 5:
                    CheckIn()
                        .frame(maxWidth: 800, alignment: .center)
                case 6:
                    Thankyou()
                        .frame(maxWidth: 800, alignment: .center)
                default:
                    Text("Oops you went too far, you aren't mean't to see this ")
                }
                if (page < 6 || page == 6) {
                    HStack {
                        if (page > 0 && page < 4 || page == 5) {
                            Button(action: {
                                withAnimation {
                                    page -= 1
                                }
                            }) {
                                Image(systemName: "arrow.left")
                                Text("Back")
                            }
                            .foregroundColor(Color.white)
                            .padding(.vertical, 7)
                            .padding(.horizontal)
                            .background(Color.gray)
                            .cornerRadius(17)
                            .padding(.horizontal, 10)
                            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
                        }
                        if(page == 4){
                            Button(action: {
                                withAnimation {
                                    page += 1
                                }
                            }) {
                                Text("Continue")
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(Color.white)
                            .padding(.vertical, 7)
                            .padding(.horizontal)
                            .background(Color.blue)
                            .cornerRadius(17)
                            .padding(.horizontal, 10)}
                        else if (page == 6){
                            Button(action: {
                                withAnimation {
                                    page = 0
                                }
                                
                            }) {
                                Text("Start Over")
                            }
                            .foregroundColor(Color.white)
                            .padding(.vertical, 7)
                            .padding(.horizontal)
                            .background(Color.blue)
                            .cornerRadius(17)
                            .padding(.horizontal, 10)
                        }
                        else {Button(action: {
                            withAnimation {
                                page += 1
                            }
                        }) {
                            Text("Next")
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(Color.white)
                        .padding(.vertical, 7)
                        .padding(.horizontal)
                        .background(Color.blue)
                        .cornerRadius(17)
                        .padding(.horizontal, 10)}
                        
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
                
            }
            .preferredColorScheme(.light)
        }
    }
}
