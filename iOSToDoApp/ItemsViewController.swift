//
//  ItemsViewController.swift
//  iOSToDoApp
//
//  Created by CMR on 20/09/2018.
//

import UIKit
import RealmSwift

class ItemsViewController: UIViewController {
//    let realm: Realm
    var items: List<Item>?
    var project: Project?
    var notificationToken: NotificationToken?
    
    let tableView = UITableView()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
//        var syncConfig = SyncUser.current!.configuration(realmURL: Constants.REALM_URL, fullSynchronization: true, enableSSLValidation: false, urlPrefix: nil)
//        syncConfig.objectTypes = [Item.self]
        
//        self.realm = try! Realm(configuration: syncConfig)
//        self.items = realm.objects(Item.self).sorted(byKeyPath: "timestamp", ascending: false)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        title = project?.name ?? "Unnamed Project"
        items = project?.items

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped)),
            UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logoutButtonTapped))
        ]
        
        tableView.frame = self.view.frame
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        
        notificationToken = items?.observe { [weak self] changes in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                // Query rsults have changed, so apply them to the UITableView
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                tableView.endUpdates()
            case .error(let error):
                fatalError("\(error)")
            }
        }
    }
    deinit {
        notificationToken?.invalidate()
    }
    
    @objc func addButtonTapped() {
        let alertController = UIAlertController(title: "Add Item", message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            let textField = alertController.textFields![0] as UITextField
            let item = Item()
            item.body = textField.text ?? ""
            
            try! self.project?.realm?.write {
                self.project?.items.append(item)
            }
            // do something with textField
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addTextField(configurationHandler: { textField in
            textField.placeholder = "New Item Text"
        })
        self.present(alertController, animated: true)
    }
    @objc func logoutButtonTapped() {
        let alertController = UIAlertController(title: "Logout", message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Yes, Logout", style: .destructive, handler: { _ in
            SyncUser.current?.logOut()
            self.navigationController?.setViewControllers([WelcomeViewController()], animated: true)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true)
    }
}

extension ItemsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
        let item = (items?[indexPath.row])!
        cell.textLabel?.text = item.body
        cell.accessoryType = item.isDone ? UITableViewCell.AccessoryType.checkmark : UITableViewCell.AccessoryType.none
        return cell
    }
}

extension ItemsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = items?[indexPath.row]
        try! self.project?.realm?.write {
            item!.isDone.toggle()
        }
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let item = items?[indexPath.row]
        try! self.project?.realm?.write {
            self.project?.realm?.delete(item!)
        }
    }
}
