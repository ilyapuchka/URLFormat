import XCTest
@testable import URLFormat
import Prelude

class SwiftNIOMockTests: XCTestCase {
    
    func testFormats() throws {
        var url: URLComponents
        
        let f1 = ""/.user/.string/.repos/?.filter(.string)&.page(.int)

        url = URLComponents(string: "user/ilya/repos?filter=swift&page=2")!
        var match = try XCTUnwrap(f1.parse(URLRequestComponents(urlComponents: url)))
        XCTAssertEqual("\(flatten(match))", #"("ilya", "swift", 2)"#)
        XCTAssertEqual(try f1.print(parenthesize("ilya", "swift", 2))?.urlComponents, url)

        url = URLComponents(string: "/user/ilya/repos?page=2&filter=swift")!
        match = try XCTUnwrap(f1.parse(URLRequestComponents(urlComponents: url)))
        XCTAssertEqual("\(flatten(match))", #"("ilya", "swift", 2)"#)

        let f2: URLFormat<Prelude.Unit> = ""/.helloworld
        
        url = URLComponents(string: "helloworld")!
        let match2 = try XCTUnwrap(f2.parse(URLRequestComponents(urlComponents: url)))
        XCTAssertEqual(try f2.print(match2)?.urlComponents, url)
        
        url = URLComponents(string: "helloworld/foo")!
        try XCTAssertNil(f2.parse(URLRequestComponents(urlComponents: url)))

        let f3 = ""/.hello/.string/?.name(.string)
        
        url = URLComponents(string: "hello/user?name=ilya")!
        let match3 = try XCTUnwrap(f3.parse(URLRequestComponents(urlComponents: url)))
        XCTAssertEqual("\(match3)", #"("user", "ilya")"#)
        XCTAssertEqual(try f3.print(match3)?.urlComponents, url)

        let f4 = ""/.hello/?.name(.string)&.page(.int)
        
        url = URLComponents(string: "hello?name=ilya&page=2")!
        let match4 = try XCTUnwrap(f4.parse(URLRequestComponents(urlComponents: url)))
        XCTAssertEqual("\(match4)", #"("ilya", 2)"#)
        XCTAssertEqual(try f4.print(match4)?.urlComponents, url)
        
        let f5 = ""/.hello/?.name(.string)

        url = URLComponents(string: "hello?name=ilya&page=2")!
        let match5 = try XCTUnwrap(f5.parse(URLRequestComponents(urlComponents: url)))
        XCTAssertEqual("\(match5)", #"ilya"#)
        
        url = URLComponents(string: "hello/ilya/world?name=ilya&page=2")!
        try XCTAssertNil(f5.parse(URLRequestComponents(urlComponents: url)))
        
        let f6 = ""/.user/.string*
        
        url = URLComponents(string: "user/ilya/?page=2")!
        var match6 = try XCTUnwrap(f6.parse(URLRequestComponents(urlComponents: url)))
        XCTAssertEqual("\(match6)", #"("ilya", "")"#)

        url = URLComponents(string: "user/ilya/repo/?page=2")!
        match6 = try XCTUnwrap(f6.parse(URLRequestComponents(urlComponents: url)))
        XCTAssertEqual("\(match6)", #"("ilya", "repo/")"#)

        let f7 = ""/.hello*?.name(.string)
        
        url = URLComponents(string: "hello?name=ilya&page=2")!
        var match7 = try XCTUnwrap(f7.parse(URLRequestComponents(urlComponents: url)))
        XCTAssertEqual("\(match7)", #"("", "ilya")"#)
        
        url = URLComponents(string: "hello/world/?name=ilya&page=2")!
        match7 = try XCTUnwrap(f7.parse(URLRequestComponents(urlComponents: url)))
        XCTAssertEqual("\(match7)", #"("world/", "ilya")"#)
    }
    
    func testURLRequestFormat() throws {
        let POST = ClosedPathFormat<Prelude.Unit>(httpMethod("POST"))
        let f1: URLFormat<((String, String), Int)> = POST/.user/.string/.repos/?.filter(.string)&.page(.int)

        let request = URLRequestComponents(
            method: "POST",
            urlComponents: URLComponents(string: "user/ilya/repos?filter=swift&page=2")!
        )
        let match = try XCTUnwrap(f1.parse(request))
        XCTAssertEqual("\(flatten(match))", #"("ilya", "swift", 2)"#)
        XCTAssertEqual(try f1.print(parenthesize("ilya", "swift", 2))?.urlComponents, request.urlComponents)
        XCTAssertEqual(try f1.print(parenthesize("ilya", "swift", 2))?.method, "POST")
    }
    
}
