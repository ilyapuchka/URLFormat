import Foundation
import Prelude
import CommonParsers

public struct URLRequestComponents: Monoid, CustomStringConvertible {
    public let method: String
    public internal(set) var urlComponents: URLComponents
    
    public init(method: String = "", urlComponents: URLComponents = URLComponents()) {
        self.urlComponents = urlComponents
        self.method = method
    }
    
    public static var empty: URLRequestComponents = URLRequestComponents()

    public var isEmpty: Bool {
        return pathComponents.isEmpty && urlComponents.scheme == nil && urlComponents.host == nil
    }

    public static func <> (lhs: URLRequestComponents, rhs: URLRequestComponents) -> URLRequestComponents {
        var result = URLComponents()
        result.scheme = lhs.urlComponents.scheme ?? rhs.urlComponents.scheme
        result.host = lhs.urlComponents.host ?? rhs.urlComponents.host
        result.path = [lhs.urlComponents.path, rhs.urlComponents.path]
            .filter { !$0.isEmpty }
            .joined(separator: "/")

        if lhs.urlComponents.host != nil && rhs.urlComponents.host == nil {
            result.path = "/" + result.path
        }

        result.queryItems =
            lhs.urlComponents.queryItems.flatMap { lhs in
                rhs.urlComponents.queryItems.flatMap { rhs in lhs + rhs }
                    ?? lhs
            }
            ?? rhs.urlComponents.queryItems
        return .init(method: lhs.method, urlComponents: result)
    }

    public var pathComponents: [String] {
        get {
            if urlComponents.path.isEmpty {
                return []
            } else if urlComponents.path.hasPrefix("/") {
                return urlComponents.path.dropFirst().components(separatedBy: "/")
            } else {
                return urlComponents.path.components(separatedBy: "/")
            }
        }
        set {
            urlComponents.path = newValue.joined(separator: "/")
        }
    }

    func with(_ f: (inout URLRequestComponents) -> Void) -> URLRequestComponents {
        var v = self
        f(&v)
        return v
    }
    
    public var description: String {
        if !method.isEmpty {
            return "\(method) \(urlComponents)"
        } else {
            return "\(urlComponents)"
        }
    }
}

public class URLFormat<A> {
    let parser: Parser<URLRequestComponents, A>

    init(_ parser: Parser<URLRequestComponents, A>) {
        self.parser = parser
    }
    
    public func parse(_ url: URLRequestComponents) throws -> A? {
        fatalError()
    }

    public func print(_ value: A) throws -> URLRequestComponents? {
        try parser.print(value)
    }

    public func template() throws -> URLRequestComponents? {
        try parser.templateValue().flatMap(parser.template)
    }
}

// url does not have query and is open for adding more path/query parameters
@dynamicMemberLookup
public class OpenPathFormat<A>: URLFormat<A> {
    public subscript(dynamicMember member: String) -> ClosedPathFormat<A> {
        return ClosedPathFormat(parser <% path(member))
    }
    public override func parse(_ url: URLRequestComponents) throws -> A? {
        try self.end.parser.parse(url)?.match
    }
}

// url does not have a query and is complete, not expeciting any path parameters
// only query parameters can be added
public class ClosedPathFormat<A>: URLFormat<A>, ExpressibleByStringLiteral {
    public override init(_ parser: Parser<URLRequestComponents, A>) {
        super.init(parser)
    }
    required public convenience init(stringLiteral value: String) {
        self.init(httpMethod(value).map(.any))
    }
    public override func parse(_ url: URLRequestComponents) throws -> A? {
        try self.end.parser.parse(url)?.match
    }
}

