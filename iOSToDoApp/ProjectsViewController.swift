//
//  ProjectsViewController.swift
//  iOSToDoApp
//
//  Created by CMR on 20/09/2018.
//

import UIKit
import RealmSwift

class ProjectsViewController: UIViewController {
    let realm: Realm
    let projects: Results<Project>
    var subscription: SyncSubscription<Project>!
    var subscriptionToken: NotificationToken?
    var notificationToken: NotificationToken?
    
    
    var tableView = UITableView()
    let activityIndicator = UIActivityIndicatorView()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        print(#function)
//        realm = try! Realm(configuration: SyncUser.current!.configuration(realmURL: Constants.REALM_URL, fullSynchronization: true, enableSSLValidation: false, urlPrefix: nil))
        realm = try! Realm(configuration: SyncUser.current!.configuration())
        
//        projects = realm.objects(Project.self).filter("owner = %@", SyncUser.current!.identity!).sorted(byKeyPath: "timestamp", ascending: false)
        projects = realm.objects(Project.self).sorted(byKeyPath: "timestamp", ascending: false)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        title = "My Projects"
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        activityIndicator.center = self.view.center
        activityIndicator.color = .darkGray
        activityIndicator.isHidden = false
        activityIndicator.hidesWhenStopped = true
        
        tableView.frame = self.view.frame
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addItemButtonTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logoutButtonTapped))
        
        // In a Query-based sync use case this is where we tell the server we want to subscribe to particular query
        subscription = projects.subscribe(named: "my-projects")
        
        activityIndicator.startAnimating()
        subscriptionToken = subscription.observe(\.state, options: .initial) { [weak self] state in
            print("Subscription State: \(state)")
            if state == .complete {
                self?.activityIndicator.stopAnimating()
            }
        }
        
        notificationToken = projects.observe { [weak self] changes in
            guard let tableView = self?.tableView else { return }
            print("projects observe : \(changes)")
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the UITableView
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
                                     with: .automatic)
                tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.endUpdates()
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }
        
    }
    deinit {
        subscriptionToken?.invalidate()
        notificationToken?.invalidate()
        activityIndicator.stopAnimating()
    }
    
    @objc func addItemButtonTapped() {
        let alertController = UIAlertController(title: "Add New Project", message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            let textField = alertController.textFields![0] as UITextField
            let project = Project()
            project.name = textField.text ?? ""
//            project.owner = SyncUser.current!.identity!
            try! self.realm.write {
                self.realm.add(project)
                
                let user = self.realm.object(ofType: PermissionUser.self, forPrimaryKey: SyncUser.current!.identity!)!
                let permission = project.permissions.findOrCreate(forRole: user.role!)
                permission.canRead = true
                permission.canUpdate = true
                permission.canDelete = true
            }
            // do something with textField
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addTextField(configurationHandler: {(textField : UITextField!) -> Void in
            textField.placeholder = "New Item Text"
        })
        self.present(alertController, animated: true, completion: nil)
    }
    @objc func logoutButtonTapped() {
        let alertController = UIAlertController(title: "Logout", message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Yes, Logout", style: .destructive, handler: { _ in
            SyncUser.current?.logOut()
            self.navigationController?.setViewControllers([WelcomeViewController()], animated: true)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    func confirmDeleteProjectAndTasks(_ project: Project) {
        
        let alertController = UIAlertController(title: "Delete \(project.name)?", message: "This will delete \(project.items.count) task(s)", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Yes, Delete \(project.name)", style: .destructive, handler: { _ in
            self.deleteProject(project)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true)
    }
    func deleteProject(_ project: Project) {
        try! realm.write {
            realm.delete(project.items)
            realm.delete(project)
        }
    }
}


extension ProjectsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")

        let project = projects[indexPath.row]
        cell.textLabel?.text = project.name
        cell.detailTextLabel?.text = (project.items.count > 0) ? "\(project.items.count) task(s)" : "No tasks"
        return cell
    }
    
}

extension ProjectsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let project = projects[indexPath.row]
        let itemsViewController = ItemsViewController()
        itemsViewController.project = project
        self.navigationController?.pushViewController(itemsViewController, animated: true)
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let project = projects[indexPath.row]
        if project.items.count > 0 {
            confirmDeleteProjectAndTasks(project)
        } else {
            deleteProject(project)
        }
    }
}
