//
//  AdviceWidget.swift
//  AdviceWidget
//
//  Created by Arin Asawa on 3/19/21.
//

import WidgetKit
import SwiftUI
import Combine

public enum AppGroup: String {
  case advice = "group.com.arinasawa.storedAdviceData"

  public var containerURL: URL {
    switch self {
    case .advice:
      return FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: self.rawValue)!
    }
  }
}


class NetworkManager{
    func saveAdviceSlip(_ slip:Slip){
        let encoder = JSONEncoder()
        let url = AppGroup.advice.containerURL.appendingPathComponent("SavedAdvice")
        if let encodedData = try? encoder.encode(slip){
           try? encodedData.write(to: url)
        }
        
    }
    
   
    
    func getAdviceOfDay(completion: @escaping(Slip) -> Void
    ){
        let url = URL(string: "https://api.adviceslip.com/advice")!
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data{
                if let decodedData = try? JSONDecoder().decode(Slip.self, from: data){
                    completion(decodedData)
                    self.saveAdviceSlip(decodedData)
                    UserDefaults(suiteName: AppGroup.advice.rawValue)?.setValue(Provider.date2string(date: Date()), forKey: "date")
                    return
                }
            }
            completion(Slip(advice: Advice(id: 0, text: "Error Fetching Advice!")))
        }
        .resume()
    }
}

struct Provider: TimelineProvider {
    let networkManager = NetworkManager()
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
    static func date2string(date:Date)->String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        return dateFormatter.string(from: Date())
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), adviceSlip: .previewData)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        if let storedAdviceSlip = storedAdviceSlip(){
            let entry = SimpleEntry(date: Date(), adviceSlip: storedAdviceSlip)
            completion(entry)
        }else{
            networkManager.getAdviceOfDay { (slip) in
                let entry = SimpleEntry(date: Date(), adviceSlip: slip)
                completion(entry)
            }
        }
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        if let storedAdviceSlip = storedAdviceSlip(){
            if ((UserDefaults(suiteName: AppGroup.advice.rawValue)?.value(forKey: "date") as! String) == Provider.date2string(date: Date())){
                let entry = SimpleEntry(date: Date(), adviceSlip: storedAdviceSlip)
                let timeline = Timeline(entries: [entry], policy: .after(Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!))
                completion(timeline)
                return
            }
        }
            networkManager.getAdviceOfDay { (slip) in
                let entry = SimpleEntry(date: Date(), adviceSlip: slip)
                let timeline = Timeline(entries: [entry], policy: .after(Calendar.current.date(byAdding: .hour, value: 24, to: Date())!))
                completion(timeline)
            }
        
    }
}



struct SimpleEntry: TimelineEntry {
    let date: Date
    let adviceSlip:Slip
}
struct Advice:Codable{
    var id:Int
    var text:String
    
    enum CodingKeys:String,CodingKey{
        case id = "id"
        case text = "advice"
    }
}

struct Slip:Codable{
    var advice:Advice
    enum CodingKeys:String,CodingKey{
        case advice = "slip"
    }
    
    static let previewData = Slip(advice: Advice(id: 1 , text: "Testing Advice..."))
}

struct AdviceWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.white, .red]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .center){
                Text(entry.adviceSlip.advice.text)
                        .italic()
                        .bold()
                        .font(.title2)
                        .padding()
            }
        }
    }
}

@main
struct AdviceWidget: Widget {
    let kind: String = "AdviceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AdviceWidgetEntryView(entry: entry) .environment(\.colorScheme, .light)

        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemMedium])
    }
}

struct AdviceWidget_Previews: PreviewProvider {
    static var previews: some View {
        AdviceWidgetEntryView(entry: SimpleEntry(date: Date(), adviceSlip: .previewData))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

