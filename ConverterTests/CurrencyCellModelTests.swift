//
//  CurrencyCellModelTests.swift
//  ConverterTests
//
//  Created by  Ivan Ushakov on 01/08/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import XCTest
@testable import Converter

import RxSwift

class CurrencyCellModelTests: XCTestCase {

    func testInitialState() {
        let currency = Currency.EUR
        let rate = 1.0
        let shared = Variable<Double>(100.0)

        let viewModel = CurrencyCellModel(code: currency.rawValue, rate: rate, shared: shared)
        XCTAssertEqual(viewModel.code, currency.rawValue)
        XCTAssertEqual(viewModel.name, Locale.current.localizedString(forCurrencyCode: currency.rawValue))
        XCTAssertEqual(viewModel.output.value, "100.00")
    }

    func testInput() {
        let currency = Currency.CAD
        let rate = 2.0
        let shared = Variable<Double>(1.0)

        let viewModel = CurrencyCellModel(code: currency.rawValue, rate: rate, shared: shared)
        XCTAssertEqual(viewModel.output.value, "2.00")

        viewModel.input.value = "10"
        XCTAssertEqual(viewModel.output.value, "10.00")
        XCTAssertEqual(shared.value, 5.0)
    }

    func testInput_Empty() {
        let currency = Currency.CAD
        let rate = 2.0
        let shared = Variable<Double>(1.0)

        let viewModel = CurrencyCellModel(code: currency.rawValue, rate: rate, shared: shared)
        XCTAssertEqual(viewModel.output.value, "2.00")

        viewModel.input.value = nil
        XCTAssertEqual(viewModel.output.value, "2.00")
        XCTAssertEqual(shared.value, 1.0)
    }

    func testInput_Invalid() {
        let currency = Currency.RUB
        let rate = 4.0
        let shared = Variable<Double>(100.0)

        let viewModel = CurrencyCellModel(code: currency.rawValue, rate: rate, shared: shared)
        XCTAssertEqual(viewModel.output.value, "400.00")

        viewModel.input.value = "test"
        XCTAssertEqual(viewModel.output.value, "400.00")
        XCTAssertEqual(shared.value, 100.0)
    }

    func testUpdateRate_NotEditable() {
        let currency = Currency.CAD
        let rate = 1.0
        let shared = Variable<Double>(2.0)

        let viewModel = CurrencyCellModel(code: currency.rawValue, rate: rate, shared: shared)
        XCTAssertEqual(viewModel.output.value, "2.00")

        viewModel.updateRate(2.0)
        XCTAssertEqual(viewModel.output.value, "4.00")
    }

    func testUpdateRate_Editable() {
        let currency = Currency.CAD
        let rate = 1.0
        let shared = Variable<Double>(2.0)

        let viewModel = CurrencyCellModel(code: currency.rawValue, rate: rate, shared: shared)
        XCTAssertEqual(viewModel.output.value, "2.00")

        viewModel.editable = true
        viewModel.updateRate(2.0)
        XCTAssertEqual(viewModel.output.value, "2.00")
    }
}
