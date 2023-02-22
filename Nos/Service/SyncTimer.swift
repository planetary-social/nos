//
//  SyncTimer.swift
//  Nos
//
//  Created by Christopher Jorgensen on 2/22/23.
//

import Foundation
import Combine

final class SyncTimer {
    let currentTimePublisher = Timer.TimerPublisher(interval: 1.0, runLoop: .main, mode: .default)
    let cancellable: AnyCancellable?

    init() {
        self.cancellable = currentTimePublisher.connect() as? AnyCancellable
    }

    deinit {
        self.cancellable?.cancel()
    }
}
