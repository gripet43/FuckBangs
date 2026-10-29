import Foundation
import Darwin

struct ResourceProbe {
    private var lastCPUSeconds: Double = 0
    private var lastWall = Date()

    mutating func sample() -> (cpuPercent: Double, residentMB: Double) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)

        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), rebound, &count)
            }
        }

        guard result == KERN_SUCCESS else { return (0, 0) }

        let cpuSeconds = Double(info.user_time.seconds + info.system_time.seconds)
            + Double(info.user_time.microseconds + info.system_time.microseconds) / 1_000_000
        let resident = Double(info.resident_size) / 1024 / 1024

        let now = Date()
        let wall = now.timeIntervalSince(lastWall)
        let delta = cpuSeconds - lastCPUSeconds
        lastWall = now
        lastCPUSeconds = cpuSeconds

        guard wall > 0 else { return (0, resident) }
        return (max(0, delta / wall * 100), resident)
    }
}

func nbLog(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}
