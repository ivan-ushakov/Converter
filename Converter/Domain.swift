//
//  Domain.swift
//  Converter
//
//  Created by  Ivan Ushakov on 30/07/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import UIKit

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

struct Color {
    var r: CGFloat
    var g: CGFloat
    var b: CGFloat
}

extension Color {
    static func from(code: String) -> Color {
        if (code.count != 3) {
            fatalError()
        }

        let characters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L",
                          "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
        let weight = CGFloat(26.0)

        guard let i1 = characters.index(of: String(code[code.index(code.startIndex, offsetBy: 0)])) else {
            fatalError()
        }
        let r = CGFloat(i1) / weight

        guard let i2 = characters.index(of: String(code[code.index(code.startIndex, offsetBy: 1)])) else {
            fatalError()
        }
        let g = CGFloat(i2) / weight

        guard let i3 = characters.index(of: String(code[code.index(code.startIndex, offsetBy: 2)])) else {
            fatalError()
        }
        let b = CGFloat(i3) / weight

        return Color(r: r, g: g, b: b)
    }
}

extension UIColor {
    convenience init(color: Color) {
        self.init(red: color.r, green: color.g, blue: color.b, alpha: 1)
    }
}

