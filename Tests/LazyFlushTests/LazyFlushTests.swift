import XCTest
import Combine
@testable import LazyFlush

final class LazyFlushTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        super.tearDown()
    }

    /// 1. bufferSize reached -> split into batches of size 3
    @MainActor func testBufferSizeFlush() {
        let expectation = self.expectation(description: "Buffer size flush twice")
        expectation.expectedFulfillmentCount = 2
        let source = PassthroughSubject<Int, Never>()
        var result: [[Int]] = []

        source
            .buffer(silence: .seconds(1), maxBurst: .seconds(1), bufferSize: 3, scheduler: DispatchQueue.main)
            .sink { batch in
                result.append(batch)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // send two full batches
        source.send(1)
        source.send(2)
        source.send(3)
        source.send(4)
        source.send(5)
        source.send(6)

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(result, [[1,2,3], [4,5,6]])
    }

    /// 2. first element -> maxBurst elapsed -> flush, twice
    @MainActor func testMaxBurstFlushMultiple() {
        let expectation = self.expectation(description: "Max burst flush twice")
        expectation.expectedFulfillmentCount = 2
        let source = PassthroughSubject<String, Never>()
        let maxBurst: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(200)
        var result: [[String]] = []

        source
            .buffer(silence: .seconds(1), maxBurst: maxBurst, bufferSize: 0, scheduler: DispatchQueue.main)
            .sink { batch in
                result.append(batch)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // first burst
        source.send("A")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            source.send("B")
        }
        // second burst after first flush
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            source.send("C")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            source.send("D")
        }

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(result, [["A","B"], ["C","D"]])
    }

    /// 3. silence elapsed -> flush, twice
    @MainActor func testSilenceFlushMultiple() {
        let expectation = self.expectation(description: "Silence flush twice")
        expectation.expectedFulfillmentCount = 2
        let source = PassthroughSubject<Int, Never>()
        var result: [[Int]] = []

        source
            .buffer(silence: .seconds(0.2), maxBurst: .zero, bufferSize: 0, scheduler: DispatchQueue.main)
            .sink { batch in
                result.append(batch)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // first batch
        source.send(1)
        source.send(2)
        source.send(3)
        // second batch after silence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            source.send(4)
            source.send(5)
            source.send(6)
        }

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(result, [[1,2,3], [4,5,6]])
    }

    /// 4. default silence only, flush twice
    @MainActor func testDefaultSilenceMultiple() {
        let expectation = self.expectation(description: "Default silence flush twice")
        expectation.expectedFulfillmentCount = 2
        let source = PassthroughSubject<Character, Never>()
        var result: [[Character]] = []

        source
            .buffer(silence: .seconds(0.1), scheduler: DispatchQueue.main)
            .sink { batch in
                result.append(batch)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // first
        source.send("X")
        // second after silence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            source.send("Y")
        }

        waitForExpectations(timeout: 0.5)
        XCTAssertEqual(result, [["X"], ["Y"]])
    }
}
