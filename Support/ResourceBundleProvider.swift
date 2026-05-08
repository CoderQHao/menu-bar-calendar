//
//  ResourceBundleProvider.swift
//  MenuBarCalendar
//
//  Created by DongQing on 2026/5/8.
//

import Foundation

enum ResourceBundleProvider {
    static var bundle: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        return Bundle(for: BundleSentinel.self)
        #endif
    }
}

private final class BundleSentinel {}
