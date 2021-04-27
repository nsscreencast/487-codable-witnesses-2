import Foundation

struct User {
    let id: UUID
    let name: String
    let ageInYears: Int
}

extension User: Encodable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case ageInYears = "age"
    }
    
    enum AltCodingKeys: String, CodingKey {
        case id = "ID"
        case name = "UserName"
        case ageInYears = "UserAge"
    }
}

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

let user = User(id: .init(), name: "Tim Cook", ageInYears: 60)

printJSON(try encoder.encode(user))

struct Encoding<Input> {
    let encode: (Input, Encoder) throws -> Void
}

extension Encoding where Input == User {
    static var defaultEncoding = Encoding<User> { (user, encoder) in
        var container = encoder.container(keyedBy: User.CodingKeys.self)
        try container.encode(user.id, forKey: .id)
        try container.encode(user.name, forKey: .name)
        try container.encode(user.ageInYears, forKey: .ageInYears)
    }
    
    static var altEncoding = Encoding<User> { (user, encoder) in
        var container = encoder.container(keyedBy: User.AltCodingKeys.self)
        try container.encode(user.id, forKey: .id)
        try container.encode(user.name, forKey: .name)
        try container.encode(user.ageInYears, forKey: .ageInYears)
    }
}

//userEncoder.encode(user, encoder)

//printJSON(try encoder.encode(proxy))

extension JSONEncoder {
    struct EncodingProxy<T>: Encodable {
        let value: T
        let encoding: Encoding<T>
        
        func encode(to encoder: Encoder) throws {
            try encoding.encode(value, encoder)
        }
    }
    
    func encode<Input>(_ input: Input, as encoding: Encoding<Input>) throws -> Data {
        let proxy = EncodingProxy(value: input, encoding: encoding)
        return try encode(proxy)
    }
}

printJSON(try encoder.encode(user, as: .defaultEncoding))
printJSON(try encoder.encode(user, as: .altEncoding))

extension Encoding where Input == Int {
    static var singleValue = Encoding<Int> { int, encoder in
        var container = encoder.singleValueContainer()
        try container.encode(int)
    }
    
    static func keyed<Key: CodingKey>(as key: Key) -> Self {
        .init { int, encoder in
            var container = encoder.container(keyedBy: Key.self)
            try container.encode(int, forKey: key)
        }
    }
}

extension Encoding where Input == String {
    static var singleValue = Encoding<String> { string, encoder in
        var container = encoder.singleValueContainer()
        try container.encode(string)
    }
    
    static func keyed<Key: CodingKey>(as key: Key) -> Self {
        .init { string, encoder in
            var container = encoder.container(keyedBy: Key.self)
            try container.encode(string, forKey: key)
        }
    }
    
    static func lowercased<Key: CodingKey>(as key: Key) -> Self {
        keyed(as: key)
            .pullback { $0.lowercased() }
    }
}

extension Encoding where Input == UUID {
    static func keyed<Key: CodingKey>(as key: Key) -> Self {
        .init { uuid, encoder in
            var container = encoder.container(keyedBy: Key.self)
            try container.encode(uuid, forKey: key)
        }
    }
    
    static func lowercased<Key: CodingKey>(as key: Key) -> Self {
        Encoding<String>
            .lowercased(as: key)
            .pullback(\.uuidString)
    }
}

extension Encoding {
    func pullback<NewInput>( _ f: @escaping (NewInput) -> Input) -> Encoding<NewInput> {
        .init { newInput, encoder in
            try self.encode(f(newInput), encoder)
        }
    }
}

extension Encoding where Input == User {
    static var id: Self = Encoding<UUID>
        .lowercased(as: User.CodingKeys.id)
        .pullback(\.id)

    static var name: Self = Encoding<String>
        .keyed(as: User.CodingKeys.name)
        .pullback(\.name)
    
    static var ageInYears: Self = Encoding<Int>
        .keyed(as: User.CodingKeys.ageInYears)
        .pullback(\.ageInYears)
}

printJSON(try encoder.encode(user, as: .id))

extension Encoding {
    static func combine(_ encodings: Encoding<Input>...) -> Self {
        .init { input, encoder in
            for encoding in encodings {
                try encoding.encode(input, encoder)
            }
        }
    }
}

extension Encoding where Input == User {
    static var defaultEncodingTwo = combine(id, name, ageInYears)
    static var forUpdates = combine(name, ageInYears)
}

printJSON(try encoder.encode(user, as: .forUpdates))
