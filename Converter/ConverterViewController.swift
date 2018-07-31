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

    let color: Color

    let code: String

    let name: String

    var editable = false

    private var rate: Double

    private let shared: Variable<Double>

    private let formatter = NumberFormatter()

    private let disposeBag = DisposeBag()

    init(code: String, rate: Double, shared: Variable<Double>) {
        self.color = Color.from(code: code)
        self.code = code
        self.name = Locale.current.localizedString(forCurrencyCode: code) ?? NSLocalizedString("Unknown", comment: "")
        self.rate = rate
        self.shared = shared

        self.formatter.numberStyle = .decimal
        self.formatter.usesGroupingSeparator = false
        self.formatter.maximumFractionDigits = 2
        self.formatter.minimumFractionDigits = 2

        self.input.asObservable().subscribe(onNext: { [weak self] value in
            self?.handleInput(value)
        }).disposed(by: self.disposeBag)

        shared.asObservable().subscribe(onNext: { [weak self] value in
            self?.update(value)
        }).disposed(by: self.disposeBag)
    }

    func updateRate(_ value: Double) {
        self.rate = value
        if (!self.editable) {
            update(self.shared.value)
        }
    }

    private func handleInput(_ value: String?) {
        if let numberString = value, let number = Double(numberString) {
            self.shared.value = number / self.rate
        } else {
            update(self.shared.value)
        }
    }

    private func update(_ value: Double) {
        self.output.value = formatter.string(from: NSNumber(value: Double(value * self.rate)))
    }
}

class ConverterViewModel {

    let cells = Variable<[CurrencyCellModel]>([])

    let editable = Variable<Int?>(nil)

    private let timerService: TimerServiceType

    private let webService: WebServiceType

    private let shared = Variable<Double>(100.0)

    private let disposeBag = DisposeBag()

    init(timerService: TimerServiceType, webService: WebServiceType) {
        self.timerService = timerService
        self.webService = webService
    }

    func startTimer() {
        self.timerService.scheduledTimer(withTimeInterval: 1.0) {
            self.fetch()
        }
    }

    func select(_ index: Int) {
        self.editable.value = index
    }

    // MARK: Private

    private func fetch() {
        self.webService.fetchRates().subscribe(onNext: { response in
            self.update(response)
        }, onError: { error in
            print("Fail to load data: \(error)")
        }).disposed(by: self.disposeBag)
    }

    private func update(_ response: RateResponse) {
        if (self.cells.value.count == 0) {
            var array = response.rates.map { self.transform($0) }.sorted(by: { $0.code < $1.code })
            array.insert(CurrencyCellModel(code: response.base.rawValue, rate: 1, shared: self.shared), at: 0)
            self.cells.value = array
        } else {
            var map = Dictionary<String, Double>()
            response.rates.forEach { map[$0.currency.rawValue] = $0.value }

            self.cells.value.forEach { cell in
                if let value = map[cell.code] {
                    cell.updateRate(value)
                }
            }
        }
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

        self.tableView.keyboardDismissMode = .onDrag

        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.viewModel.startTimer()
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.viewModel.select(indexPath.row)
    }

    // MARK: Private

    private func bindViewModel() {
        self.viewModel.cells.asObservable().subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: self.disposeBag)

        self.viewModel.editable.asObservable().subscribe(onNext: { [weak self] editable in
            guard let index = editable else { return }
            self?.makeEditable(index)
        }).disposed(by: self.disposeBag)
    }

    private func makeEditable(_ index: Int) {
        let block: () -> (Void) = {
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? CurrencyCell {
                cell.makeFirstResponder()
            }
        }

        if (index != 0) {
            self.tableView.performBatchUpdates({
                let from = IndexPath(row: index, section: 0)
                let to = IndexPath(row: 0, section: 0)
                self.tableView.moveRow(at: from, to: to)
            }, completion: { _ in
                block()
            })
        } else {
            block()
        }
    }
}

private class CurrencyCell: UITableViewCell, UITextFieldDelegate {

    static let reuseIdentifier = "CurrencyCell"

    private let iconView = UIView()

    private let codeLabel = UILabel()

    private let nameLabel = UILabel()

    private let textField = UITextField()

    private let lineView = UIView()

    private var disposeBag = DisposeBag()

    private var editableBlock: ((Bool) -> Void)?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: CurrencyCell.reuseIdentifier)

        self.backgroundColor = UIColor.clear
        self.selectionStyle = .none

        self.contentView.addSubview(self.iconView)

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
        self.textField.delegate = self
        self.contentView.addSubview(self.textField)

        self.lineView.backgroundColor = UIColor.lightGray
        self.contentView.addSubview(self.lineView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    func bindViewModel(_ model: CurrencyCellModel) {
        self.iconView.backgroundColor = UIColor(color: model.color)
        self.codeLabel.text = model.code
        self.nameLabel.text = model.name

        (self.textField.rx.text <-> model.input).disposed(by: self.disposeBag)

        model.output.asObservable().subscribe(onNext: { [weak self] output in
            self?.textField.text = output
        }).disposed(by: self.disposeBag)

        self.editableBlock = { value in
            model.editable = value
        }
    }

    func makeFirstResponder() {
        self.textField.becomeFirstResponder()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.disposeBag = DisposeBag()
        self.editableBlock = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let border = CGFloat(4)

        let iconViewX = self.layoutMargins.left + border;
        let iconSize = self.contentView.frame.height - 4 * border
        self.iconView.frame = CGRect(x: iconViewX, y: border, width: iconSize, height: iconSize)
        self.iconView.layer.cornerRadius = floor(iconSize / 2)

        let labelX = self.iconView.frame.maxX + border

        self.codeLabel.sizeToFit()
        self.codeLabel.frame = CGRect(x: labelX, y: border, width: self.codeLabel.frame.width, height: self.codeLabel.frame.height)

        self.nameLabel.sizeToFit()
        self.nameLabel.frame = CGRect(x: labelX, y: self.codeLabel.frame.maxY + border, width: self.nameLabel.frame.width, height: self.nameLabel.frame.height)

        self.textField.sizeToFit()
        let textFieldWidth = self.textField.frame.width + 4
        let textFieldX = self.contentView.frame.width - self.layoutMargins.right - textFieldWidth
        let textFieldY = floor((self.contentView.frame.height - self.textField.frame.height) / 2)
        self.textField.frame = CGRect(x: textFieldX, y: textFieldY, width: textFieldWidth, height: self.textField.frame.height)

        self.lineView.frame = CGRect(x: textFieldX, y: self.textField.frame.maxY + 1, width: textFieldWidth, height: 1)
    }

    // MARK: UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.editableBlock?(true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.editableBlock?(false)
    }
}

