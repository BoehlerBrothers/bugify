//
//  Bugif.swift
//  BugifyDemo
//
//  Created by Lukas on 07.12.18.
//  Copyright © 2018 Lukas. All rights reserved.
//

import Foundation
import UIKit

class Bugify {
    static let shared = Bugify(apiKey: Bugify.apiKey)
    static var apiKey = ""
    
    private var currentlyEditing = false
    
    init(apiKey: String) {
        Bugify.apiKey = apiKey
    }
    
    func initialize() {
        print("YEAH!!!!")
    }
    
    func deviceShaken(callStack: [String]) {
        guard let topController = getTopController() else {
            return
        }
        
        showDebugReport(topController: topController, callStack: callStack)
    }
    
    func showDebugReport(topController: UIViewController, callStack: [String]) {
        let bugifyReportComposerViewController = UIStoryboard(name: "BugifyStoryboard", bundle: nil).instantiateViewController(withIdentifier: "BugifyReportComposer") as! BugifyReportComposer
        
        // Capture & populate screenshot.
        let screenShot = captureScreen(view: topController.view)
        
        topController.present(bugifyReportComposerViewController, animated: true, completion: {
            bugifyReportComposerViewController.screenShotImageView.image = UIImage(cgImage: screenShot!.cgImage!)
        })
    }
    
    func getTopController() -> UIViewController? {
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return nil
    }
    
    private func captureScreen(view: UIView) -> UIImage? {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

class BugifyReportComposer: UIViewController {
    @IBOutlet weak var screenShotImageView: UIImageView!
    
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            let callStack = Thread.callStackSymbols
            Bugify.shared.deviceShaken(callStack: callStack)
        }
    }
}
