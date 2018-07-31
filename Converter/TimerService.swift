//
//  TimerService.swift
//  Converter
//
//  Created by  Ivan Ushakov on 30/07/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import Foundation

protocol TimerServiceType {
    func scheduledTimer(withTimeInterval: TimeInterval, block: @escaping () -> Void)
}

class TimerService: TimerServiceType {

    private var entries = Dictionary<TimeInterval, Entry>()

    deinit {
        self.entries.forEach { $0.value.cancel() }
    }

    func scheduledTimer(withTimeInterval: TimeInterval, block: @escaping () -> Void) {
        if let entry = self.entries[withTimeInterval] {
            entry.append(block)
            return
        }

        let timer = Timer.scheduledTimer(withTimeInterval: withTimeInterval, repeats: true) { _ in
            if let entry = self.entries[withTimeInterval] {
                entry.notify()
            }
        }
        self.entries[withTimeInterval] = Entry(timer: timer, block: block)
    }
}

private class Entry {
    private let timer: Timer
    private var blocks: [() -> Void]

    init(timer: Timer, block: @escaping () -> Void) {
        self.timer = timer
        self.blocks = [block]
    }

    func append(_ block: @escaping () -> Void) {
        self.blocks.append(block)
    }

    func notify() {
        self.blocks.forEach { $0() }
    }

    func cancel() {
        self.timer.invalidate()
        self.blocks.removeAll()
    }
}

