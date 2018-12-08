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
    private var currentBugifyReportComposer: BugifyReportComposer?
    
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
        self.currentBugifyReportComposer = UIStoryboard(name: "BugifyStoryboard", bundle: nil).instantiateViewController(withIdentifier: "BugifyReportComposer") as! BugifyReportComposer
        
        // Capture & populate screenshot.
        let screenShot = captureScreen(view: topController.view)
        
        let navController = UINavigationController(rootViewController: self.currentBugifyReportComposer!)
        self.currentBugifyReportComposer?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(Bugify.sendFeedbackReport(sender:)))
        self.currentBugifyReportComposer?.title = "Report a problem"
        
        topController.present(navController, animated: true, completion: {
            self.currentBugifyReportComposer?.screenShotImageView.image = UIImage(cgImage: screenShot!.cgImage!)
            self.currentBugifyReportComposer?.screenShotImageView.layer.addShadow()
            self.currentBugifyReportComposer?.bugDescription.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
            NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
            
            let defaults = UserDefaults.standard
            self.currentBugifyReportComposer?.senderEmail.text = defaults.string(forKey: "bugifyDefaultSenderEmail") ?? ""
            
            self.currentBugifyReportComposer?.bugDescription.text = "Describe your problem..."
            self.currentBugifyReportComposer?.bugDescription.textColor = UIColor.lightGray
            self.currentBugifyReportComposer?.bugDescription.delegate = self.currentBugifyReportComposer
        })
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height - 16
            self.currentBugifyReportComposer?.bugDescriptionBottom.constant = (keyboardHeight - 16) * -1
            self.currentBugifyReportComposer?.screenShotImageViewBottom.constant = keyboardHeight
        }
    }
    
    @objc func sendFeedbackReport(sender: UIBarButtonItem) {
        // Save sender
        let defaults = UserDefaults.standard
        defaults.set(self.currentBugifyReportComposer?.senderEmail.text, forKey: "bugifyDefaultSenderEmail")
        
        // Send to server
        let url = URL(string: "http://www.stackoverflow.com")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main) {(response, data, error) in
            guard let data = data else { return }
            print(String(data: data, encoding: .utf8)!)
        }
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

extension CALayer {
    func addShadow() {
        self.shadowOffset = .zero
        self.shadowOpacity = 0.15
        self.shadowRadius = 6
        self.shadowColor = UIColor.black.cgColor
        self.masksToBounds = false
        self.borderColor = UIColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.2).cgColor
        self.borderWidth = 0.5
    }
}

class BugifyReportComposer: UIViewController, UITextViewDelegate {
    @IBOutlet weak var screenShotImageView: UIImageView!
    @IBOutlet weak var senderEmail: UITextField!
    @IBOutlet weak var bugDescription: UITextView!
    @IBOutlet weak var bugDescriptionBottom: NSLayoutConstraint!
    @IBOutlet weak var screenShotImageViewBottom: NSLayoutConstraint!
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Describe your problem..."
            textView.textColor = UIColor.lightGray
        }
    }
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            let callStack = Thread.callStackSymbols
            Bugify.shared.deviceShaken(callStack: callStack)
        }
    }
}
