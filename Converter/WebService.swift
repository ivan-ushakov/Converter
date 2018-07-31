//
//  WebService.swift
//  Converter
//
//  Created by  Ivan Ushakov on 30/07/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

protocol WebServiceType {
    func fetchRates() -> Observable<RateResponse>
}

class WebService: WebServiceType {

    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: configuration)
    }

    func fetchRates() -> Observable<RateResponse> {
        guard let url = URL(string: "https://revolut.duckdns.org/latest?base=EUR") else { fatalError() }
        return self.session.rx.json(request: URLRequest(url: url)).map { try RateResponse.transform($0) }.observeOn(MainScheduler.instance)
    }
}

struct WebServiceError: Error {
    
}

extension Rate {
    static func transform(_ object: Dictionary<String, Double>) throws -> [Rate] {
        return try object.map { key, value -> Rate in
            guard let currency = Currency(rawValue: key) else {
                throw WebServiceError()
            }
            return Rate(currency: currency, value: value)
        }
    }
}

extension RateResponse {
    static func transform(_ response: Any) throws -> RateResponse {
        guard let object = response as? Dictionary<String, Any> else {
            throw WebServiceError()
        }

        guard let baseString = object["base"] as? String, let base = Currency(rawValue: baseString) else {
            throw WebServiceError()
        }

        guard let dateString = object["date"] as? String, let date = Formatter.shared.date(from: dateString) else {
            throw WebServiceError()
        }

        guard let rateObject = object["rates"] as? Dictionary<String, Double> else {
            throw WebServiceError()
        }

        return RateResponse(base: base, date: date, rates: try Rate.transform(rateObject))
    }
}

private class Formatter {

    static let shared = Formatter()

    private let formatter = DateFormatter()

    init() {
        self.formatter.dateFormat = "yyyy-MM-dd"
    }

    func date(from: String) -> Date? {
        return self.formatter.date(from: from)
    }
}

