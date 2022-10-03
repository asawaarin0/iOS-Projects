import Foundation

struct CrosswordCreator{
    var crossword:Crossword
    var domains=[Variable:[String]]()
    let operation:BlockOperation
    init(crossword:Crossword, operation:BlockOperation){
        self.crossword = crossword
        self.operation = operation
        //initialize domains for all variables
        for variable in self.crossword.variables{
            domains[variable] = self.crossword.words
        }
    }
    
    mutating func solve()->[Variable:String]?{
        self.enforce_node_consistency()
        guard ac3() else {return nil}
        return self.backtrack(assignment: [Variable:String]())
    }
    
    mutating func enforce_node_consistency(){
        for variable in self.domains.keys{
            self.domains[variable] = self.domains[variable]?.filter({$0.count == variable.length
            })
        }
    }
    
    mutating func revise(x:Variable, y:Variable)->Bool{
        let overlap = self.crossword.overlaps[x]?[y]
        var revised = false
        let copyOfDomainX = self.domains[x]!
        if overlap != nil{
            for word in copyOfDomainX{
                var possibleAlternativeInDomainY = false
                for value in self.domains[y]!{
                    if word[word.index(word.startIndex, offsetBy: overlap!.0)] == value[value.index(value.startIndex, offsetBy: overlap!.1)] && (word != value){
                        possibleAlternativeInDomainY = true
                        continue
                    }
                }
                if !possibleAlternativeInDomainY{
                    self.domains[x]!.remove(at: (self.domains[x]?.firstIndex(of: word))!)
                    revised = true
                }
            }
        }
        return revised
    }
    
    mutating func ac3(arcs:[(Variable, Variable)] = [])->Bool{
        var queue = [(Variable, Variable)]()
        if arcs.isEmpty{
            for variable in self.domains.keys{
                for neighborVar in self.crossword.neighbors(variable: variable){
                    if !queue.contains(where: { arc in
                        arc == (neighborVar, variable)
                    }){
                        queue.append((variable, neighborVar))
                    }
                }
            }
        }else{
            queue = arcs
        }
        
        while queue.count != 0{
            let (x,y) = queue.removeLast()
            if self.revise(x: x, y: y){
                if self.domains[x]?.count == 0{
                    return false
                }else{
                    for neighbor in self.crossword.neighbors(variable: x){
                        if neighbor != y{
                            queue.append((neighbor, x))
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    func assignment_complete(assignment:[Variable:String])->Bool{
        if assignment.keys.count == self.domains.keys.count{
            return true
        }
        return false
    }
    
    func consistent(assignment:[Variable:String])->Bool{
        //check if neighbors have conflicting characters
        for v1 in assignment.keys{
            for v2 in assignment.keys{
                if v1 == v2{
                    continue
                }
                let word1 = assignment[v1]!
                let word2 = assignment[v2]!
                
                //making sure all assignment values are different
                if word1 == word2{

                    return false
                }
                if let overlap = self.crossword.overlaps[v1]?[v2]{
           
                
                    if word1[word1.index(word1.startIndex, offsetBy: overlap.0)] != word2[word2.index(word2.startIndex, offsetBy: overlap.1)]{
                        return false
                    }
                }
            }
        }
        return true
    }
    func orderDomainValues(variable:Variable, assignment:[Variable:String])->[String]{
        var valuesAndNumRuledOut = [(String, Int)]()
        let neighbors = self.crossword.neighbors(variable: variable).filter({!assignment.keys.contains($0)})
        for value in self.domains[variable]!{
            var numRuledOut = 0
            for neighbor in neighbors{
                for word in self.domains[neighbor]!{
                    if let overlap = self.crossword.overlaps[variable]![neighbor]{
                        if value[value.index(value.startIndex, offsetBy: overlap.0)] != word[word.index(word.startIndex, offsetBy: overlap.1)] || value == word{
                            numRuledOut += 1
                        }
                    }
                }
            }
            valuesAndNumRuledOut.append((value, numRuledOut))
        }
        valuesAndNumRuledOut.sort { pair1, pair2 in
            pair1.1 < pair2.1
        }
        return valuesAndNumRuledOut.map({$0.0})
    }
    
    func selectUnassignedVariable(assignment:[Variable:String])->Variable{
        var possibleVariables = self.domains.keys.filter({!assignment.keys.contains($0)})
        if possibleVariables.count == 1{
            return possibleVariables[0]
        }
        possibleVariables.sort { v1, v2 in
            self.domains[v1]!.count < self.domains[v2]!.count
        }
        if self.domains[possibleVariables[0]]?.count == self.domains[possibleVariables[1]]?.count{
            //if execution reaches here, then there was a tie and thus variables should be sorted by degree in descending order
            possibleVariables.sort { v1, v2 in
                self.crossword.neighbors(variable: v1).count > self.crossword.neighbors(variable: v2).count
            }
        }
        return possibleVariables[0]
    }
    mutating func backtrack(assignment:[Variable:String])->[Variable:String]?{
        if operation.isCancelled{
            return nil
        }
        if self.assignment_complete(assignment: assignment){
            return assignment
        }
        let variable = self.selectUnassignedVariable(assignment: assignment)
        for value in self.orderDomainValues(variable: variable, assignment: assignment){
            if operation.isCancelled{
                return nil
            }
            var newAssignment = assignment
            newAssignment[variable] = value
            if self.consistent(assignment: newAssignment){
                let domainsCopy = self.domains
                self.domains[variable] = [value]
                var arcs = [(Variable, Variable)]()
                for neighbor in self.crossword.neighbors(variable: variable){
                    arcs.append((neighbor, variable))
                }
                guard ac3() else {self.domains = domainsCopy; continue}
                let result = self.backtrack(assignment: newAssignment)
                if result != nil{
                    return result
                }
                self.domains = domainsCopy
            }
        }
        return nil
    }
    
}

