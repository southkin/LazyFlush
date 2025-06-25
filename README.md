# LazyFlush

[![](https://img.shields.io/badge/platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS-blue)](https://github.com/yourname/LazyFlush)
[![](https://img.shields.io/badge/spm-supported-orange)](https://swift.org/package-manager/)
[![](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)

LazyFlush provides a powerful Combine `.buffer(...)` operator overload that batches publisher outputs according to three “procrastination” rules:

1. **Buffer Capacity**: Flush immediately once the buffer reaches a given size.  
2. **Max Burst Time**: Flush if the first element in the batch has waited longer than a threshold.  
3. **Silence Timeout**: Flush after a period of inactivity (no new elements).

> *“If you can put it off, do it—until you absolutely have to.”*

---

## Features

- **Flexible Buffering**  
  Buffer outputs and emit in batches when any of three conditions is met.

- **Combine‐Native**  
  No external dependencies—just import and use alongside your existing publishers.

- **Cross‐Platform**  
  Supports iOS 15+, macOS 12+, tvOS 15+, watchOS 8+.

- **Lightweight & Zero‐Config**  
  Sensible defaults; customize just the time intervals or buffer size you need.

---

## Usage
```swift
import Combine
import LazyFlush

let source = PassthroughSubject<Int, Never>()
var cancellables = Set<AnyCancellable>()

source
  .buffer(
    silence: .seconds(1),        // flush after 1s of inactivity
    maxBurst: .seconds(5),       // or after 5s of first element waiting
    bufferSize: 10,              // or when 10 items accumulate
    scheduler: DispatchQueue.main
  )
  .sink { batch in
    print("Received batch:", batch)
  }
  .store(in: &cancellables)

```

---

## API
```swift
func buffer<S: Scheduler>(
  silence: S.SchedulerTimeType.Stride,
  maxBurst: S.SchedulerTimeType.Stride = .zero,
  bufferSize: Int = 0,
  scheduler: S
) -> AnyPublisher<[Output], Failure>
```
- silence
  >Time to wait after the last element before emitting the buffered batch.
- maxBurst
  >Maximum wait time after the first element arrives. If zero (default), this is disabled.
- bufferSize
  >Maximum items in the batch before immediate emission. If zero (default), this is disabled.
- scheduler
  >The Combine scheduler (DispatchQueue, RunLoop, etc.) used to manage timers.
---

## Installation

Add LazyFlush to your project via Swift Package Manager:

1. In Xcode, choose **File → Add Packages…**  
1. Enter the repository URL : https://github.com/southkin/LazyFlush.git
1. Select the desired version or branch.

Or in your `Package.swift`:

```swift
dependencies: [
 .package(url: "https://github.com/southkin/LazyFlush.git", from: "1.0.0"),
],
targets: [
 .target(
     name: "YourApp",
     dependencies: ["LazyFlush"]
 ),
]