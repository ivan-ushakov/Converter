//
//  Router.swift
//  Converter
//
//  Created by  Ivan Ushakov on 30/07/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import UIKit

protocol RouterType {
    func present(_ viewModel: ConverterViewModel)
}

class Router: RouterType {

    private let window: UIWindow

    init() {
        self.window = UIWindow(frame: UIScreen.main.bounds)

        window.backgroundColor = UIColor.clear
    }

    func present(_ viewModel: ConverterViewModel) {
        let controller = ConverterViewController(viewModel: viewModel)

        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.isHidden = true

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}

