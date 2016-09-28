import Foundation

class CSVParser {
  
  var content: String
  
  let delimiter: Character
  var lines: [String]
  var rows: [[String]]
  
  init(content: String, delimiter: Character = ",") {
    self.content = content
    self.delimiter = delimiter
    self.lines = content.lines()
    // 3?
    self.rows = Array<[String]>.init(repeating: [String].init(repeating: "", count: 3), count: self.lines.count)
  }

  convenience init(filePath: String, delimiter: Character = ",") throws {
    let fileContent = try String(contentsOfFile: filePath)
    self.init(content: fileContent, delimiter: delimiter)
  }
  
  func wirite(toFilePath path: String) throws {
    try self.lines.joined(separator: "\r\n").write(to: URL(fileURLWithPath: path), atomically: false, encoding: .utf8)
  }
  
  func concurrencyParse(handler:  @escaping ()->()) {
    let wordsInOneTime = 200
    let parseGroup = DispatchGroup()
    let writeRowQueue = DispatchQueue(label: "com.nero.writerow")
    writeRowQueue.setTarget(queue: DispatchQueue.global(qos: .default))
    for i in 0...self.lines.count / wordsInOneTime {
      let workItem = DispatchWorkItem(block: {
        let min = wordsInOneTime < (self.lines.count - i*wordsInOneTime) ? wordsInOneTime : (self.lines.count - i*wordsInOneTime)
        for j in 0..<min{
          let index = i*wordsInOneTime + j
//          self.rows[index] =
          let parsedLine = self.lines[index].words()
//          dispatch_barrier_async(<#T##queue: DispatchQueue##DispatchQueue#>, <#T##block: () -> Void##() -> Void#>)
          writeRowQueue.async(group: parseGroup, qos: .default, flags: .barrier) {
            self.rows[index] = parsedLine
          }
        }
        print("\(i) done")
      })
      DispatchQueue.global(qos: .userInitiated).async(group: parseGroup, execute: workItem)

    }
//    parseGroup.notify(queue: DispatchQueue.main, execute: handler)
    parseGroup.wait()
    handler()
  }
  
  func parse() {
    for (index, line) in self.lines.enumerated() {
      self.rows[index] = line.words()
    }
  }
  
  
}

extension String {
  
  func words(splitBy split: CharacterSet = CharacterSet(charactersIn: ",\r\n")) -> [String] {
    let quote = "\""
    var apperQuote = false
    let result = self.utf16.split(maxSplits: Int.max, omittingEmptySubsequences: false) { x in
      if quote == String(UnicodeScalar(x)!) {
        if !apperQuote {
          apperQuote = true
        }else {
          apperQuote = false
        }
      }
      if apperQuote {
        return false
      }else { 
        return split.contains(UnicodeScalar(x)!)
      }
      }.flatMap(String.init)
    return result
  }
  
  func lines(splitBy split: CharacterSet = CharacterSet(charactersIn: "\r\n")) -> [String] {
    let quote = "\""
    var apperQuote = false
    let result = self.utf16.split(maxSplits: Int.max, omittingEmptySubsequences: false) { x in
      if quote == String(UnicodeScalar(x)!) {
        if !apperQuote {
          apperQuote = true
        }else {
          apperQuote = false
        }
      }
      if apperQuote {
        return false
      }else {
        return split.contains(UnicodeScalar(x)!)
      }
      }.flatMap(String.init)
    return result
  }
  
}

struct CSVParserIterator: IteratorProtocol {
  
  typealias Element = [String]
  
  let delimiter: Character
  let lines: [String]
  var linesIterator: IndexingIterator<[String]>
  
  init(lines: [String], delimiter: Character) {
    self.lines = lines
    self.delimiter = delimiter
    self.linesIterator = self.lines.makeIterator()
  }
  
  
  public mutating func next() -> [String]? {
    return self.linesIterator.next().map{ $0.words() }
  }
  
}

extension CSVParser: Sequence {
  public func makeIterator() -> CSVParserIterator {
    return CSVParserIterator(lines: self.lines, delimiter: self.delimiter)
  }
}


extension CSVParser: Collection {
  public typealias Index = Int
  public var startIndex: Index { return self.lines.startIndex }
  public var endIndex: Index {
    return self.lines.endIndex
  }
  
  public func index(after i: Index) -> Index {
    return self.lines.index(after: i)
  }
  
  subscript(idx: Index) -> [String] {
    get {
      return self.lines[idx].words()
    }
    
    set (newValue) {
      self.lines[idx] = newValue.joined(separator: String(self.delimiter))
    }
  }
}