// url has a query and is open for adding more query parameters
// no path parameters can be added
@dynamicMemberLookup
public class OpenQueryFormat<A>: URLFormat<A> {
    public subscript<B>(dynamicMember member: String) -> (URLPartialIso<String, B>) -> ClosedQueryFormat<(A, B)> {
        return { [parser] iso in
            return ClosedQueryFormat(parser <%> query(member, iso))
        }
    }
    public subscript<B>(dynamicMember member: String) -> (URLPartialIso<String, B>) -> ClosedQueryFormat<B> where A == Prelude.Unit {
        return { [parser] iso in
            return ClosedQueryFormat(parser %> query(member, iso))
        }
    }
    public subscript<B: RawRepresentable & CaseIterable>(dynamicMember member: String) -> (URLPartialIso<Int, B>) -> ClosedQueryFormat<(A, B)> where B.RawValue == Int {
        return { [parser] iso in
            return ClosedQueryFormat(parser <%> query(member, .int >>> .raw(B.self)))
        }
    }
    public subscript<B: RawRepresentable & CaseIterable>(dynamicMember member: String) -> (URLPartialIso<Double, B>) -> ClosedQueryFormat<(A, B)> where B.RawValue == Double {
        return { [parser] iso in
            return ClosedQueryFormat(parser <%> query(member, .double >>> .raw(B.self)))
        }
    }
    public subscript<B: RawRepresentable & CaseIterable>(dynamicMember member: String) -> (URLPartialIso<Character, B>) -> ClosedQueryFormat<(A, B)> where B.RawValue == Character {
        return { [parser] iso in
            return ClosedQueryFormat(parser <%> query(member, .char >>> .raw(B.self)))
        }
    }
    public override func parse(_ url: URLRequestComponents) throws -> A? {
        try parser.parse(url)?.match
    }
}

// url has a query and is complete, not expecting any query parameters
// no query parameters can be added
public class ClosedQueryFormat<A>: URLFormat<A> {
    public override func parse(_ url: URLRequestComponents) throws -> A? {
        try parser.parse(url)?.match
    }
}

postfix operator /
public postfix func / <A>(_ lhs: ClosedPathFormat<A>) -> OpenPathFormat<A> {
    return OpenPathFormat(lhs.parser)
}

postfix operator /?
public postfix func /? <A>(_ lhs: ClosedPathFormat<A>) -> OpenQueryFormat<A> {
    return OpenQueryFormat(lhs.end.parser)
}

postfix operator *?
public postfix func *? <A>(_ lhs: ClosedPathFormat<A>) -> OpenQueryFormat<(A, String)> {
    return OpenQueryFormat(lhs.parser <%> some())
}

public postfix func *? (_ lhs: ClosedPathFormat<Prelude.Unit>) -> OpenQueryFormat<String> {
    return OpenQueryFormat(lhs.parser %> some())
}

postfix operator &
public postfix func & <A>(_ lhs: ClosedQueryFormat<A>) -> OpenQueryFormat<A> {
    return OpenQueryFormat(lhs.parser)
}

postfix operator *
public postfix func * <A>(_ lhs: ClosedPathFormat<A>) -> URLFormat<(A, String)> {
    return ClosedQueryFormat(lhs.parser <%> some())
}

public postfix func * (_ lhs: ClosedPathFormat<Prelude.Unit>) -> URLFormat<String> {
    return ClosedQueryFormat(lhs.parser %> some())
}

extension OpenPathFormat {
    public var string: ClosedPathFormat<(A, String)> {
        return ClosedPathFormat(parser <%> path(.string))
    }
    public var char: ClosedPathFormat<(A, Character)> {
        return ClosedPathFormat(parser <%> path(.char))
    }
    public var bool: ClosedPathFormat<(A, Bool)> {
        return ClosedPathFormat(parser <%> path(.bool))
    }
    public var int: ClosedPathFormat<(A, Int)> {
        return ClosedPathFormat(parser <%> path(.int))
    }
    public var double: ClosedPathFormat<(A, Double)> {
        return ClosedPathFormat(parser <%> path(.double))
    }
    public var uuid: ClosedPathFormat<(A, UUID)> {
        return ClosedPathFormat(parser <%> path(.uuid))
    }
    public var any: ClosedPathFormat<(A, Any)> {
        return ClosedPathFormat(parser <%> path(.any))
    }
    public func lossless<B: LosslessStringConvertible & CustomParserTemplateValueConvertible>(_ type: B.Type) -> ClosedPathFormat<(A, B)> {
        return ClosedPathFormat(parser <%> path(.losslessStringConvertible))
    }
    public func raw<B: RawRepresentable & CaseIterable>(_ type: B.Type) -> ClosedPathFormat<(A, B)> where B.RawValue == String {
        return ClosedPathFormat(parser <%> path(.string).map(.rawRepresentable))
    }
    public func raw<B: RawRepresentable & CaseIterable>(_ type: B.Type) -> ClosedPathFormat<(A, B)> where B.RawValue == Int {
        return ClosedPathFormat(parser <%> path(.int).map(.rawRepresentable))
    }
    public func raw<B: RawRepresentable & CaseIterable>(_ type: B.Type) -> ClosedPathFormat<(A, B)> where B.RawValue == Double {
        return ClosedPathFormat(parser <%> path(.double).map(.rawRepresentable))
    }
    public func raw<B: RawRepresentable & CaseIterable>(_ type: B.Type) -> ClosedPathFormat<(A, B)> where B.RawValue == Character {
        return ClosedPathFormat(parser <%> path(.char).map(.rawRepresentable))
    }
}

