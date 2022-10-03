//
//  CrosswordStructureViewController.swift
//  AICrosswordSolver
//
//  Created by Arin Asawa on 7/13/22.
//

import UIKit

class CrosswordStructureViewController: UIViewController{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    var loadingIndicatorView:UIActivityIndicatorView!
    var noSolutionLabel:UILabel!
    var cancelButton:UIButton!
    var solvingOperation:OperationQueue?
    var solution:[Variable:String]?
    var wordSet:WordSet?{
        didSet{
            if wordSet != nil{
                startSolving()
            }
        }
    }
    private let sectionInsets = UIEdgeInsets(
        top: 10.0,
        left: 15,
        bottom: 10.0,
        right: 15)

    var structure = [[CrosswordBox]]()
    let numberOfRows = 8
    let itemsInEachRow = 6
    let reuseIdentifier = "crosswordCell"
    var nextButtonIsEnabled:Bool{
        var containsVariable = false
        var allVariablesLengthSatisfactory = true
        for (i, row) in structure.enumerated(){
            for (j, element) in row.enumerated(){
                if element.containsLetter{
                    //ensure that there is one cell next to it that is selected
                    let nearbyCellCoordinates = [(i+1, j), (i-1, j), (i, j+1), (i,j-1)]
                    var hasAtLeastOneCellNearby = false
                    for coordinate in nearbyCellCoordinates{
                        if (coordinate.0 > -1 && coordinate.0 < numberOfRows) && (coordinate.1 > -1 && coordinate.1 < itemsInEachRow){
                            if structure[coordinate.0][coordinate.1].containsLetter{
                                containsVariable = true
                                hasAtLeastOneCellNearby = true
                                break
                            }
                        }
                    }
                    if !hasAtLeastOneCellNearby{
                        allVariablesLengthSatisfactory = false
                    }
                }
        }
        }
        return containsVariable && allVariablesLengthSatisfactory
    }
 
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeCrosswordStructure()
        nextButton.isEnabled = false
        collectionView.dataSource = self
        self.loadingIndicatorView = createLoadingIndicator(color: .green)
        self.noSolutionLabel = createNoSolutionLabel()
        self.cancelButton = createCancelButton()
        self.cancelButton.addTarget(self, action: #selector(didPressCancelButton(button:)), for: .touchUpInside)
    }
    
    @objc func didPressCancelButton(button:UIButton){
        if let operation = self.solvingOperation{
            operation.cancelAllOperations()
        }
        self.removeLoadingScreen()
        self.didClickResetButton(resetButton)
    }
    
    func initializeCrosswordStructure(){
        for _ in 0..<numberOfRows{
            var row = [CrosswordBox]()
            for _ in 0..<itemsInEachRow{
                row.append(CrosswordBox(containsLetter: false, letter: nil))
            }
            structure.append(row)
        }
    }

    @IBAction func didClickResetButton(_ sender: UIButton) {
        solution = nil
        //remove no solution label if it is in superview
        if noSolutionLabel.isDescendant(of: self.view){
            self.noSolutionLabel.removeFromSuperview()
        }
        //show collection view
        self.collectionView.isHidden = false
        //remove current wordset
        wordSet = nil
        //make the next button visible again
        nextButton.isHidden = false
        //reset the navigation item title
        self.navigationItem.title = "Select Crossword Structure"
        //reset the crossword structure
        for i in 0..<numberOfRows{
            for j in 0..<itemsInEachRow{
                structure[i][j].containsLetter = false
                structure[i][j].letter = nil
            }
        }
        collectionView.reloadData()
        //disable next button
        nextButton.isEnabled = false
    }
    
