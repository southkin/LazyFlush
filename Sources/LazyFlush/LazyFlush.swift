// The Swift Programming Language
// https://docs.swift.org/swift-book
import Combine
import Foundation

extension Publisher {
    func buffer<S: Scheduler>(
        silence: S.SchedulerTimeType.Stride,
        maxBurst: S.SchedulerTimeType.Stride = .zero,
        bufferSize: Int = 0,
        scheduler: S
    ) -> AnyPublisher<[Output], Failure> {
        let subject = PassthroughSubject<[Output], Failure>()
        var buffer = [Output]()
        let lock = NSLock()
        var burstTimer: Cancellable?
        var silentTimer: Cancellable?

        func flush() {
            lock.lock()
            let batch = buffer
            buffer.removeAll()
            lock.unlock()
            if !batch.isEmpty {
                subject.send(batch)
            }
            burstTimer?.cancel()
            silentTimer?.cancel()
        }

        let sub = self
            .sink(
                receiveCompletion: { comp in
                    flush()
                    subject.send(completion: comp)
                },
                receiveValue: { value in
                    let isFirst = lock.withLock {
                        let wasEmpty = buffer.isEmpty
                        buffer.append(value)
                        return wasEmpty
                    }

                    if bufferSize > 0, buffer.count >= bufferSize {
                        flush()
                        return
                    }

                    if isFirst, maxBurst > .zero {
                        burstTimer?.cancel()
                        burstTimer = scheduler.schedule(
                            after: scheduler.now.advanced(by: maxBurst)
                        ) { flush() } as? any Cancellable
                    }

                    silentTimer?.cancel()
                    silentTimer = scheduler.schedule(
                        after: scheduler.now.advanced(by: silence)
                    ) { flush() } as? any Cancellable
                }
            )

        return subject
            .handleEvents(receiveCancel: {
                sub.cancel()
                burstTimer?.cancel()
                silentTimer?.cancel()
            })
            .eraseToAnyPublisher()
    }
}

extension NSLock {
    func withLock<T>(_ work: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try work()
    }
}
