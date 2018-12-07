//
//  Bugify.swift
//  Bugify
//
//  Created by Lukas on 03.12.18.
//  Copyright © 2018 Lukas. All rights reserved.
//

import Foundation

public class Bugify {
    static let shared = Bugify()
    
    func initialize(sdk: String) {
        print("asdf" + sdk)
    }
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            print("Device shaken")
        }
    }
}
