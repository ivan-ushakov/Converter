//
//  Router.swift
//  Converter
//
//  Created by  Ivan Ushakov on 30/07/2018.
//  Copyright © 2018  Ivan Ushakov. All rights reserved.
//

import UIKit

struct ErrorViewModel {
    var message: String
}

protocol RouterType {
    func present(_ viewModel: ConverterViewModel)
    func present(_ viewModel: ErrorViewModel)
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

    func present(_ viewModel: ErrorViewModel) {
        if let root = window.rootViewController {
            let controller = UIAlertController(title: "Error", message: viewModel.message, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            root.present(controller, animated: true, completion: nil)
        }
    }
}

