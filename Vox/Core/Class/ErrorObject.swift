import Foundation

final public class ErrorObject {
    final public class Source {
        public let pointer: String?
        public let parameter: String?
        
        init(pointer: String?, parameter: String?) {
            self.pointer = pointer
            self.parameter = parameter
        }
    }
    
    public let id: String?
    public let links: [String: Any]?
    public let status: String?
    public let code: String?
    public let title: String?
    public let detail: String?
    public let source: Source?
    public let meta: [String: Any]?
    public let dictionary: [String: Any]?
    
    init(dictionary: [String: Any]) {
        id = dictionary["id"] as? String
        links = dictionary["links"] as? [String: Any]
        code = dictionary["code"] as? String
        title = dictionary["title"] as? String
        detail = dictionary["detail"] as? String
        self.dictionary = dictionary

        let stringStatus = dictionary["status"] as? String
        let intStatus = dictionary["status"] as? NSNumber

        if let status = stringStatus ?? intStatus?.stringValue {
            self.status = status
        } else {
            status = nil
        }

        let source: Source? = {
            guard let source = dictionary["source"] as? [String: Any] else {
                return nil
            }
            
            return Source(pointer: source["pointer"] as? String, parameter: source["parameter"] as? String)
        }()
        self.source = source
        
        meta = dictionary["meta"] as? [String: Any]
    }
}
