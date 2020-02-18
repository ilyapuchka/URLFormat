import XCTest
@testable import URLFormat
@testable import VaporURLFormat
import Prelude
import Vapor
@testable import CommonParsers

class VaporURLFormatTests: XCTestCase {
    func testVaporRoute() throws {
        let app = try Application.runningTest(port: 8081) { (router) in
            router(GET/.hello/.string) { (request, s) -> String in
                return s
            }
        }
        
        try app.clientTest(.GET, "/hello/vapor", equals: "vapor")
    }
}

extension Application {
    static func runningTest(port: Int, routes: (Router) throws -> ()) throws -> Application {
        let router = EngineRouter.default()
        try routes(router)
        var services = Services.default()
        services.register(router, as: Router.self)
        let serverConfig = NIOServerConfig(
            hostname: "localhost",
            port: port,
            backlog: 8,
            workerCount: 1,
            maxBodySize: 128_000,
            reuseAddress: true,
            tcpNoDelay: true,
            supportCompression: false,
            webSocketMaxFrameSize: 1 << 14
        )
        services.register(serverConfig)
        let app = try Application.asyncBoot(config: .default(), environment: .xcode, services: services).wait()
        try app.asyncRun().wait()
        return app
    }
    
    @discardableResult
    func clientTest(
        _ method: HTTPMethod,
        _ path: String,
        beforeSend: (Request) throws -> () = { _ in },
        afterSend: (Response) throws -> ()
    ) throws -> Application {
        let config = try make(NIOServerConfig.self)
        let path = path.hasPrefix("/") ? path : "/\(path)"
        let req = Request(
            http: .init(method: method, url: "http://localhost:\(config.port)" + path),
            using: self
        )
        try beforeSend(req)
        let res = try FoundationClient.default(on: self).send(req).wait()
        try afterSend(res)
        return self
    }

    @discardableResult
    func clientTest(_ method: HTTPMethod, _ path: String, equals: String) throws -> Application {
        return try clientTest(method, path) { res in
            XCTAssertEqual(res.http.body.string, equals)
        }
    }
}

private extension Environment {
    static var xcode: Environment {
        return .init(name: "xcode", isRelease: false, arguments: ["xcode"])
    }
}

private extension HTTPBody {
    var string: String {
        guard let data = self.data else {
            return "<streaming>"
        }
        return String(data: data, encoding: .ascii) ?? "<non-ascii>"
    }
}

private extension Data {
    var utf8: String? {
        return String(data: self, encoding: .utf8)
    }
}
