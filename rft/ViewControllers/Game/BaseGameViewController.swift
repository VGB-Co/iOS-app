//
//  BaseGameViewController.swift
//  rft
//
//  Created by Levente Vig on 2018. 10. 16..
//  Copyright © 2018. Levente Vig. All rights reserved.
//

import RxCocoa
import RxSwift
import SVProgressHUD
import SnapKit
import SwiftyTimer
import UIKit

class BaseGameViewController: UIViewController {

	// MARK: - IBOutlets

	@IBOutlet var timerLabel: UILabel!
	@IBOutlet var gameWrapperView: UIView!

	// MARK: - Variables

	var difficultyLevel: DifficultyLevel?
	let exercises: BehaviorRelay<[Exercise]> = BehaviorRelay(value: [])
	let disposeBag = DisposeBag()
	var gameViewController: GameViewController?
	var currentExercise = 0
	var timer: Timer?
	var start: Date?
	var end: Date?

	// MARK: - View lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()
		RestClient.getExercises(for: difficultyLevel ?? .beginner, with: self)
		subscribeToNotifications()
		SVProgressHUD.show()
		timer = Timer.new(every: 1.ms) { [weak self] in
			let progress = Date().timeIntervalSince(self?.start ?? Date())
			let timeText = String(format: "%.2f", progress)
			self?.timerLabel.text = timeText
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}

	// MARK: - Init

	private func subscribeToNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(addGameView), name: Constants.Notifications.FinishedCurrentExecise, object: nil)
	}

	// MARK: - Setup game

	@objc private func addGameView() {

		guard currentExercise < exercises.value.count else {
			// TODO: Last exercise
			endTimer()

			timerLabel.blink()
			DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
				self.timerLabel.layer.removeAllAnimations()
			}

			gameViewController?.answerTextField.isUserInteractionEnabled = false
			gameViewController?.answerTextField.alpha = 0

			// TODO: Post results to service
			return
		}
		let exercise = exercises.value[currentExercise]
		gameViewController?.exercise.accept(exercise)
		currentExercise += 1
	}

	// MARK: - Manage game

	func startGame() {
		gameViewController = self.storyboard?.instantiateViewController(withIdentifier: Constants.ViewControllers.GameViewController) as? GameViewController
		gameWrapperView.addSubview(gameViewController?.view ?? UIView())
		gameViewController?.view.snp.makeConstraints({ make in
			make.edges.equalTo(gameWrapperView)
		})
		addGameView()
		startTimer()
	}

	// MARK: - Time measuring

	func startTimer() {
		start = Date()
		timer?.start(modes: RunLoop.Mode.default)
	}

	func endTimer() {
		timer?.invalidate()
		end = Date()
	}

	// MARK: - Navigation

	@IBAction func closeGame(_ sender: Any) {
		dismissView()
	}

	func dismissView() {
		let popup = UIAlertController(title: "Stop Game", message: "Are you sure you want to quit?", preferredStyle: .alert)
		let yesAction = UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
			self?.dismiss(animated: true, completion: nil)
		})
		let noAction = UIAlertAction(title: "No", style: .cancel, handler: { _ in
			popup.removeFromParent()
		})
		popup.addAction(yesAction)
		popup.addAction(noAction)
		self.present(popup, animated: true, completion: nil)
	}
}

// MARK: - RestClient delegate

extension BaseGameViewController: GameDelegate {
	func getExercisesDidSuccess(exercises: [Exercise]) {
		self.exercises.accept(exercises)
		startGame()
		SVProgressHUD.dismiss()
	}

	func getExercisesDidFail(with error: Error?) {
		NSLog("😢 get exercises did fail: \(String(describing: error))")
		SVProgressHUD.dismiss()
	}
}