import Vapor
import URLFormat
import Routing
import Prelude

public let GET = ClosedPathFormat<Prelude.Unit>(stringLiteral: "GET")
public let POST = ClosedPathFormat<Prelude.Unit>(stringLiteral: "POST")
public let PUT = ClosedPathFormat<Prelude.Unit>(stringLiteral: "PUT")
public let PATCH = ClosedPathFormat<Prelude.Unit>(stringLiteral: "PATCH")
public let DELETE = ClosedPathFormat<Prelude.Unit>(stringLiteral: "DELETE")

extension Router {
    #if swift(>=5.2)
    @discardableResult
    public func callAsFunction<T, A>(_ format: URLFormat<A>, use closure: @escaping (Request, A) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format, use: closure)
    }
    @discardableResult
    public func callAsFunction<T, A, B>(_ format: URLFormat<(A, B)>, use closure: @escaping (Request, A, B) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0, $1.1) }
    }
    @discardableResult
    public func callAsFunction<T, A, B, C>(_ format: URLFormat<((A, B), C)>, use closure: @escaping (Request, A, B, C) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0.0, $1.0.1, $1.1) }
    }
    @discardableResult
    public func callAsFunction<T, A, B, C, D>(_ format: URLFormat<(((A, B), C), D)>, use closure: @escaping (Request, A, B, C, D) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0.0.0, $1.0.0.1, $1.0.1, $1.1) }
    }
    @discardableResult
    public func callAsFunction<T, A, B, C, D, E>(_ format: URLFormat<((((A, B), C), D), E)>, use closure: @escaping (Request, A, B, C, D, E) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0.0.0.0, $1.0.0.0.1, $1.0.0.1, $1.0.1, $1.1) }
    }
    @discardableResult
    public func callAsFunction<T, A, B, C, D, E, F>(_ format: URLFormat<(((((A, B), C), D), E), F)>, use closure: @escaping (Request, A, B, C, D, E, F) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0.0.0.0.0, $1.0.0.0.0.1, $1.0.0.0.1, $1.0.0.1, $1.0.1, $1.1) }
    }
    @discardableResult
    public func callAsFunction<T, A, B, C, D, E, F, G>(_ format: URLFormat<((((((A, B), C), D), E), F), G)>, use closure: @escaping (Request, A, B, C, D, E, F, G) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0.0.0.0.0.0, $1.0.0.0.0.0.1, $1.0.0.0.0.1, $1.0.0.0.1, $1.0.0.1, $1.0.1, $1.1) }
    }
    @discardableResult
    public func callAsFunction<T, A, B, C, D, E, F, G, H>(_ format: URLFormat<(((((((A, B), C), D), E), F), G), H)>, use closure: @escaping (Request, A, B, C, D, E, F, G, H) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0.0.0.0.0.0.0, $1.0.0.0.0.0.0.1, $1.0.0.0.0.0.1, $1.0.0.0.0.1, $1.0.0.0.1, $1.0.0.1, $1.0.1, $1.1) }
    }
    @discardableResult
    public func callAsFunction<T, A, B, C, D, E, F, G, H, I>(_ format: URLFormat<((((((((A, B), C), D), E), F), G), H), I)>, use closure: @escaping (Request, A, B, C, D, E, F, G, H, I) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0.0.0.0.0.0.0.0, $1.0.0.0.0.0.0.0.1, $1.0.0.0.0.0.0.1, $1.0.0.0.0.0.1, $1.0.0.0.0.1, $1.0.0.0.1, $1.0.0.1, $1.0.1, $1.1) }
    }
    @discardableResult
    public func callAsFunction<T, A, B, C, D, E, F, G, H, I, J>(_ format: URLFormat<(((((((((A, B), C), D), E), F), G), H), I), J)>, use closure: @escaping (Request, A, B, C, D, E, F, G, H, I, J) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0.0.0.0.0.0.0.0.0, $1.0.0.0.0.0.0.0.0.1, $1.0.0.0.0.0.0.0.1, $1.0.0.0.0.0.0.1, $1.0.0.0.0.0.1, $1.0.0.0.0.1, $1.0.0.0.1, $1.0.0.1, $1.0.1, $1.1) }
    }
    #else
    @discardableResult
    public func route<T, A>(_ format: URLFormat<A>, use closure: @escaping (Request, A) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format, use: closure)
    }
    @discardableResult
    public func route<T, A, B>(_ format: URLFormat<(A, B)>, use closure: @escaping (Request, A, B) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0, $1.1) }
    }
    @discardableResult
    public func route<T, A, B, C>(_ format: URLFormat<((A, B), C)>, use closure: @escaping (Request, A, B, C) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0.0, $1.0.1, $1.1) }
    }
    @discardableResult
    public func route<T, A, B, C, D>(_ format: URLFormat<(((A, B), C), D)>, use closure: @escaping (Request, A, B, C, D) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0.0.0, $1.0.0.1, $1.0.1, $1.1) }
    }
    @discardableResult
    public func route<T, A, B, C, D, E>(_ format: URLFormat<((((A, B), C), D), E)>, use closure: @escaping (Request, A, B, C, D, E) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0.0.0.0, $1.0.0.0.1, $1.0.0.1, $1.0.1, $1.1) }
    }
    @discardableResult
    public func route<T, A, B, C, D, E, F>(_ format: URLFormat<(((((A, B), C), D), E), F)>, use closure: @escaping (Request, A, B, C, D, E, F) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0.0.0.0.0, $1.0.0.0.0.1, $1.0.0.0.1, $1.0.0.1, $1.0.1, $1.1) }
    }
    @discardableResult
    public func route<T, A, B, C, D, E, F, G>(_ format: URLFormat<((((((A, B), C), D), E), F), G)>, use closure: @escaping (Request, A, B, C, D, E, F, G) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0.0.0.0.0.0, $1.0.0.0.0.0.1, $1.0.0.0.0.1, $1.0.0.0.1, $1.0.0.1, $1.0.1, $1.1) }
    }
    @discardableResult
    public func route<T, A, B, C, D, E, F, G, H>(_ format: URLFormat<(((((((A, B), C), D), E), F), G), H)>, use closure: @escaping (Request, A, B, C, D, E, F, G, H) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0.0.0.0.0.0.0, $1.0.0.0.0.0.0.1, $1.0.0.0.0.0.1, $1.0.0.0.0.1, $1.0.0.0.1, $1.0.0.1, $1.0.1, $1.1) }
    }
    @discardableResult
    public func route<T, A, B, C, D, E, F, G, H, I>(_ format: URLFormat<((((((((A, B), C), D), E), F), G), H), I)>, use closure: @escaping (Request, A, B, C, D, E, F, G, H, I) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0.0.0.0.0.0.0.0, $1.0.0.0.0.0.0.0.1, $1.0.0.0.0.0.0.1, $1.0.0.0.0.0.1, $1.0.0.0.0.1, $1.0.0.0.1, $1.0.0.1, $1.0.1, $1.1) }
    }
    @discardableResult
    public func route<T, A, B, C, D, E, F, G, H, I, J>(_ format: URLFormat<(((((((((A, B), C), D), E), F), G), H), I), J)>, use closure: @escaping (Request, A, B, C, D, E, F, G, H, I, J) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        register(format) { try closure($0, $1.0.0.0.0.0.0.0.0.0, $1.0.0.0.0.0.0.0.0.1, $1.0.0.0.0.0.0.0.1, $1.0.0.0.0.0.0.1, $1.0.0.0.0.0.1, $1.0.0.0.0.1, $1.0.0.0.1, $1.0.0.1, $1.0.1, $1.1) }
    }
    #endif
    
    public func register<T, U>(_ format: URLFormat<U>, use closure: @escaping (Request, U) throws -> T) -> Route<Responder> where T: ResponseEncodable {
        let responder = BasicResponder { request in
            guard let urlComponents = URLComponents(string: request.http.urlString) else {
                throw RoutingError.init(identifier: "", reason: "")
            }
            let requestComponents = URLRequestComponents(method: request.http.method.string, urlComponents: urlComponents)
            guard let params = try format.parse(requestComponents) else {
                throw RoutingError.init(identifier: "", reason: "")
            }
            return try closure(request, params).encode(for: request)
        }
        let template = try! format.template()!
        let pathComponents = template.pathComponents.flatMap { comp -> [PathComponent] in
            let lowercased = comp.lowercased()
            if lowercased.hasPrefix(":") {
                return [.parameter(String(lowercased.dropFirst()))]
            } else {
                return lowercased.convertToPathComponents()
            }
        }
        
        let route = Route<Responder>(path: [.constant(template.method)] + pathComponents, output: responder)
        self.register(route: route)
        return route
    }
}