extension OpenPathFormat where A == Prelude.Unit {
    public var string: ClosedPathFormat<String> {
        return ClosedPathFormat(parser %> path(.string))
    }
    public var char: ClosedPathFormat<Character> {
        return ClosedPathFormat(parser %> path(.char))
    }
    public var bool: ClosedPathFormat<Bool> {
        return ClosedPathFormat(parser %> path(.bool))
    }
    public var int: ClosedPathFormat<Int> {
        return ClosedPathFormat(parser %> path(.int))
    }
    public var double: ClosedPathFormat<Double> {
        return ClosedPathFormat(parser %> path(.double))
    }
    public var uuid: ClosedPathFormat<UUID> {
        return ClosedPathFormat(parser %> path(.uuid))
    }
    public var any: ClosedPathFormat<Any> {
        return ClosedPathFormat(parser %> path(.any))
    }
    public func lossless<B: LosslessStringConvertible & CustomParserTemplateValueConvertible>(_ type: B.Type) -> ClosedPathFormat<B> {
        return ClosedPathFormat(parser %> path(.losslessStringConvertible))
    }
    public func raw<B: RawRepresentable & CaseIterable>(_ type: B.Type) -> ClosedPathFormat<B> where B.RawValue == String {
        return ClosedPathFormat(parser %> path(.string).map(.rawRepresentable))
    }
    public func raw<B: RawRepresentable & CaseIterable>(_ type: B.Type) -> ClosedPathFormat<B> where B.RawValue == Int {
        return ClosedPathFormat(parser %> path(.int).map(.rawRepresentable))
    }
    public func raw<B: RawRepresentable & CaseIterable>(_ type: B.Type) -> ClosedPathFormat<B> where B.RawValue == Double {
        return ClosedPathFormat(parser %> path(.double).map(.rawRepresentable))
    }
    public func raw<B: RawRepresentable & CaseIterable>(_ type: B.Type) -> ClosedPathFormat<B> where B.RawValue == Character {
        return ClosedPathFormat(parser %> path(.char).map(.rawRepresentable))
    }
}

extension URLPartialIso where A == String, B: LosslessStringConvertible & CustomParserTemplateValueConvertible {
    public static func lossless(_ type: B.Type) -> URLPartialIso {
        return losslessStringConvertible
    }
}

extension URLPartialIso where B: RawRepresentable & CaseIterable, B.RawValue == A {
    public static func raw(_ type: B.Type) -> URLPartialIso<A, B> {
        rawRepresentable
    }
}

public extension URLFormat {
    /// Matches url that has no additional path componets that were not parsed yet.
    var end: URLFormat {
        return .init(self.parser <% Parser<URLRequestComponents, Prelude.Unit>(
            parse: { $0.isEmpty ? ($0, unit) : nil },
            print: const(URLRequestComponents()),
            template: const(URLRequestComponents()),
            templateValue: { unit }
        ))
    }
}

public func any() -> Parser<URLRequestComponents, Prelude.Unit> {
    return Parser(
        parse: { ($0, unit) },
        print: const(URLRequestComponents()),
        template: const(URLRequestComponents()),
        templateValue: { unit }
    )
}

public func some() -> Parser<URLRequestComponents, String> {
    return Parser(
        parse: { format in
            format.isEmpty
                ? (format, "")
                : (format.with { $0.pathComponents = [] }, format.pathComponents.joined(separator: "/"))
        },
        print: { str in URLRequestComponents().with { $0.urlComponents.path = str } },
        template: { _ in URLRequestComponents(urlComponents: URLComponents(string: "*")!) },
        templateValue: { "" }
    )
}

public func httpMethod(_ method: String) -> Parser<URLRequestComponents, Prelude.Unit> {
    return Parser<URLRequestComponents, Prelude.Unit>(
        parse: { request in
            guard request.method == method else { return nil }
            return (request, unit)
        },
        print: const(URLRequestComponents(method: method)),
        template: const(URLRequestComponents(method: method)),
        templateValue: { unit }
    )
}

