//
//  SettingsViewController.swift
//  rft
//
//  Created by Levente Vig on 2018. 10. 13..
//  Copyright © 2018. Levente Vig. All rights reserved.
//

import Firebase
import RxCocoa
import RxDataSources
import RxSwift
import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
	let settingsItems: BehaviorRelay<[SectionOfCustomData]> = BehaviorRelay(value: [])
    let disposeBag = DisposeBag()
	let dataSource = RxTableViewSectionedReloadDataSource<SectionOfCustomData>(configureCell: { (dataSource
		, tableView
		, indexPath
		, model) -> UITableViewCell in
		let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.SettingsCell) as! SettingsCell
		if let settingsModel = model as? SettingsItem {
			cell.settingsImageView.image = settingsModel.image
			cell.titleLabel.text = settingsModel.title
			cell.url = settingsModel.url
		}
		
		return cell
	})
    
    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
		self.navigationItem.largeTitleDisplayMode = .never
        setupTableView()
		setupDatasource()
    }
    
    func setupDatasource() {
        settingsItems.accept(SettingsItemProvider.sharedInstance().getSettingsItems())
		
		dataSource.titleForHeaderInSection = { dataSource, index in
			return dataSource.sectionModels[index].header
		}
        
        settingsItems
			.bind(to: tableView.rx.items(dataSource: dataSource))
			.disposed(by: disposeBag)
    }
    
    func setupTableView() {
        tableView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
			let cell = self?.tableView.cellForRow(at: indexPath) as! SettingsCell
            if indexPath == IndexPath(row: 1, section: 0){
                self?.logout()
			} else if indexPath.section == 1 {
				if let urlString = cell.url {
					if let url = URL(string: urlString) {
						UIApplication.shared.open(url, options: [:], completionHandler: nil)
					}
				}
			}
			
            self?.tableView.deselectRow(at: indexPath, animated: true)
            
        }).disposed(by: disposeBag)
        tableView.tableFooterView = UIView()
		tableView.rx.setDelegate(self).disposed(by: disposeBag)
    }
    
    
    
    // MARK: - Navigation
    @objc private func logout() {
        do {
            try Auth.auth().signOut()
            Constants.kAppDelegate.defaults.removeObject(forKey: Constants.UserDefaultsKeys.loggedInUser)
            performSegue(withIdentifier: Constants.Segues.Logout, sender: self)
            NSLog("✅ logout complete")
        } catch {
            NSLog("😢 logout failed")
        }
    }
    
}

extension SettingsViewController: SettingsCellBinding {
    func bind(to cell: SettingsCell, with model: SettingsItem) {
        cell.titleLabel.text = model.title
        cell.imageView?.image = model.image
		cell.url = model.url
    }
}

extension SettingsViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if section == 1 {
			return 44.0
		}
		return 0.0
	}
}
