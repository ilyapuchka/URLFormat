# URLFormat

Type safe url patter matching without regular expressions and argument type mismatches based on parser combinators.

Example:

```swift
let urlFormat: URLFormat = ""/.users/.string/.repos/?.filter(.string)&.page(.int)
let url = URLComponents(string: "/users/apple/repos/?filter=swift&page=2")!
let parameters = urlFormat.parse(url)

_ = flatten(parameters) // ("apple", "swift", 2)
urlFormat.print(parameters) // "user/apple/repos?filter=swift&page=2"
urlFormat.template(parameters) // "user/:String/repos?filter=:String&page=:Int"
```

## Usage

URLFormat is a URL builder that allows you to describe URL in a natural manner and allows you to pattern match it in a type safe way.

Conventional way of represting URL patterns, i.e. for web server API routes, is using some kind of string placehoders for paramters, i.e. `/user/:name`. This then is being parsed and path and query paramters are aggregated into collection. The issues is that this approach is error-prone (what if `:` is missed) and access to the parameters is not type safe - it's possible to access parameters as a wrong type or convertion must be implemented by the client, and it's possible to access parameter by wrong key or index.

Another approach that Swift allows is to use enums pattern matching, like described in [this post](https://alisoftware.github.io/swift/pattern-matching/2015/08/23/urls-and-pattern-matching/) and implemented in [URLPatterns](https://github.com/johnpatrickmorgan/URLPatterns). While this approach allows type-safe access to parameters it's not very ergonomic and nice to read:

```swift
if case .n4("user", let userId, "profile", _) ~= url.countedPathElements() { ... }
```

Another downside of this approach is that it only allows to extract parameters of the same type, so most of the time you would extract all of them as `String` and convert to other types:

```swift
case chat(room: String, membersCount: Int)

case .n3("chat", let room, let membersCount):
  self = .chat(room: room, membersCount: number) // Cannot convert value of type 'String' to expected argument type 'Int'
```

In Vapor routes are defined as a collection of path components:

```swift
router.get("users", String.parameter) { req in
    let name = try req.parameters.next(String.self)
    return "User #\(name)"
}
```

You can as well use string placeholders for parameters:

```swift
router.get("users", ":name") { request in
    guard let userName = request.parameters["name"]?.string else {
        throw Abort.badRequest
    }

    return "You requested User #\(userName)"
}
```

This is nicer to write and read, but it's even less type safe - the parameters must be fetched in the order they appear in the path and their types should match but compiler won't ensure that and you would need to make sure that the pattern definition and parameters access are always in sync.

You can't as well describe query parameters in the route, they instead are accessed in the route handler either via `request.data["key"]?.string` or `request.query?["key"]?.stirng` which is not type safe as well.

With URLFormat you would describe URLs as follows:

```swift
let urlFormat: URLFormat = ""/.users/.string/.repos/?.filter(.string)&.page(.int)
let url = URLComponents(string: "/users/apple/repos/?filter=swift&page=2")!
let parameters = urlFormat.parse(url)
print(flatten(parameters)) // ("apple", "swift", 2)
```

This patter will match URL with path like `/users/apple/repos/?filter=swift&page=1` (first and last `/` are optional). The fully qualified type of `urlFormat` in this case would be  `ClosedQueryFormat<((String, String), Int)>` (most of the time using base class type `URLFormat` is sufficient). The type of generic parameter describes types of all captured parameters. To extract them from the actual URL you'd use `parse` method and one of `flatten` functions to "flatten" nested tuples, i.e. `((A, B), C) -> (A, B, C)` which makes it more convenient to access parameters.

Note that it's not necessary to specify a generic type parameter manually as compiler can infer it from the declaration<sup id="a1">[1](#f1)</sup>. And compiler ensures that pattern and types of captured parameters are always in sync.

A nice caveat is that `URLFormat` can be used to print actual URLs and their readable templates if you provide it values for its parameters (again compiler makes sure that they are always in sync):

```swift
let parameters = parenthesize("apple", "swift", 2)
urlFormat.print(parameters) // "users/apple/repos?filter=swift&page=2"
urlFormat.template(parameters) // "users/:String/repos?filter=:String&page=:Int"
```

Note that there are no string literals involved in declaring this URL<sup id="a2">[2](#f2)</sup>. This is because under the hood `URLFormat` implements `@dynamicMemberLookup`, so expression like `.users` is converted to the parser that parses `"users"` string from the path components.

Path parameters are parsed using `.string` and `.int` operators. Query parameters are parsed with a combination of these operators and dynamic member lookup, so `.filter(.string)` will parse a string query parameter named `"filter"`, `.page(.int)` will parse an integer query parameter named `"page"`.

URLFormat also makes sure that URL is composed of path and query components correctly by allowing usage of `/`, `/?`, `&`, `*` and `*?` operators only in the correct places. This is done by using different subclasses of `URLFormat` to keep track of the builder state. It is similar to using phantom generic type parameters but allows to implement dynamic member lookup only for specific states of the builder.

<a name="f1">1</a>: an exeption here is when pattern does not capture any parameters, i.e. `_ = URLFormat<Prelude.Unit> = /.helloworld` . `Prelude.Unit` here is a type, similar to `Void`, but unlike `Void` it is an actual empty struct type. [↩](#a1)

<a name="f2">2</a>: `""` in the beginning of the patters is needed because static `dynamicMemberLookup` subscript calls can't be infered without explicitly specifying type (see [this discussion](https://forums.swift.org/t/static-dynamicmemberlookup/33310/5) for details) [↩](#a2)

## Parameters types

Following parameters types are supported:

- `String` with `.string` operator 
- `Character` with `.char` operator
- `Int` with `.int` operator
- `Double` with `.double` operator
- `Bool` with `.bool` operator
- `UUID` with `.uuid` operator
- `Any` with `.any` operator (unlike `*` this will match only single path component, `*` will capture all trailing path components into one string)
- `LosslessStringConvertible` types with `lossless(MyType.self)` operator
- `RawRepresentable` with `String`, `Character`, `Int` and `Double` raw value types with `raw(MyType.self)` operator

You can add support for your own types by implementing `PartialIso<String, MyType>`:

```swift
import CommonParsers

extension PartialIso where A == String, B == MyType {
    static var myType: PartialIso { ... }
}
extension OpenPathFormat where A == Prelude.Unit {
    var myType: ClosedPathFormat<MyType> {
        return ClosedPathFormat(parser %> path(.myType))
    }
}
extension OpenPathFormat {
    var myType: ClosedPathFormat<(A, MyType)> {
        return ClosedPathFormat(parser <%> path(.myType))
    }
}
```

With that you can use your type as a path or a query parameter:

`""/.users/.myType/.repos/?.filter(.myType)&.page(.int)`

## Operators

`/` - concatenates two path components
`/?` - concatenates path with a query component
`&` - concatenates two query components
`*` - allows any trailing path components
`*?` - concatenates path with any trailing path components and a query component

## Installation

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .package(url: "https://github.com/ilyapuchka/URLFormat.git", .branch("master")),
    ]
)
```
