#if false
//
//  FeedbackSubmissionViewController.swift
//  FeedbackKit
//
//  Created by Tim Jots on 5/15/19.
//

import Foundation
import UIKit

public class FeedbackSubmissionViewController: UIViewController {

    public var feedbackManager: FeedbackManager?

    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var textView: UITextView!

    public override func viewDidLoad() {
        super.viewDidLoad()

        submitButton.addTarget(self, action: #selector(submitFeedback), for: .touchUpInside)
    }

    @objc func submitFeedback() {
        guard let feedback = textView.text, !feedback.isEmpty else {
            let alert = UIAlertController(title: "Error", message: "Feedback cannot be empty.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        feedbackManager?.submit(feedback: feedback) { [weak self] success in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: success ? "Success" : "Failure",
                                              message: success ? "Thank you for your feedback!" : "Failed to submit feedback.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }
}
#endif