public func path(_ str: String) -> Parser<URLRequestComponents, Prelude.Unit> {
    return Parser<URLRequestComponents, Prelude.Unit>(
        parse: { format in
            return head(format.pathComponents).flatMap { (p, ps) in
                return p == str
                    ? (format.with { $0.pathComponents = ps }, unit)
                    : nil
            }
        },
        print: { _ in URLRequestComponents().with { $0.urlComponents.path = str } },
        template: { _ in URLRequestComponents().with { $0.urlComponents.path = str } },
        templateValue: { unit }
    )
}

public func path<A>(_ f: URLPartialIso<String, A>) -> Parser<URLRequestComponents, A> {
    return Parser<URLRequestComponents, A>(
        parse: { format in
            guard let (p, ps) = head(format.pathComponents), let v = try f.iso.apply(p) else { return nil }
            return (format.with { $0.pathComponents = ps }, v)
        },
        print: { a in
            try f.iso.unapply(a).flatMap { s in
                URLRequestComponents().with { $0.urlComponents.path = s }
            }
        },
        template: { a in
            try f.iso.unapply(a).flatMap { s in
                return URLRequestComponents().with { $0.urlComponents.path = ":" + "\(type(of: a))" }
            }
        },
        templateValue: { f.templateValue }
    )
}

public func query<A>(_ key: String, _ f: URLPartialIso<String, A>) -> Parser<URLRequestComponents, A> {
    return Parser<URLRequestComponents, A>(
        parse: { format in
            guard
                let queryItems = format.urlComponents.queryItems,
                let p = queryItems.first(where: { $0.name == key })?.value,
                let v = try f.iso.apply(p)
                else { return nil }
            return (format, v)
        },
        print: { a in
            try f.iso.unapply(a).flatMap { s in
                URLRequestComponents().with { $0.urlComponents.queryItems = [URLQueryItem(name: key, value: s)] }
            }
        },
        template: { a in
            try f.iso.unapply(a).flatMap { s in
                URLRequestComponents().with { $0.urlComponents.queryItems = [URLQueryItem(name: key, value: ":" + "\(type(of: a))")] }
            }
        },
        templateValue: { f.templateValue }
    )
}

private func head<A>(_ xs: [A]) -> (A, [A])? {
    guard let x = xs.first else { return nil }
    return (x, Array(xs.dropFirst()))
}

// Because of prefix/postifx operators precedence values are accomulated not in a symmectric tuples so we have to fixup flattening

public func flatten<A, B, C>(_ f: ((A, B), C)) -> (A, B, C) {
    return (f.0.0, f.0.1, f.1)
}

public func parenthesize<A, B, C>(_ a: A, _ b: B, _ c: C) -> ((A, B), C) {
    return ((a, b), c)
}

public func flatten<A, B, C, D>(_ f: (((A, B), C), D)) -> (A, B, C, D) {
    return (f.0.0.0, f.0.0.1, f.0.1, f.1)
}

public func parenthesize<A, B, C, D>(_ a: A, _ b: B, _ c: C, _ d: D) -> (((A, B), C), D) {
    return (((a, b), c), d)
}

public func flatten<A, B, C, D, E>(_ f: ((((A, B), C), D), E)) -> (A, B, C, D, E) {
    return (f.0.0.0.0, f.0.0.0.1, f.0.0.1, f.0.1, f.1)
}

public func parenthesize<A, B, C, D, E>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E) -> ((((A, B), C), D), E) {
    return ((((a, b), c), d), e)
}

public func flatten<A, B, C, D, E, F>(_ f: (((((A, B), C), D), E), F)) -> (A, B, C, D, E, F) {
    return (f.0.0.0.0.0, f.0.0.0.0.1, f.0.0.0.1, f.0.0.1, f.0.1, f.1)
}

public func parenthesize<A, B, C, D, E, F>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F) -> (((((A, B), C), D), E), F) {
    return (((((a, b), c), d), e), f)
}

public func flatten<A, B, C, D, E, F, G>(_ f: ((((((A, B), C), D), E), F), G)) -> (A, B, C, D, E, F, G) {
    return (f.0.0.0.0.0.0, f.0.0.0.0.0.1, f.0.0.0.0.1, f.0.0.0.1, f.0.0.1, f.0.1, f.1)
}

public func parenthesize<A, B, C, D, E, F, G>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G) -> ((((((A, B), C), D), E), F), G) {
    return ((((((a, b), c), d), e), f), g)
}

public func flatten<A, B, C, D, E, F, G, H>(_ f: (((((((A, B), C), D), E), F), G), H)) -> (A, B, C, D, E, F, G, H) {
    return (f.0.0.0.0.0.0.0, f.0.0.0.0.0.0.1, f.0.0.0.0.0.1, f.0.0.0.0.1, f.0.0.0.1, f.0.0.1, f.0.1, f.1)
}

