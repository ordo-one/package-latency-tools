#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
import Glibc
#else
#error("Unsupported Platform")
#endif

public final class LatencyTimer {

    let name: String

    var measurements: [(String, UInt64)]

    public init(name: String) {
        self.name = name
        self.measurements = [(String, UInt64)]()
        self.measurements.reserveCapacity(10)
    }

    public func reserveCapacity(_ capacity: Int) {
        measurements.reserveCapacity(capacity)
    }

    @inlinable
    @inline(__always)
    public static func getTimestamp() -> UInt64 {
        var ts = timespec()
        let result = clock_gettime(CLOCK_REALTIME, &ts)

        guard result == 0 else {
            fatalError("Failed to get current time in clock_gettime(), errno = \(errno)")
        }

        return UInt64(ts.tv_sec) * 1_000_000 + UInt64(ts.tv_nsec / 1_000)
    }

    public func checkpoint(label: String) {
        measurements.append((label, LatencyTimer.getTimestamp()))
    }

    public func output() -> String {
        if measurements.isEmpty {
            return "<no measurements>"
        }
        var result = ""
        var i = 0
        while i + 1 < measurements.count {
            let diff = measurements[i + 1].1 - measurements[i].1
            result.append("\(measurements[i].0) - \(measurements[i + 1].0): \(diff) usec\n")
            i += 1
        }
        return ""
    }
}
