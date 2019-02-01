import Foundation

public enum PropertyType: String {
    case dictionary = "dictionary"
    case string = "string"
    case number = "number"
    case arrayOfDictionaries = "arrayOfDictionaries"
    case arrayOfStrings = "arrayOfStrings"
    case bool = "bool"
}

open class Resource: BaseResource {
    let internalIdentifier = "<Resource_\(UUID().uuidString)>"

    open class var resourceType: String {
        fatalError("Must override `static var resourceType: String`")
    }

    open class var codingKeys: [String: String] {
        return [:]
    }

    open class var propertyTypes: [String: PropertyType] {
        return [:]
    }

    public static var incorrectPropertyValueClosure: ((String, String, String, String, Any?) -> Void)?

    private var resourceContext: Context?
    private var resourceObject: NSMutableDictionary?
    weak var context: Context?
    weak var object: NSMutableDictionary?

    @objc public var id: String?
    public lazy var type: String = Swift.type(of: self).resourceType

    public var meta: NSMutableDictionary? {
        var _meta: NSMutableDictionary?

        context?.queue.sync {
            _meta = object?["meta"] as? NSMutableDictionary
        }

        return _meta
    }

    public var attributes: NSMutableDictionary? {
        var _attributes: NSMutableDictionary?

        context?.queue.sync {
            _attributes = object?["attributes"] as? NSMutableDictionary
        }

        return _attributes
    }

    public var relationships: NSMutableDictionary? {
        var _relationships: NSMutableDictionary?

        context?.queue.sync {
            _relationships = object?["relationships"] as? NSMutableDictionary
        }

        return _relationships
    }

    public required init(context: Context? = nil) {
        super.init()

        if context == nil {
            let _context = Context(dictionary: NSMutableDictionary())
            let _object = NSMutableDictionary()
            self.resourceContext = _context
            self.resourceObject = _object
            self.context = _context
            self.object = _object
        } else {
            self.context = context
        }
    }

    open override func value(forKey key: String) -> Any? {
        let key = Swift.type(of: self).codingKeys[key] ?? key
        let value = context?.value(forKey: key, inResource: self)
        let typedValue = typeSafeValue(key: key, value: value)
        return typedValue
    }

    open override func setValue(_ value: Any?, forKey key: String) {
        let key = Swift.type(of: self).codingKeys[key] ?? key
        context?.setValue(value, forKey: key, inResource: self)
    }

    private func typeSafeValue(key: String, value: Any?) -> Any? {
        guard let value = value else {
            return nil
        }
        guard let type = Swift.type(of: self).propertyTypes[key] else {
            return value
        }

        var typedValue: Any?

        switch type {
        case .string:
            typedValue = value as? String
        case .number:
            typedValue = value as? NSNumber
        case .arrayOfDictionaries:
            typedValue = value as? [[String: Any]]
        case .arrayOfStrings:
            typedValue = value as? [String]
        case .bool:
            typedValue = value as? Bool
        case .dictionary:
            typedValue = value as? [String: Any]
        }

        if typedValue == nil {
            Resource.incorrectPropertyValueClosure?(self.type, id ?? "", key, type.rawValue, value)
        }

        return typedValue
    }

    public func documentDictionary() throws -> [String: Any] {
        let attributes = self.attributes
        let relationships = self.relationships

        var dictionary: [String: Any] = [
            "type": self.type
        ]

        if let id = id {
            dictionary["id"] = id
        }

        if let attributes = attributes,
            attributes.count > 0 {
            dictionary["attributes"] = attributes
        }

        if let relationships = relationships,
            relationships.count > 0 {
            dictionary["relationships"] = relationships
        }

        return ["data": dictionary]
    }

    public func documentData() throws -> Data {
        let data = try JSONSerialization.data(withJSONObject: documentDictionary(), options: [])

        return data
    }

    func reassignContext(_ context: Context) {
        self.context = context
        self.resourceContext = context
    }
}

extension Resource {
    subscript(key: String) -> Any? {
        get {
            return value(forKey: key)
        }
        set {
            setValue(newValue, forKey: key)
        }
    }
}

extension Array where Element: Resource {
    public func documentDictionary() throws -> [String: Any] {
        let array = try map { (resource) throws -> [String: Any] in
            guard let id = resource.id else {
                throw JSONAPIError.serialization
            }

            let attributes = resource.attributes
            let relationships = resource.relationships

            var dictionary: [String: Any] = [
                "id": id,
                "type": resource.type
            ]

            if let attributes = attributes,
                attributes.count > 0 {
                dictionary["attributes"] = attributes
            }

            if let relationships = relationships,
                relationships.count > 0 {
                dictionary["relationships"] = relationships
            }

            return dictionary
        }

        return ["data": array]
    }

    public func documentDictionaryForCreation() throws -> [String: Any] {
        let array = try map { (resource) throws -> [String: Any] in
            let attributes = resource.attributes
            let relationships = resource.relationships

            var dictionary: [String: Any] = [
                "type": resource.type
            ]

            if let attributes = attributes,
                attributes.count > 0 {
                dictionary["attributes"] = attributes
            }

            if let relationships = relationships,
                relationships.count > 0 {
                dictionary["relationships"] = relationships
            }

            return dictionary
        }

        return ["data": array]
    }

    public func documentData() throws -> Data {
        let data = try JSONSerialization.data(withJSONObject: documentDictionary(), options: [])

        return data
    }
}


