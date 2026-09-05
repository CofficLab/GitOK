import XCTest
@testable import KitSuperLog
import Combine

/// KitSuperLog 覆盖率补充：Duration→ms、静态 log 入口、日志数量上限、
/// 泛型类型 author、后台线程 isMain。
final class SuperLogCoverageTests: XCTestCase {

    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        cancellables = []
        MagicLogger.clearLogs()
    }

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Duration → ms

    private struct Meter: SuperLog {}

    func testDurationToMilliseconds() {
        XCTAssertEqual(Meter.ms(.zero), "0.00")
        XCTAssertEqual(Meter.ms(.seconds(1)), "1000.00")
        XCTAssertEqual(Meter.ms(.milliseconds(1234)), "1234.00")
        XCTAssertEqual(Meter.ms(.milliseconds(1)), "1.00")
    }

    // MARK: - Static log entry

    func testStaticLogWithExplicitLevel() {
        let expectation = expectation(description: "static log received")

        MagicLogger.shared.$logs
            .dropFirst()
            .sink { logs in
                guard let entry = logs.last else { return }
                XCTAssertEqual(entry.level, .warning)
                XCTAssertEqual(entry.originalMessage, "static warning")
                // caller 经 fileName(from:) 归一化：去掉目录与扩展名。
                XCTAssertEqual(entry.caller, "SuperLogCoverageTests")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        MagicLogger.log("static warning", level: .warning)
        wait(for: [expectation], timeout: 2)
    }

    // MARK: - 各级别便捷方法

    func testConvenienceLevelMethods() {
        let staticExpectation = expectation(description: "static convenience levels")
        staticExpectation.expectedFulfillmentCount = 3
        MagicLogger.shared.$logs
            .dropFirst()
            .sink { logs in
                guard let entry = logs.last else { return }
                switch entry.level {
                case .warning: XCTAssertEqual(entry.originalMessage, "sw")
                case .error: XCTAssertEqual(entry.originalMessage, "se")
                case .debug: XCTAssertEqual(entry.originalMessage, "sd")
                default: XCTFail("unexpected level \(entry.level)")
                }
                staticExpectation.fulfill()
            }
            .store(in: &cancellables)

        MagicLogger.warning("sw")
        MagicLogger.error("se")
        MagicLogger.debug("sd")
        wait(for: [staticExpectation], timeout: 2)

        // 实例级便捷方法（走 addLog 的 os.Logger 各分支）。
        let instanceExpectation = expectation(description: "instance convenience levels")
        instanceExpectation.expectedFulfillmentCount = 3
        let logger = MagicLogger(app: "convenience")
        logger.$logs
            .dropFirst()
            .sink { logs in
                guard let entry = logs.last else { return }
                switch entry.level {
                case .warning: XCTAssertEqual(entry.originalMessage, "iw")
                case .error: XCTAssertEqual(entry.originalMessage, "ie")
                case .debug: XCTAssertEqual(entry.originalMessage, "id")
                default: XCTFail("unexpected level \(entry.level)")
                }
                instanceExpectation.fulfill()
            }
            .store(in: &cancellables)

        logger.warning("iw")
        logger.error("ie")
        logger.debug("id")
        wait(for: [instanceExpectation], timeout: 2)
    }

    // MARK: - Max log count trimming

    func testMaxLogCountTrimsToLimit() {
        let logger = MagicLogger(app: "trim-test")

        for index in 0..<1005 {
            logger.log("msg-\(index)", level: .info, caller: "Test.swift", line: index)
        }

        // addLog 在 main queue 异步追加；轮询直到裁剪完成。
        let deadline = Date().addingTimeInterval(5)
        while logger.logs.count != 1000 && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }

        XCTAssertEqual(logger.logs.count, 1000, "日志数量应被裁剪到上限 1000")
        XCTAssertEqual(logger.logs.first?.originalMessage, "msg-5")
        XCTAssertEqual(logger.logs.last?.originalMessage, "msg-1004")
    }

    func testLogsBelowLimitAreKept() {
        let logger = MagicLogger(app: "keep-test")
        for index in 0..<3 {
            logger.log("keep-\(index)", level: .debug, caller: "Test.swift", line: index)
        }

        let deadline = Date().addingTimeInterval(2)
        while logger.logs.count < 3 && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }

        XCTAssertEqual(logger.logs.count, 3)
        XCTAssertEqual(logger.logs.map(\.level), [.debug, .debug, .debug])
    }

    // MARK: - Generic type author

    private class GenericLog<T>: SuperLog {}

    func testGenericTypeAuthorStripsGenericParameters() {
        XCTAssertEqual(GenericLog<Int>.author, "GenericLog")
        XCTAssertEqual(GenericLog<String>.author, "GenericLog")
    }

    // MARK: - isMain off the main thread

    func testIsMainOnBackgroundThread() {
        let expectation = expectation(description: "background thread")
        DispatchQueue.global().async {
            let manager = TestUserManager()
            XCTAssertFalse(manager.isMain)
            // 非主线程访问 t 触发 currentQosDescription 的 pthread_get_qos_class_np 路径。
            _ = manager.t
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }

    // MARK: - Instance convenience strings

    func testInstanceConvenienceStrings() {
        let manager = TestUserManager()
        XCTAssertEqual(manager.className, "TestUserManager")
        XCTAssertEqual(manager.r("x"), " ➡️ x")
        // onAppear / onInit 静态字符串包含线程前缀。
        XCTAssertTrue(TestUserManager.onAppear.contains("OnAppear"))
        XCTAssertTrue(TestUserManager.onInit.contains("Init"))
        XCTAssertEqual(manager.a, TestUserManager.a)
        XCTAssertEqual(manager.i, TestUserManager.i)
    }
}
