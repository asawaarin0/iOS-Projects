//
//  ContentView.swift
//  Advice
//
//  Created by Arin Asawa on 3/19/21.
//

import SwiftUI
import Combine
import WidgetKit

struct AdviceView: View {
    @State var tasks = [AnyCancellable]()
    @State var advice = "Loading.."
    var body: some View {
        NavigationView{
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.white, .red]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                VStack(alignment: .center){
                        Text(advice)
                            .italic()
                            .bold()
                            .font(.title)
                            .padding(.trailing)
                            .padding(.leading)
                            .padding(.bottom)
                    Button(action: {
                        playHaptic()
                        self.advice = "Loading..."
                       fetchAdvice()
                    }, label: {
                        Text("Get New Advice")
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    })
                    
                    .foregroundColor(.red)
                }
                .navigationBarTitle(Text("Advice Of The Day"))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear{
                loadAdviceOfTheDay()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)){_ in
            DispatchQueue.main.async {
                loadAdviceOfTheDay()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)){_ in
            DispatchQueue.main.async {
                loadAdviceOfTheDay()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged), perform: { _ in
            DispatchQueue.main.async {
                loadAdviceOfTheDay()
            }
        })
    }
    
    
        func loadAdviceOfTheDay(){
            if let storedSlip = storedAdviceSlip(){
                if ( UserDefaults(suiteName: AppGroup.advice.rawValue)?.value(forKey: "date") as! String) != date2string(date: Date()){
                    fetchAdvice()
                }else{
                    self.advice = storedSlip.advice.text
                }
            }else{
                fetchAdvice()
            }
        }

        func fetchAdvice(){
            advicePublisher().receive(on: RunLoop.main).sink { (slip) in
                    self.tasks.removeAll()
                    self.advice = slip.advice.text
                    saveAdviceSlip(slip)
                UserDefaults(suiteName: AppGroup.advice.rawValue)?.setValue(date2string(date: Date()), forKey: "date")
                WidgetCenter.shared.reloadAllTimelines()
                
                }
                .store(in: &tasks)
        }

        
        func saveAdviceSlip(_ slip:Slip){
            let encoder = JSONEncoder()
            let url = AppGroup.advice.containerURL.appendingPathComponent("SavedAdvice")
            if let encodedData = try? encoder.encode(slip){
               try? encodedData.write(to: url)
            }
            
        }

        func storedAdviceSlip()->Slip?{
            let decoder = JSONDecoder()
            let url = AppGroup.advice.containerURL.appendingPathComponent("SavedAdvice")
            if let data = try? Data(contentsOf: url){
                if let slip = try? decoder.decode(Slip.self, from: data){
                    return slip
                }
            }
            
            return nil
        }
        
        func advicePublisher()->AnyPublisher<Slip,Never>{
           return  URLSession.shared.dataTaskPublisher(for: URL(string: "https://api.adviceslip.com/advice")!)
            .map{$0.data}
                .decode(type: Slip.self, decoder: JSONDecoder())
            .catch {error in
                Just(Slip(advice:Advice(id:0, text: "Error! Please check your internet connection and try again..")))
            }
            .eraseToAnyPublisher()
                
        }

        func playHaptic(){
            let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
        }

        func date2string(date:Date)->String{
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            return dateFormatter.string(from: Date())
        }

}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AdviceView()
    }
}
