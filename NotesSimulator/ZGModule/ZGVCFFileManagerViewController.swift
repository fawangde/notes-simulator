import UIKit

final class ZGVCFFileManagerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private var files: [String] = []
    private let table = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "VCF 文件管理"
        view.backgroundColor = UIColor(patternImage: UIImage(named: "bg_op") ?? UIImage())

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(goBack)
        )

        table.frame = view.bounds
        table.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        table.backgroundColor = .clear
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(table)
    }

    @objc private func goBack() {
        dismiss(animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        files = ZGFileHelper.shared.allVCFFiles()
        table.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        files.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let path = files[indexPath.row]
        cell.textLabel?.text = URL(fileURLWithPath: path).lastPathComponent
        cell.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        cell.textLabel?.textColor = .white
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let url = URL(fileURLWithPath: files[indexPath.row])
        present(UIActivityViewController(activityItems: [url], applicationActivities: nil), animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "删除") { _, _, _ in
            let path = self.files[indexPath.row]
            try? FileManager.default.removeItem(atPath: path)
            self.files.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
