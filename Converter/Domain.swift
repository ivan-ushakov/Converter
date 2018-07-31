//
//  Domain.swift
//  Converter
//
//  Created by  Ivan Ushakov on 30/07/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import Foundation

enum Currency: String {
    case AUD, BGN, BRL, CAD, CHF, CNY, CZK, DKK, EUR, GBP, HKD, HRK, HUF, IDR, ILS, INR, ISK, JPY, KRW, MXN, MYR, NOK, NZD, PHP, PLN, RON, RUB, SEK, SGD, THB, TRY, USD, ZAR
}

struct Rate {
    var currency: Currency
    var value: Double
}

struct RateResponse {
    var base: Currency
    var date: Date
    var rates: [Rate]
}

