//
//  TaskListViewController.swift
//  TaskListApp2
//
//  Created by Liaisan on 2/13/24.
//

import UIKit

final class TaskListViewController: UITableViewController {
    
    private let cellID = "cell"
    private var tasks: [Task] = []
    private let storageManager = StorageManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        fetchData()
    }

    private func setupView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        view.backgroundColor = .white
        setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        title = "Task List"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.backgroundColor = UIColor(
            displayP3Red: 21/255,
            green: 101/255,
            blue: 192/255,
            alpha: 194/255
        )
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        // Add button to navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewTask)
        )
        
        navigationController?.navigationBar.tintColor = .white
    }
    
    @objc private func addNewTask() {
        showAlert()
    }
    
    private func save(taskName: String) {
        storageManager.create(taskName) { [unowned self] task in
            tasks.append(task)
            tableView.insertRows(
                at: [IndexPath(row: self.tasks.count - 1, section: 0)],
                with: .automatic
            )
        }
    }

    private func fetchData() {
        storageManager.fetchData { [unowned self] result in
            switch result {
            case .success(let tasks):
                self.tasks = tasks
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension TaskListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tasks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let task = tasks[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = task.title
        cell.contentConfiguration = content
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TaskListViewController {
    // Edit task
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let task = tasks[indexPath.row]
        showAlert(task: task) {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    // Delete task
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let task = tasks.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            storageManager.delete(task)
        }
    }
}

// MARK: - Alert Controller
extension TaskListViewController {
    
    private func showAlert(task: Task? = nil, completion: (() -> Void)? = nil) {
        let alertFactory = AlertControllerFactory(
            userAction: task != nil ? .editTask : .newTask,
            taskTitle: task?.title
        )
        let alert = alertFactory.createAlert { [weak self] taskName in
            if let task, let completion {
                self?.storageManager.update(task, newName: taskName)
                completion()
                return
            }
            
            self?.save(taskName: taskName)
        }
        
        present(alert, animated: true)
    }
}
