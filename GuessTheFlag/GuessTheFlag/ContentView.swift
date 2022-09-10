import SwiftUI
/// An animatable modifier that is used for observing animations for a given animatable value.
struct AnimationCompletionObserverModifier<Value>: AnimatableModifier where Value: VectorArithmetic {

    /// While animating, SwiftUI changes the old input value to the new target value using this property. This value is set to the old value until the animation completes.
    var animatableData: Value {
        didSet {
            notifyCompletionIfFinished()
        }
    }

    /// The target value for which we're observing. This value is directly set once the animation starts. During animation, `animatableData` will hold the oldValue and is only updated to the target value once the animation completes.
    private var targetValue: Value

    /// The completion callback which is called once the animation completes.
    private var completion: () -> Void

    init(observedValue: Value, completion: @escaping () -> Void) {
        self.completion = completion
        self.animatableData = observedValue
        targetValue = observedValue
    }

    /// Verifies whether the current animation is finished and calls the completion callback if true.
    private func notifyCompletionIfFinished() {
        guard animatableData == targetValue else { return }

        /// Dispatching is needed to take the next runloop for the completion callback.
        /// This prevents errors like "Modifying state during view update, this will cause undefined behavior."
        DispatchQueue.main.async {
            self.completion()
        }
    }

    func body(content: Content) -> some View {
        /// We're not really modifying the view so we can directly return the original input value.
        return content
    }
}


extension View {

    /// Calls the completion handler whenever an animation on the given value completes.
    /// - Parameters:
    ///   - value: The value to observe for animations.
    ///   - completion: The completion callback to call once the animation completes.
    /// - Returns: A modified `View` instance with the observer attached.
    func onAnimationCompleted<Value: VectorArithmetic>(for value: Value, completion: @escaping () -> Void) -> ModifiedContent<Self, AnimationCompletionObserverModifier<Value>> {
        return modifier(AnimationCompletionObserverModifier(observedValue: value, completion: completion))
    }
}


import Network

struct ContentView: View {
   // @State private var countries = ["Estonia","France","Germany","Ireland","Italy","Nigeria","Poland","Russia","Spain","UK","US"].shuffled()
    @State var flags = [Flag]()
    @State private var correctAnswer = Int.random(in: 0...2)
    @State private var showingScore = false
    @State private var scoreTitle = ""
    @State private var score = 0
    @State private var rotationDegrees:Double = 0
    @State private var opacity:Double = 1
    @State private var hasInternetConnection = false
    @State private var answerTapped:(Bool,Int) = (false,0)
    @State private var ongoingTask:URLSessionDataTask?
    let monitor = NWPathMonitor()
    var body: some View {
        ZStack{
            LinearGradient(gradient: Gradient(colors: [.blue,.black]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            if hasInternetConnection == false{
                    Text("It looks like you have no Internet!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
            }else{
            if flags.count < 3{
                Text("Loading the question...")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }else{
            VStack(spacing:20){
                VStack{
                    Text("Tap the flag of")
                    Text(flags[correctAnswer].country)
                        .font(.largeTitle)
                        .fontWeight(.black)
                }
                .foregroundColor(.white)
                ForEach(0..<3){number in
                    Button(action: {self.flagTapped(number);}) {
                        ZStack{
                            FlagImage(uiImage:flags[number].flag)
                            if self.answerTapped.0 && number == self.answerTapped.1 && self.answerTapped.1 != self.correctAnswer{
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(Color.red)
                                    .font(.system(size: 60))
                                    .transition(.opacity)
                            }
                        }
                    }
                    .rotation3DEffect(.degrees(number == self.correctAnswer ? self.rotationDegrees : 0), axis: (x: 0, y: 1, z: 0))
                    .onAnimationCompleted(for: self.rotationDegrees) {
                        self.rotationDegrees = 0
                        self.showingScore = true
                    }
                    .opacity(number != self.correctAnswer ? self.opacity:1)

                }
                Text("Your Score Is \(score)")
                    .foregroundColor(Color.white)
                    .font(.body)
                    .fontWeight(.semibold)
                    .padding(.top)
               // Spacer()
            }
            .padding()
            }
            }
            
      }
        .onAppear{
            monitor.pathUpdateHandler = { path in
                if path.status == .satisfied {
                    hasInternetConnection = true
                } else {
                    hasInternetConnection = false
                    if let task = ongoingTask{
                        task.cancel()
                    }
                }

            }
            let queue = DispatchQueue(label: "Monitor")
            monitor.start(queue: queue)
            fetchCountryFlags { (result) in
                    switch result{
                    case .success(let flag):
                        self.flags.append(flag)
                    case .failure(let error):
                        print(error)
                    }
            }
        }
        .alert(isPresented: $showingScore) {
            Alert(title: Text(self.scoreTitle), message: Text("Your score is \(score)"), dismissButton: .default(Text("Ok"), action: {
                self.answerTapped.0 = false
                self.opacity = 1
                self.askQuestion()
            }))
        }
       
    }
    func flagTapped(_ number:Int){
        withAnimation{
            self.answerTapped.0 = true
            self.answerTapped.1 = number
        }
        if number == correctAnswer{
            withAnimation{
                self.rotationDegrees = 360
            }
            scoreTitle = "Correct! That is indeed the flag of \(flags[correctAnswer].country)"
            score += 1
        }else{
            scoreTitle = "Wrong! That is not the flag of \(flags[correctAnswer].country), but that of \(flags[number].country)"
            score -= 1
            showingScore = true
        }

    }
    
    func askQuestion(){
        self.flags.removeAll()
        correctAnswer = Int.random(in: 0...2)
        fetchCountryFlags { (result) in
                switch result{
                case .success(let flag):
                    self.flags.append(flag)
                case .failure(let error):
                    print(error)
                }
        }
    }
    func fetchCountryFlags(completion: @escaping (Result<Flag,Error>) -> Void){
        var randomCountryCode = NSLocale.isoCountryCodes.randomElement()
        while flags.contains(where: { (flag) -> Bool in
            flag.country == country(with: randomCountryCode!)
        }) == true{
            randomCountryCode = NSLocale.isoCountryCodes.randomElement()!
        }
        let url = URL(string: "http://www.geognos.com/api/en/countries/flag/\(randomCountryCode!).png")
      let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if let data = data{
                if let image = UIImage(data: data){
                    DispatchQueue.main.async {
                        completion(.success(Flag(country: country(with: randomCountryCode!), flag: image)))
                        if flags.count < 3{
                            fetchCountryFlags(completion: completion)
                        }else{
                            self.ongoingTask = nil
                            return
                        }
                    }
                }else{
                    fetchCountryFlags(completion: completion)
                }
            }else{
                fetchCountryFlags(completion: completion)
            }
        }
        task.resume()
        self.ongoingTask = task
    }
    
    func country(with isoCode:String)->String{
        let id = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.countryCode.rawValue: isoCode])
           return NSLocale(localeIdentifier: "en_UK").displayName(forKey: NSLocale.Key.identifier, value: id) ?? "Country not found for code: \(isoCode)"
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
