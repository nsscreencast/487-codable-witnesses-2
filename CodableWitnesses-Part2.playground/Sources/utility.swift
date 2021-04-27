import Foundation

public func printJSON(_ data: Data) {
    print(String(data: data, encoding: .utf8)!)
}
