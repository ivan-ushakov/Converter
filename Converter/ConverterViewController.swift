//
//  ConverterViewController.swift
//  Converter
//
//  Created by  Ivan Ushakov on 30/07/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import UIKit

import RxSwift

class CurrencyCellModel {

    let input = Variable<String?>(nil)

    let output = Variable<String?>(nil)

    let code: String

    let name: String

    let rate: Double

    private let formatter = NumberFormatter()

    private let disposeBag = DisposeBag()

    init(code: String, rate: Double, shared: Variable<Double>) {
        self.code = code
        self.name = Locale.current.localizedString(forCurrencyCode: code) ?? NSLocalizedString("Unknown", comment: "")
        self.rate = rate

        self.input.asObservable().subscribe(onNext: { string in
            if let numberString = string, let number = Double(numberString) {
                shared.value = number / self.rate
            } else {
                self.update(shared.value)
            }
        }).disposed(by: self.disposeBag)

        shared.asObservable().subscribe(onNext: { value in
            self.update(value)
        }).disposed(by: self.disposeBag)

        self.formatter.numberStyle = .decimal
    }

    private func update(_ value: Double) {
        self.output.value = formatter.string(from: NSNumber(value: value * self.rate))
    }
}

class ConverterViewModel {

    let cells = Variable<[CurrencyCellModel]>([])

    private let router: RouterType

    private let timerService: TimerServiceType

    private let webService: WebServiceType

    private let shared = Variable<Double>(100.0)

    private let disposeBag = DisposeBag()

    init(router: RouterType, timerService: TimerServiceType, webService: WebServiceType) {
        self.router = router
        self.timerService = timerService
        self.webService = webService
    }

    func fetch() {
        self.webService.fetchRates().subscribe(onNext: { response in
            var array = response.rates.map { self.transform($0) }.sorted(by: { $0.code < $1.code })

            array.insert(CurrencyCellModel(code: response.base.rawValue, rate: 1, shared: self.shared), at: 0)

            self.cells.value = array
        }, onError: { error in
            self.showError(NSLocalizedString("Fail to load data", comment: ""))
        }).disposed(by: self.disposeBag)
    }

    private func showError(_ message: String) {
        let viewModel = ErrorViewModel(message: message)
        self.router.present(viewModel)
    }

    private func transform(_ rate: Rate) -> CurrencyCellModel {
        return CurrencyCellModel(code: rate.currency.rawValue, rate: rate.value, shared: self.shared)
    }
}

class ConverterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()

    private let disposeBag = DisposeBag()

    private let viewModel: ConverterViewModel

    init(viewModel: ConverterViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white

        self.tableView.register(CurrencyCell.self, forCellReuseIdentifier: CurrencyCell.reuseIdentifier)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.separatorStyle = .none
        self.view.addSubview(self.tableView)
        
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.viewModel.fetch()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.tableView.frame = self.view.bounds
    }
    
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.cells.value.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CurrencyCell.reuseIdentifier) as? CurrencyCell else {
            fatalError()
        }

        cell.bindViewModel(self.viewModel.cells.value[indexPath.row])

        return cell
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    // MARK: Private
    private func bindViewModel() {
        self.viewModel.cells.asObservable().subscribe(onNext: { _ in
            self.tableView.reloadData()
        }).disposed(by: self.disposeBag)
    }
}

private class CurrencyCell: UITableViewCell {

    static let reuseIdentifier = "CurrencyCell"

    private let codeLabel = UILabel()

    private let nameLabel = UILabel()

    private let textField = UITextField()

    private var disposeBag = DisposeBag()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: CurrencyCell.reuseIdentifier)
        
        self.backgroundColor = UIColor.clear
        self.selectionStyle = .none

        self.codeLabel.backgroundColor = UIColor.clear
        self.codeLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        self.codeLabel.textColor = UIColor.black
        self.codeLabel.textAlignment = .left
        self.contentView.addSubview(self.codeLabel)
        
        self.nameLabel.backgroundColor = UIColor.clear
        self.nameLabel.font = UIFont.systemFont(ofSize: 12)
        self.nameLabel.textColor = UIColor.lightGray
        self.nameLabel.textAlignment = .left
        self.contentView.addSubview(self.nameLabel)

        self.textField.backgroundColor = UIColor.clear
        self.textField.font = UIFont.systemFont(ofSize: 18)
        self.textField.textAlignment = .right
        self.textField.keyboardType = .numberPad
        self.contentView.addSubview(self.textField)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func bindViewModel(_ model: CurrencyCellModel) {
        self.codeLabel.text = model.code
        self.nameLabel.text = model.name

        (self.textField.rx.text <-> model.input).disposed(by: self.disposeBag)

        model.output.asObservable().subscribe(onNext: { output in
            self.textField.text = output
        }).disposed(by: self.disposeBag)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        self.disposeBag = DisposeBag()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        let x = self.layoutMargins.left;

        self.codeLabel.sizeToFit()
        self.codeLabel.frame = CGRect(x: x, y: 0, width: self.codeLabel.frame.width, height: self.codeLabel.frame.height)

        self.nameLabel.sizeToFit()
        self.nameLabel.frame = CGRect(x: x, y: self.codeLabel.frame.maxY + 5, width: self.nameLabel.frame.width, height: self.nameLabel.frame.height)

        self.textField.sizeToFit()
        let width = self.contentView.frame.width - self.layoutMargins.left - self.layoutMargins.right
        let textFieldX = floor(width / 2)
        let textFieldY = floor((self.contentView.frame.height - self.textField.frame.height) / 2)
        self.textField.frame = CGRect(x: textFieldX, y: textFieldY, width: textFieldX, height: self.textField.frame.height)
    }
}

