//
//  WelcomeViewController.swift
//  iOSToDoApp
//
//  Created by CMR on 20/09/2018.
//

import UIKit
import RealmSwift
func initializeRealmPermissions(_ realm: Realm) {
    // Ensure that class-level permissions cannot be modified by anyone but admin users.
    // The Project type can be queried, while Item cannot. This means that the only Item
    // objects that will be synchronized are those associated with our Projects.
    // Additionally, we prevent roles from being modified to avoid malicious users
    // from gaining access to other user's projects by adding themselves as members
    // of that user's private role.
    let queryable = [Project.className(): true, Item.className(): false, PermissionRole.className(): true]
    let updateable = [Project.className(): true, Item.className(): true, PermissionRole.className(): false]
    
    for cls in [Project.self, Item.self, PermissionRole.self] {
        let everyonePermission = realm.permissions(forType: cls).findOrCreate(forRoleNamed: "everyone")
        everyonePermission.canQuery = queryable[cls.className()]!
        everyonePermission.canUpdate = updateable[cls.className()]!
        everyonePermission.canSetPermissions = false
    }
    
    // Ensure that the schema and Realm-level permissions cannot be modified by anyone but admin users.
    let everyonePermission = realm.permissions.findOrCreate(forRoleNamed: "everyone")
    everyonePermission.canModifySchema = false
    // `canSetPermissions` must be disabled last, as it would otherwise prevent other permission changes
    // from taking effect.
    everyonePermission.canSetPermissions = false
}
// Initialize the default permissions of the Realm.
// This is done asynchronously, as we must first wait for the Realm to download from the server
// to ensure that we don't end up with the same user being added to a role multiple times.
func initializePermissions(_ user: SyncUser, completion: @escaping (Error?) -> Void) {
    Realm.asyncOpen(configuration: user.configuration()) { (realm, error) in
        guard let realm = realm else {
            completion(error)
            return
        }
        
        try! realm.write {
            initializeRealmPermissions(realm)
        }
        
        completion(nil)
    }
}

class WelcomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Welcome"
        view.backgroundColor = .white
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let _ = SyncUser.current {
            // We Have already logged in here
            self.navigationController?.pushViewController(ProjectsViewController(), animated: true)
        } else {
            let alertController = UIAlertController(title: "Login to Realm Cloud", message: "Supply a nice nickname!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Login", style: .default, handler: { [unowned self] alert -> Void in
                let textField = alertController.textFields![0] as UITextField
                let creds = SyncCredentials.nickname(textField.text!, isAdmin: false)
                
                SyncUser.logIn(with: creds, server: Constants.AUTH_URL) { [weak self] (user,error) in
                    guard let user = user else { fatalError(error!.localizedDescription) }
                    
                    initializePermissions(user) { error in
                        if let error = error {
                            fatalError(error.localizedDescription)
                        }
                        
                        self?.navigationController?.pushViewController(ProjectsViewController(), animated: true)
                    }
                }
            }))
            alertController.addTextField(configurationHandler: { (textField: UITextField) in
                textField.placeholder = "A Name for your user"
            })
            self.present(alertController, animated: true)
        }
    }

}
