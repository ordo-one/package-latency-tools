#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
import Glibc
#else
#error("Unsupported Platform")
#endif

public class LatencyTimer {
    
    let name: String;
    
    var measurements: Array<(String, UInt64)>;
    
    public init(name: String) {
        self.name = name;
        self.measurements = Array<(String, UInt64)>();
        self.measurements.reserveCapacity(10);
    }
    
    public func reserveCapacity(_ capacity: Int) {
        measurements.reserveCapacity(capacity)
    }
    
    public static func getTimestamp() -> UInt64
    {
        var tm = timeval();
        gettimeofday(&tm, nil);
        return UInt64(tm.tv_sec) * 1_000_000 + UInt64(tm.tv_usec);
    }
    
    public func checkpoint(label: String)
    {
        measurements.append((label, LatencyTimer.getTimestamp()));
    }
 
    public func output() -> String
    {
        if (measurements.isEmpty) {
            return "<no measurements>";
        }
        var result = "";
        var i = 0;
        while (i + 1 < measurements.count) {
            let diff = measurements[i + 1].1 - measurements[i].1;
            result.append("\(measurements[i].0) - \(measurements[i + 1].0): \(diff) usec\n");
            i += 1;
        }
        return "";
    }
}
