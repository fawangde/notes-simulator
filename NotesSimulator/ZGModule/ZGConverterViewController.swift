import UIKit

final class ZGConverterViewController: UIViewController {
    private let btnConvert = UIButton(type: .system)
    private let btnClearTXT = UIButton(type: .system)
    private let btnClearVCF = UIButton(type: .system)
    private let btnTxtManage = UIButton(type: .system)
    private let btnVcfManage = UIButton(type: .system)
    private let btnEmailManage = UIButton(type: .system)
    private let btnBoomManage = UIButton(type: .system)

    private let lblResult = UILabel()
    private let lblDetail = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        let bgView = UIImageView(image: UIImage(named: "bg_op"))
        bgView.frame = view.bounds
        bgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bgView.contentMode = .scaleAspectFill
        bgView.clipsToBounds = true
        view.addSubview(bgView)
        view.sendSubviewToBack(bgView)

        view.backgroundColor = .clear
        setupButtons()
        setupLabels()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutButtons()
        layoutLabels()
    }

    private func setupButtons() {
        let list: [(UIButton, String, Selector)] = [
            (btnConvert, "开始转换", #selector(startConvert)),
            (btnClearTXT, "一键清空TXT", #selector(clearAllTXT)),
            (btnClearVCF, "一键清空VCF", #selector(clearAllVCF)),
            (btnTxtManage, "TXT文件管理", #selector(openTXTManager)),
            (btnVcfManage, "VCF文件管理", #selector(openVCFManager)),
            (btnEmailManage, "邮箱管理", #selector(openEmailManager)),
            (btnBoomManage, "雷号管理", #selector(openBoomManager)),
        ]

        for (btn, title, sel) in list {
            btn.setTitle(title, for: .normal)
            btn.backgroundColor = UIColor.black.withAlphaComponent(0.65)
            btn.setTitleColor(.white, for: .normal)
            btn.layer.cornerRadius = 10
            btn.addTarget(self, action: sel, for: .touchUpInside)
            view.addSubview(btn)
        }
    }

    private func layoutButtons() {
        let btnW: CGFloat = min(260, view.bounds.width - 40)
        let btnH: CGFloat = 50
        var y: CGFloat = 120
        let buttons = [btnConvert, btnClearTXT, btnClearVCF, btnTxtManage, btnVcfManage, btnEmailManage, btnBoomManage]
        for btn in buttons {
            btn.frame = CGRect(x: (view.bounds.width - btnW) / 2, y: y, width: btnW, height: btnH)
            y += btnH + 15
        }
    }

    private func setupLabels() {
        lblResult.textColor = .white
        lblResult.textAlignment = .center
        view.addSubview(lblResult)

        lblDetail.textColor = .white
        lblDetail.numberOfLines = 0
        lblDetail.font = UIFont.systemFont(ofSize: 13)
        lblDetail.isUserInteractionEnabled = true
        view.addSubview(lblDetail)

        lblDetail.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(copyLogText))
        )
        view.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        )
    }

    private func layoutLabels() {
        let resultHeight: CGFloat = 30
        lblResult.frame = CGRect(
            x: 20,
            y: btnConvert.frame.minY - 10 - resultHeight,
            width: view.bounds.width - 40,
            height: resultHeight
        )

        let logTop = btnBoomManage.frame.maxY + 15
        let logBottomInset = max(view.safeAreaInsets.bottom, 12)
        lblDetail.frame = CGRect(
            x: 20,
            y: logTop,
            width: view.bounds.width - 40,
            height: max(0, view.bounds.height - logTop - logBottomInset)
        )
    }

    private func showPasswordVerifyAlert(completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "请输入管理密码", message: "", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "6位数字密码"
            tf.isSecureTextEntry = true
            tf.keyboardType = .numberPad
            tf.addTarget(self, action: #selector(self.limitPwdLength(_:)), for: .editingChanged)
        }
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            let pwd = alert.textFields?.first?.text ?? ""
            completion(pwd == "258258")
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
            completion(false)
        })
        present(alert, animated: true)
    }

    @objc private func limitPwdLength(_ tf: UITextField) {
        if tf.text?.count ?? 0 > 6 {
            tf.text = String(tf.text!.prefix(6))
        }
    }

    @objc private func copyLogText() {
        guard let text = lblDetail.text, !text.isEmpty else {
            showAlert(title: "提示", msg: "暂无日志可复制")
            return
        }
        UIPasteboard.general.string = text
        showAlert(title: "复制成功", msg: "日志已复制到剪贴板")
    }

    private func checkCanUse(_ completion: @escaping (Bool) -> Void) {
        completion(ZGConverterAccessBridge.canUse())
    }

    @objc private func hideKeyboard() {
        view.endEditing(true)
    }

    @objc private func startConvert() {
        checkCanUse { [weak self] ok in
            guard let self else { return }
            guard ok else {
                self.showAlert(title: "不可用", msg: ZGConverterAccessBridge.deniedMessage)
                return
            }

            let helper = ZGFileHelper.shared
            let dataMgr = ZGDataManager.shared
            let txtList = helper.allTXTFiles()
            let emails = dataMgr.getEmails()
            let boomList = dataMgr.getBoomNums()

            if txtList.isEmpty {
                self.showAlert(title: "提示", msg: "没有TXT文件")
                return
            }
            if emails.isEmpty {
                self.showAlert(title: "提示", msg: "请先添加邮箱")
                return
            }

            var totalAll = 0
            var logStr = ""

            for path in txtList {
                let url = URL(fileURLWithPath: path)
                let fileName = url.deletingPathExtension().lastPathComponent

                guard let content = try? String(contentsOf: url, encoding: .utf8) else {
                    logStr += "【\(fileName)】读取失败\n"
                    continue
                }

                let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
                var vcfContent = ""
                var fileCount = 0
                var fileBoomArr = [String]()

                for (idx, line) in lines.enumerated() {
                    if idx >= emails.count { break }

                    let pureNum = line.filter(\.isNumber)
                    guard pureNum.count == 11 else { continue }

                    let fmtPhone = helper.formatPhone(pureNum)
                    let email = emails[idx]
                    let isBoom = boomList.contains(pureNum)

                    if isBoom {
                        let nameStr = fmtPhone + "boom"
                        vcfContent += "BEGIN:VCARD\nVERSION:3.0\nN:\(nameStr)\nTEL:\(fmtPhone)\nEND:VCARD\n\n"
                        fileBoomArr.append(pureNum)
                    } else {
                        let nameStr = fmtPhone
                        vcfContent += "BEGIN:VCARD\nVERSION:3.0\nN:\(nameStr)\nTEL:\(email)\nEND:VCARD\n\n"
                    }

                    fileCount += 1
                    totalAll += 1
                }

                let savePath = helper.vcfFolder + "/\(fileName).vcf"
                try? vcfContent.write(toFile: savePath, atomically: true, encoding: .utf8)

                logStr += "文件：\(fileName)  共转换：\(fileCount) 个\n"
                if !fileBoomArr.isEmpty {
                    logStr += "   包含雷号：\(fileBoomArr.joined(separator: "、"))\n"
                }
                logStr += "---------------------------------\n"
            }

            self.lblResult.text = "✅ 全部转换完成，总计：\(totalAll) 个"
            self.lblDetail.text = logStr
        }
    }

    @objc private func clearAllTXT() {
        checkCanUse { [weak self] ok in
            guard let self else { return }
            guard ok else {
                self.showAlert(title: "不可用", msg: ZGConverterAccessBridge.deniedMessage)
                return
            }
            ZGFileHelper.shared.clearAllTXT()
            self.showAlert(title: "完成", msg: "已清空所有TXT")
        }
    }

    @objc private func clearAllVCF() {
        checkCanUse { [weak self] ok in
            guard let self else { return }
            guard ok else {
                self.showAlert(title: "不可用", msg: ZGConverterAccessBridge.deniedMessage)
                return
            }
            ZGFileHelper.shared.clearAllVCF()
            self.showAlert(title: "完成", msg: "已清空所有VCF")
        }
    }

    @objc private func openTXTManager() {
        checkCanUse { [weak self] ok in
            guard let self else { return }
            guard ok else {
                self.showAlert(title: "不可用", msg: ZGConverterAccessBridge.deniedMessage)
                return
            }
            let vc = ZGTXTFileManagerViewController()
            self.present(UINavigationController(rootViewController: vc), animated: true)
        }
    }

    @objc private func openVCFManager() {
        checkCanUse { [weak self] ok in
            guard let self else { return }
            guard ok else {
                self.showAlert(title: "不可用", msg: ZGConverterAccessBridge.deniedMessage)
                return
            }
            self.showPasswordVerifyAlert { success in
                guard success else {
                    self.showAlert(title: "密码错误", msg: "请输入正确密码")
                    return
                }
                let vc = ZGVCFFileManagerViewController()
                self.present(UINavigationController(rootViewController: vc), animated: true)
            }
        }
    }

    @objc private func openEmailManager() {
        checkCanUse { [weak self] ok in
            guard let self else { return }
            guard ok else {
                self.showAlert(title: "不可用", msg: ZGConverterAccessBridge.deniedMessage)
                return
            }
            self.showPasswordVerifyAlert { success in
                guard success else {
                    self.showAlert(title: "密码错误", msg: "请输入正确密码")
                    return
                }
                let vc = ZGEmailEditViewController()
                self.present(UINavigationController(rootViewController: vc), animated: true)
            }
        }
    }

    @objc private func openBoomManager() {
        checkCanUse { [weak self] ok in
            guard let self else { return }
            guard ok else {
                self.showAlert(title: "不可用", msg: ZGConverterAccessBridge.deniedMessage)
                return
            }
            self.showPasswordVerifyAlert { success in
                guard success else {
                    self.showAlert(title: "密码错误", msg: "请输入正确密码")
                    return
                }
                let vc = ZGBoomEditViewController()
                self.present(UINavigationController(rootViewController: vc), animated: true)
            }
        }
    }

    private func showAlert(title: String, msg: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            self.present(alert, animated: true)
        }
    }

    func showImportNotice(fileName: String) {
        DispatchQueue.main.async {
            self.lblResult.text = "✅ 已导入 \(fileName)"
        }
    }
}
