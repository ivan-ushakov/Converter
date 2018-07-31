//
//  RxCommon.swift
//  Converter
//
//  Created by  Ivan Ushakov on 30/07/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

infix operator <-> : DefaultPrecedence

func <-> <T>(property: ControlProperty<T>, variable: Variable<T>) -> Disposable {

    let bindToUIDisposable = variable.asObservable().bind(to: property)

    let bindToVariable = property.subscribe(onNext: { n in
        variable.value = n
    }, onCompleted:  {
        bindToUIDisposable.dispose()
    })

    return Disposables.create(bindToUIDisposable, bindToVariable)
}

