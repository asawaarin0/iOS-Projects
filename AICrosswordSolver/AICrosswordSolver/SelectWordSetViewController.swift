//
//  SelectWordSetViewController.swift
//  AICrosswordSolver
//
//  Created by Arin Asawa on 7/13/22.
//

import UIKit

class SelectWordSetViewController: UIViewController{
    var wordSets = [WordSet(name: "Default Word Set #1", words: AppDelegate.words)]
    var selectedWordSet:WordSet? = nil
    var onTapSolve:((WordSet)->Void)?
    @IBOutlet weak var solveButton: UIButton!
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isModalInPresentation = true
        solveButton.isEnabled = false
        self.navigationItem.title = "Select Word Set"
        //add a cancel button to the left of the navbar button
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(didPressCancel))
        
    }
    
    @IBAction func didPressSolveButton(_ sender: UIButton) {
        if let presentingViewController = presentingViewController as?
            UINavigationController{
            if let crosswordStructureVC = presentingViewController.viewControllers.first as? CrosswordStructureViewController{
                crosswordStructureVC.wordSet = selectedWordSet
                self.dismiss(animated: true)
            }
        }
    }
    @objc func didPressCancel(){
        self.dismiss(animated: true)
    }
    
}


extension SelectWordSetViewController:UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wordSets.count
    }
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let detailViewController = storyboard.instantiateViewController(withIdentifier: "wordSetDetail") as! WordSetDetailTableViewController
        detailViewController.wordSet = self.wordSets[indexPath.row]
        self.navigationController?.pushViewController(detailViewController, animated: true)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wordSetCell", for: indexPath)
        var contentConfiguration = cell.defaultContentConfiguration()
        contentConfiguration.text = wordSets[indexPath.row].name
        cell.contentConfiguration = contentConfiguration
        cell.accessoryType = .detailButton
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedWordSet = wordSets[indexPath.row]
        solveButton.isEnabled = true
    }
    
}
