//
//  SettingsTabCoordinator.swift
//  Antidote
//
//  Created by Dmytro Vorobiov on 07/10/15.
//  Copyright © 2015 dvor. All rights reserved.
//

import UIKit

private struct Options {
    static let ToShowKey = "ToShowKey"

    enum Controller {
        case AdvancedSettings
    }
}

protocol SettingsTabCoordinatorDelegate: class {
    func settingsTabCoordinatorRecreateCoordinatorsStack(coordinator: SettingsTabCoordinator, options: CoordinatorOptions)
}

class SettingsTabCoordinator: RunningNavigationCoordinator {
    weak var delegate: SettingsTabCoordinatorDelegate?

    override func startWithOptions(options: CoordinatorOptions?) {
        let controller = SettingsMainController(theme: theme)
        controller.delegate = self

        navigationController.pushViewController(controller, animated: false)

        if let toShow = options?[Options.ToShowKey] as? Options.Controller {
            switch toShow {
                case .AdvancedSettings:
                    let advanced = SettingsAdvancedController(theme: theme)
                    advanced.delegate = self

                    navigationController.pushViewController(advanced, animated: false)
            }
        }
    }
}

extension SettingsTabCoordinator: SettingsMainControllerDelegate {
    func settingsMainControllerShowAboutScreen(controller: SettingsMainController) {
        let controller = SettingsAboutController(theme: theme)

        navigationController.pushViewController(controller, animated: true)
    }

    func settingsMainControllerChangeAutodownloadImages(controller: SettingsMainController) {
        let controller = ChangeAutodownloadImagesController(theme: theme)
        controller.delegate = self

        navigationController.pushViewController(controller, animated: true)
    }

    func settingsMainControllerShowAdvancedSettings(controller: SettingsMainController) {
        let controller = SettingsAdvancedController(theme: theme)
        controller.delegate = self

        navigationController.pushViewController(controller, animated: true)
    }
}

extension SettingsTabCoordinator: ChangeAutodownloadImagesControllerDelegate {
    func changeAutodownloadImagesControllerDidChange(controller: ChangeAutodownloadImagesController) {
        navigationController.popViewControllerAnimated(true)
    }
}

extension SettingsTabCoordinator: SettingsAdvancedControllerDelegate {
    func settingsAdvancedControllerToxOptionsChanged(controller: SettingsAdvancedController) {
        delegate?.settingsTabCoordinatorRecreateCoordinatorsStack(self, options: [
            Options.ToShowKey: Options.Controller.AdvancedSettings
        ])
    }
}
