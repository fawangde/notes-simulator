import UIKit

final class ZGBoomEditViewController: UIViewController {
    private let textView = UITextView()
    private let btnSave = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "雷号管理"
        view.backgroundColor = UIColor(patternImage: UIImage(named: "bg_op") ?? UIImage())

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(goBack)
        )

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideKeyboard)))

        textView.frame = CGRect(x: 20, y: 100, width: view.bounds.width - 40, height: 300)
        textView.autoresizingMask = [.flexibleWidth]
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.cornerRadius = 8
        textView.text = ZGDataManager.shared.getBoomNums().joined(separator: "\n")
        textView.textColor = .white
        textView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.addSubview(textView)

        btnSave.setTitle("保存", for: .normal)
        btnSave.frame = CGRect(x: 20, y: 420, width: view.bounds.width - 40, height: 50)
        btnSave.autoresizingMask = [.flexibleWidth]
        btnSave.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        btnSave.setTitleColor(.white, for: .normal)
        btnSave.layer.cornerRadius = 10
        btnSave.addTarget(self, action: #selector(saveBoom), for: .touchUpInside)
        view.addSubview(btnSave)
    }

    @objc private func hideKeyboard() {
        view.endEditing(true)
    }

    @objc private func goBack() {
        dismiss(animated: true)
    }

    @objc private func saveBoom() {
        view.endEditing(true)
        let list = textView.text
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        ZGDataManager.shared.saveBoomNums(list)
        showAlert(title: "成功", msg: "保存完成")
    }

    private func showAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
