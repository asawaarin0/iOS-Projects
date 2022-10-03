import Foundation

struct Crossword{
    var structure:[[Bool]]
    var words:[String]
    var width:Int
    var height:Int
    var variables = Array<Variable>()
    var overlaps = [Variable:[Variable:(Int, Int)]]()
    init(structure:[[CrosswordBox]], wordSet:WordSet){
        self.structure = structure.map({$0.map({$0.containsLetter})})
        self.words = wordSet.words
        self.width = self.structure[0].count
        self.height = structure.count
        //determine the variables of the crossword/optimization problem
        
        for i in 0..<self.height{
            for j in 0..<self.width{
                //vertical words
                var starts_word:Bool = self.structure[i][j] && (i == 0 || !self.structure[i-1][j])
                if starts_word{
                    var length = 1
                    for k in (i+1)..<self.height{
                        if self.structure[k][j]{
                            length += 1
                        }else{
                            break
                        }
                    }
                    if length > 1{
                        self.variables.append(Variable(i: i, j: j, direction: .DOWN, length: length))
                    }
                }
                //horizontal words
            starts_word = self.structure[i][j] && (j == 0 || !self.structure[i][j-1])
                if starts_word{
                    var length = 1
                    for k in (j+1)..<self.width{
                        if self.structure[i][k]{
                            length += 1
                        }else{
                            break
                        }
                    }
                    if length > 1{
                        self.variables.append(Variable(i: i, j: j, direction: .ACROSS, length: length))
                    }
                }
            }
        }
        //calculate the overlaps
        for v1 in self.variables{
            for v2 in self.variables{
                if v1 == v2{
                    continue
                }
                let cells1 = v1.cells
                let cells2 = v2.cells
                let intersection = cells1.filter { cell1 in
                    cells2.contains { cell2 in
                        cell1 == cell2
                    }
                }
                if !intersection.isEmpty{
                    if self.overlaps[v1] == nil{
                        self.overlaps[v1] = [v2: (cells1.firstIndex(where: { cell in
                            cell == intersection[0]
                        })!,cells2.firstIndex(where: { cell in
                            cell == intersection[0]
                        })!)]
                    }else{
                        self.overlaps[v1]?[v2] = (cells1.firstIndex(where: { cell in
                            cell == intersection[0]
                        })!,cells2.firstIndex(where: { cell in
                            cell == intersection[0]
                        })!)
                    }
                }
            }
        }
        
}
    
    func neighbors(variable:Variable)->[Variable]{
        var neighbors = [Variable]()
        for otherVariable in self.variables{
            if overlaps[otherVariable]?[variable] != nil{
                neighbors.append(otherVariable)
            }
        }
        return neighbors
    }
}