    func setUpLoadingScreen(){
        //hide all UI elements
        nextButton.isHidden = true
        resetButton.isHidden = true
        self.collectionView.isHidden = true
        //change navigation item title to one that reflects the fact that the puzzle is being solved
        self.navigationItem.title = "Solution"
        loadingIndicatorView.startAnimating()
        self.view.addSubview(loadingIndicatorView)
        loadingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicatorView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        loadingIndicatorView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        //add cancel button to superview
        self.view.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.topAnchor.constraint(equalTo: loadingIndicatorView.bottomAnchor, constant: 50).isActive = true
        cancelButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
    }
    func removeLoadingScreen(){
        self.loadingIndicatorView.removeFromSuperview()
        self.cancelButton.removeFromSuperview()
        self.resetButton.isHidden = false
    }
    func displaySolution(){
        for variable in self.solution!.keys{
            var i = 0
            let word = solution![variable]!
            //loop through each corresponding cell in crossword structure and fill it in
            while i<variable.cells.count{
                let cell = variable.cells[i]
                self.structure[cell.0][cell.1].letter =                     word[word.index(word.startIndex, offsetBy: i)]
                i += 1
            }
        }
        self.collectionView.reloadData()
        UIView.transition(with: self.collectionView, duration: 1.5, options: .transitionCurlDown) {
            self.collectionView.isHidden = false
        }

    }
    func displayNoSolutionLabel(){
        self.view.addSubview(noSolutionLabel)
        noSolutionLabel.translatesAutoresizingMaskIntoConstraints = false
        noSolutionLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        noSolutionLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        noSolutionLabel.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.7).isActive = true
    }
    func  startSolving(){
        setUpLoadingScreen()
        let queue = OperationQueue()
        self.solvingOperation = queue
        let partOneOperation = BlockOperation()
        partOneOperation.addExecutionBlock {
            let crossword = Crossword(structure: self.structure, wordSet: self.wordSet!)
            var crosswordCreator = CrosswordCreator(crossword: crossword, operation:partOneOperation)
            if let solution = crosswordCreator.solve(){
                self.solution = solution
            }
        }
        let partTwoOperation = BlockOperation{
            DispatchQueue.main.async {
                if self.solution != nil{
                    self.displaySolution()
                }else{
                    self.displayNoSolutionLabel()
                }
                self.removeLoadingScreen()
            }
        }
        
        partTwoOperation.addDependency(partOneOperation)
        DispatchQueue.global().async {
            queue.addOperation(partOneOperation)
            queue.addOperation(partTwoOperation)
        }
    }

    func createLoadingIndicator(color:UIColor)->UIActivityIndicatorView{
        let loadingIndicator = UIActivityIndicatorView()
        loadingIndicator.style = .large
        loadingIndicator.color = color
        return loadingIndicator
    }
    
    func createNoSolutionLabel()->UILabel{
        let noSolutionLabel = UILabel()
        noSolutionLabel.text = "No solution found to the crossword puzzle :("
        noSolutionLabel.font = noSolutionLabel.font.withSize(25)
        noSolutionLabel.numberOfLines = 2
        noSolutionLabel.textAlignment = .center
        return noSolutionLabel
    }
    func createCancelButton()->UIButton{
        let button = UIButton()
        button.backgroundColor = .orange
        button.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 10
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Cancel"
        configuration.titlePadding = 10
        configuration.baseForegroundColor = .white
        configuration.buttonSize = .medium
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 25)
            return outgoing
        })
        button.configuration = configuration
        return button
    }

}


extension CrosswordStructureViewController:UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return structure.count
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return structure[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CrosswordBoxCell
        let crosswordBox = structure[indexPath.section][indexPath.row]
        cell.backgroundColor = crosswordBox.containsLetter == false ? .gray : .white
        cell.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        cell.layer.borderWidth = 2
        cell.isUserInteractionEnabled = solution == nil
        if let letter = crosswordBox.letter{
            cell.label.text = String(letter).uppercased()
            cell.label.textColor = .black
            cell.label.isHidden = false
        }else{
            cell.label.isHidden = true
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * CGFloat((itemsInEachRow+1))
        let availableWidth = collectionView.frame.width - paddingSpace
        let widthPerItem = availableWidth/CGFloat(itemsInEachRow)
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
  
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        structure[indexPath.section][indexPath.row].containsLetter = !structure[indexPath.section][indexPath.row].containsLetter
        nextButton.isEnabled = nextButtonIsEnabled
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        collectionView.reloadItems(at: [indexPath])
    }
    
}


