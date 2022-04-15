import Foundation

public struct LatencyStatistics
{
    var l50, l80, l99, l99d9, l100: Int64
    var measurements: [Int64]

    public init()
    {
        l50 = 0
        l80 = 0
        l99 = 0
        l99d9 = 0
        l100 = 0
        measurements = [Int64]();
    }

    public mutating func reserveCapacity(_ capacity: Int)
    {
        measurements.reserveCapacity(capacity)
    }
    
    public mutating func add(_ measurement: Int64)
    {
        measurements.append(measurement)
    }
    
    public mutating func reset()
    {
        l50 = 0
        l80 = 0
        l99 = 0
        l99d9 = 0
        l100 = 0
        measurements = []
    }
    
    public mutating func calculate()
    {
        let size = measurements.count
        
        guard size != 0 else {
            reset()
            return
        }
        
        measurements.sort()

        let p50 = 50 * size / 100
        l50 = measurements[p50]

        let p80 = 80 * size / 100
        l80 = measurements[p80]

        let p99 = 99 * size / 100
        l99 = measurements[p99]

        let p99d9 = 999 * size / 1000
        l99d9 = measurements[p99d9]

        l100 = measurements.last!
    }
    
    public mutating func process(fileName: String) {
        do {
            let content = try String(contentsOfFile: fileName)

            let stringNumbers = content.split() { char in
                if char.isNumber {
                    return false
                } else {
                    return true
                }
            }

            measurements = stringNumbers.map { Int64($0)! }
            
            calculate()
            
        } catch {
            print(error)
            return
        }
    }

    public func output() -> String
    {
        return "  50% <= \(l50)\n  80% <= \(l80)\n  99% <= \(l99)\n99.9% <= \(l99d9)\n 100% <= \(l100)"
    }
    
    private func format(_ number: Int64) -> String
    {
        return "\(number) usec"
    }
    
    public func printStatistics()
    {
        print("  50% <= \(format(l50))")
        print("  80% <= \(format(l80))")
        print("  99% <= \(format(l99))")
        print("99.9% <= \(format(l99d9))")
        print(" 100% <= \(format(l100))")
    }
    
    public func printRawData()
    {
        print("[\(measurements.count)](", separator: "", terminator: "");
        for a in measurements {
            print("\(a)", separator: "", terminator: "")
        }
        print(")")
    }
}
