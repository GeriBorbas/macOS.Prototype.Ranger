//
//  PostgresTime.swift
//  PostgresClientKit
//
//  Copyright 2019 David Pitfield and the PostgresClientKit contributors
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// Represents a Postgres `TIME` value, which consists of the following components:
///
/// - hour
/// - minute
/// - seconds (and fractional seconds)
///
/// For example, `16:25:19.365`.
///
/// Like Foundation `DateComponents`, PostgresClientKit records fractional seconds in nanoseconds.
/// However, [due to a bug](https://stackoverflow.com/questions/23684727) in the Foundation
/// `DateFormatter` class, only 3 fractional digits are preserved (millisecond resolution) in
/// values sent to and received from the Postgres server.
public struct PostgresTime: PostgresValueConvertible, Equatable, CustomStringConvertible {
    
    /// Creates a `PostgresTime` from components.
    ///
    /// For example, to represent `16:25:19.365`:
    ///
    ///     let time = PostgresTime(hour: 16,
    ///                             minute: 25,
    ///                             second: 19,
    ///                             nanosecond: 365000000)
    ///
    /// - Parameters:
    ///   - hour: the hour value
    ///   - minute: the minute value
    ///   - second: the second value
    ///   - nanosecond: the nanosecond value
    public init?(hour: Int,
                 minute: Int,
                 second: Int,
                 nanosecond: Int = 0) {
        
        var dc = DateComponents()
        dc.hour = hour
        dc.minute = minute
        dc.second = second
        dc.nanosecond = nanosecond
        
        guard Postgres.isValidDate(dc) else {
            return nil
        }
        
        inner = Inner(dateComponents: dc)
    }
    
    /// Creates a `PostgresTime` by interpreting a `Date` in a specified time zone to obtain the
    /// hour, minute, second, and fractional second components, and discarding the year, month,
    /// and day components.
    ///
    /// (Foundation `Date` instances represent moments in time, not *(year, month, day)* tuples.)
    ///
    /// - Parameters:
    ///   - date: the moment in time
    ///   - timeZone: the time zone in which to interpret that moment
    public init(date: Date, in timeZone: TimeZone) {
        
        let dc = Postgres.enUsPosixUtcCalendar.dateComponents(in: timeZone, from: date)
        
        guard let hour = dc.hour,
            let minute = dc.minute,
            let second = dc.second,
            let nanosecond = dc.nanosecond else {
                // Can't happen.
                preconditionFailure("Invalid date components from \(date): \(dc)")
        }
        
        self.init(hour: hour,
                  minute: minute,
                  second: second,
                  nanosecond: nanosecond)!
    }
    
    /// Creates a `PostgresTime` from a string.
    ///
    /// The string must conform to either the [date format pattern](
    /// http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)
    /// `HH:mm:ss.SSS` (for example, `16:25:19.365`) or
    /// `HH:mm:ss` (for example, `16:25:19`).
    ///
    /// - Parameter string: the string
    public init?(_ string: String) {
        
        guard let date =
            PostgresTime.formatter.date(from: string) ??
            PostgresTime.formatter2.date(from: string) else {
                return nil
        }
        
        self.init(date: date, in: PostgresTime.formatter.timeZone)
    }
    
    /// A `DateComponents` for this `PostgresTime`.
    ///
    /// The returned value has the following components set:
    ///
    /// - `hour`
    /// - `minute`
    /// - `second`
    /// - `nanosecond`
    public var dateComponents: DateComponents {
        return inner.dateComponents
    }
    
    /// Creates a `Date` by interpreting this `PostgresTime` in a specified time zone, setting the
    /// year component to 2000 and the month and day components to 1.
    ///
    /// (Foundation `Date` instances represent moments in time, not *(year, month, day)* tuples.)
    ///
    /// - Parameter timeZone: the time zone
    /// - Returns: the moment in time
    public func date(in timeZone: TimeZone) -> Date {
        var dc = inner.dateComponents
        dc.calendar = Postgres.enUsPosixUtcCalendar
        dc.timeZone = timeZone
        dc.year = 2000
        dc.month = 1
        dc.day = 1
        return Postgres.enUsPosixUtcCalendar.date(from: dc)! // validated components on the way in
    }
    
    
    //
    // MARK: PostgresValueConvertible
    //
    
    /// A `PostgresValue` for this `PostgresTime`.
    public var postgresValue: PostgresValue {
        return inner.postgresValue
    }
    
    
    //
    // MARK: Equatable
    //
    
    /// True if `lhs.postgresValue == rhs.postgresValue`.
    public static func == (lhs: PostgresTime, rhs: PostgresTime) -> Bool {
        return lhs.postgresValue == rhs.postgresValue
    }

    
    //
    // MARK: CustomStringConvertible
    //
    
    /// A string representation of this `PostgresTime`.
    ///
    /// Equivalent to `String(describing: postgresValue)`.
    public var description: String {
        return String(describing: postgresValue)
    }
    
    
    //
    // MARK: Implementation
    //

    /// Formats Postgres `TIME` values.
    private static let formatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Postgres.enUsPosixUtcCalendar
        df.dateFormat = "HH:mm:ss.SSS"
        df.locale = Postgres.enUsPosixLocale
        df.timeZone = Postgres.utcTimeZone
        return df
    }()
    
    /// Alternative formatter for parsing Postgres `TIME` values.
    private static let formatter2: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Postgres.enUsPosixUtcCalendar
        df.dateFormat = "HH:mm:ss"
        df.locale = Postgres.enUsPosixLocale
        df.timeZone = Postgres.utcTimeZone
        return df
    }()
    
    // Inner class to allow the struct to be immutable yet have lazily instantiated properties.
    private let inner: Inner
    
    private class Inner {
        
        fileprivate init(dateComponents: DateComponents) {
            self.dateComponents = dateComponents
        }
        
        fileprivate let dateComponents: DateComponents
        
        fileprivate lazy var postgresValue: PostgresValue = {
            var dc = dateComponents
            dc.calendar = Postgres.enUsPosixUtcCalendar
            dc.timeZone = Postgres.utcTimeZone
            dc.year = 2000
            dc.month = 1
            dc.day = 1
            let d = Postgres.enUsPosixUtcCalendar.date(from: dc)!
            let s = PostgresTime.formatter.string(from: d)
            return PostgresValue(s)
        }()
    }
}

public extension Date {
    
    /// Creates a `PostgresTime` by interpreting this `Date` in a specified time zone.
    ///
    /// Equivalent to `PostgresTime(date: self, in: timeZone)`.
    ///
    /// - Parameter timeZone: the time zone
    /// - Returns: the `PostgresTime`
    func postgresTime(in timeZone: TimeZone) -> PostgresTime {
        return PostgresTime(date: self, in: timeZone)
    }
}

// EOF
