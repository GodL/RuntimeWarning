// The Swift Programming Language
// https://docs.swift.org/swift-book
#if DEBUG

import os

private let dso = {
    let count = _dyld_image_count()
    for i in 0..<count {
      if let name = _dyld_get_image_name(i) {
        let swiftString = String(cString: name)
        if swiftString.hasSuffix("/SwiftUI") {
          if let header = _dyld_get_image_header(i) {
            return UnsafeMutableRawPointer(mutating: UnsafeRawPointer(header))
          }
        }
      }
    }
    return UnsafeMutableRawPointer(mutating: #dsohandle)
}()

private func rw(category: String) -> (UnsafeMutableRawPointer, OSLog) {
    return (dso, OSLog(subsystem: "com.apple.runtime-issues", category: category))
}

#endif

public func runtimeWarning(
    category: String = "RuntimeWarning",
    _ message: @autoclosure () -> StaticString,
    _ args: @autoclosure () -> [CVarArg] = []
) {
#if DEBUG
    let message = message()
    let rw = rw(category: category)
    unsafeBitCast(
        os_log as (OSLogType, UnsafeRawPointer, OSLog, StaticString, CVarArg...) -> Void,
        to: ((OSLogType, UnsafeRawPointer, OSLog, StaticString, [CVarArg]) -> Void).self
    )(.fault, rw.0, rw.1, message, args())
#endif
}
