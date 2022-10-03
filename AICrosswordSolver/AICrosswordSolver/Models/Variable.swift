import Foundation

class Variable:Equatable,Hashable{
    let i:Int
    let j:Int
    let direction:Direction
    let length:Int
    var cells = [(Int,Int)]()
    
    enum Direction:String{
        case ACROSS = "Across"
        case DOWN = "Down"
    }
    
    static func == (lhs: Variable, rhs: Variable) -> Bool {
        return (lhs.i == rhs.i) && (lhs.j == rhs.j) && (lhs.direction == rhs.direction) && (lhs.length == rhs.length)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.i)
        hasher.combine(self.j)
        hasher.combine(self.direction)
        hasher.combine(self.length)
    }
               
    init(i:Int, j:Int, direction:Direction, length:Int){
        self.i = i
        self.j = j
        self.direction = direction
        self.length = length
        for k in 0..<length{
            if direction == .DOWN{
                self.cells.append((self.i+k, self.j))
            }else{
                self.cells.append((self.i, self.j+k))
            }
        }
    }
}