public func parenthesize<A, B, C, D, E, F, G, H>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H) -> (((((((A, B), C), D), E), F), G), H) {
    return (((((((a, b), c), d), e), f), g), h)
}

public func flatten<A, B, C, D, E, F, G, H, I>(_ f: ((((((((A, B), C), D), E), F), G), H), I)) -> (A, B, C, D, E, F, G, H, I) {
    return (f.0.0.0.0.0.0.0.0, f.0.0.0.0.0.0.0.1, f.0.0.0.0.0.0.1, f.0.0.0.0.0.1, f.0.0.0.0.1, f.0.0.0.1, f.0.0.1, f.0.1, f.1)
}

public func parenthesize<A, B, C, D, E, F, G, H, I>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H, _ i: I) -> ((((((((A, B), C), D), E), F), G), H), I) {
    return ((((((((a, b), c), d), e), f), g), h), i)
}

public func flatten<A, B, C, D, E, F, G, H, I, J>(_ f: (((((((((A, B), C), D), E), F), G), H), I), J)) -> (A, B, C, D, E, F, G, H, I, J) {
    return (f.0.0.0.0.0.0.0.0.0, f.0.0.0.0.0.0.0.0.1, f.0.0.0.0.0.0.0.1, f.0.0.0.0.0.0.1, f.0.0.0.0.0.1, f.0.0.0.0.1, f.0.0.0.1, f.0.0.1, f.0.1, f.1)
}

public func parenthesize<A, B, C, D, E, F, G, H, I, J>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H, _ i: I, _ j: J) -> (((((((((A, B), C), D), E), F), G), H), I), J) {
    return (((((((((a, b), c), d), e), f), g), h), i), j)
}

public struct URLPartialIso<A, B> {
    let iso: PartialIso<A, B>
    let templateValue: B
    
    public init(iso: PartialIso<A, B>, templateValue: B) {
        self.iso = iso
        self.templateValue = templateValue
    }
    
    public static func >>> <C> (lhs: URLPartialIso<A, B>, rhs: URLPartialIso<B, C>) -> URLPartialIso<A, C> {
        URLPartialIso<A, C>(iso: lhs.iso >>> rhs.iso, templateValue: rhs.templateValue)
    }
}

extension URLPartialIso where B: CustomParserTemplateValueConvertible {
    public init(iso: PartialIso<A, B>) {
        self.iso = iso
        self.templateValue = B.parserTemplateValue
    }
}

extension URLPartialIso where A == String, B == Any {
    public static var any: URLPartialIso {
        return .init(iso: .any, templateValue: "")
    }
}

extension URLPartialIso where A == String, B == Int {
    /// An isomorphism between strings and integers.
    public static var int: URLPartialIso {
        return .init(iso: .int, templateValue: 0)
    }
}

extension URLPartialIso where A == String, B == Bool {
    /// An isomorphism between strings and booleans.
    public static var bool: URLPartialIso {
        return .init(iso: .bool, templateValue: true)
    }
}

extension URLPartialIso where A == String, B == String {
    /// The identity isomorphism between strings.
    public static var string: URLPartialIso {
        return .init(iso: .id, templateValue: "")
    }
}

extension URLPartialIso where A == String, B == Character {
    /// The identity isomorphism between strings.
    public static var char: URLPartialIso {
        return .init(iso: .char, templateValue: Character(" "))
    }
}

extension URLPartialIso where A == String, B == Double {
    /// An isomorphism between strings and doubles.
    public static var double: URLPartialIso {
        return .init(iso: .double, templateValue: 0.0)
    }
}

extension URLPartialIso where A == String, B: LosslessStringConvertible & CustomParserTemplateValueConvertible {
    public static var losslessStringConvertible: URLPartialIso {
        return .init(iso: .losslessStringConvertible)
    }
}

extension URLPartialIso where B: RawRepresentable & CaseIterable, B.RawValue == A {
    public static var rawRepresentable: URLPartialIso {
        precondition(B.allCases.first != nil)
        return .init(iso: .rawRepresentable, templateValue: B.allCases.first!)
    }
}

extension URLPartialIso where A == String, B == UUID {
    public static var uuid: URLPartialIso<String, UUID> {
        return .init(iso: PartialIso(
            apply: UUID.init(uuidString:),
            unapply: { $0.uuidString }
        ), templateValue: UUID())
    }
}

