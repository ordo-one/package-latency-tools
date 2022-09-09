import LatencyStatistics

func parseNumbersFromString(_ content: String) -> [Int] {
    let stringNumbers = content.split { char in
        if char.isNumber {
            return false
        } else {
            return true
        }
    }
    return stringNumbers.map { Int($0)! }
}

func main() {
    let argc = CommandLine.argc
    guard argc == 2 else {
        print("There should be one argument - file name or '-' for reading from stdin")
        return
    }

    do {
        var statistics = LatencyStatistics()
        let fileName = CommandLine.arguments[1]

        if fileName == "-" {
            while let content = readLine(strippingNewline: true) {
                let measurements = parseNumbersFromString(content)

                for input in measurements {
                    statistics.add(input)
                }
            }
        } else {
            let content = try String(contentsOfFile: fileName)

            let measurements = parseNumbersFromString(content)

            for input in measurements {
                statistics.add(input)
            }
        }

        print(statistics.output())
    } catch {
        print(error)
        return
    }
}

main()
