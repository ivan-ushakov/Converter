//
//  ConverterViewModelTests.swift
//  ConverterTests
//
//  Created by  Ivan Ushakov on 31/07/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import XCTest
@testable import Converter

import RxSwift

class ConverterViewModelTests: XCTestCase {

    func testFetch() {
        let timerService = TimerService()
        let response = RateResponse(base: .EUR, date: Date(), rates: [Rate(currency: .AUD, value: 1.5)])

        let viewModel = ConverterViewModel(timerService: timerService, webService: WebService(response: response))

        viewModel.startTimer()
        XCTAssertEqual(viewModel.cells.value.count, 2)

        let c1 = viewModel.cells.value[0]
        XCTAssertEqual(c1.code, Currency.EUR.rawValue)

        let c2 = viewModel.cells.value[1]
        XCTAssertEqual(c2.code, Currency.AUD.rawValue)
    }

    func testSelect() {
        let timerService = TimerService()
        let response = RateResponse(base: .EUR, date: Date(), rates: [Rate(currency: .AUD, value: 1.5)])

        let viewModel = ConverterViewModel(timerService: timerService, webService: WebService(response: response))

        viewModel.startTimer()
        XCTAssertEqual(viewModel.cells.value.count, 2)

        viewModel.select(1)
        XCTAssertEqual(viewModel.editable.value, 1)
    }
}

private class TimerService: TimerServiceType {

    func scheduledTimer(withTimeInterval: TimeInterval, block: @escaping () -> Void) {
        block()
    }
}

private class WebService: WebServiceType {

    private let response: RateResponse?

    init(response: RateResponse?) {
        self.response = response
    }

    func fetchRates() -> Observable<RateResponse> {
        if let value = response {
            return Observable.just(value)
        } else {
            return Observable.error(WebServiceError())
        }
    }
}
