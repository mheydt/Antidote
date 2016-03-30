//
//  AutomationCoordinator.swift
//  Antidote
//
//  Created by Dmytro Vorobiov on 25.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

import Foundation
import MobileCoreServices

private struct Constants {
    static let MaxFileSizeWiFi: OCTToxFileSize = 20 * 1024 * 1024
    static let MaxFileSizeWWAN: OCTToxFileSize = 5 * 1024 * 1024
}

class AutomationCoordinator: NSObject {
    private weak var submanagerFiles: OCTSubmanagerFiles!

    private let fileMessagesController: RBQFetchedResultsController
    private let userDefaults = UserDefaultsManager()
    private let reachability = Reach()

    init(submanagerObjects: OCTSubmanagerObjects, submanagerFiles: OCTSubmanagerFiles) {
        self.submanagerFiles = submanagerFiles

        let predicate = NSPredicate(format: "sender != nil AND messageFile != nil")
        self.fileMessagesController = submanagerObjects.fetchedResultsControllerForType(.MessageAbstract, predicate: predicate)

        super.init()

        fileMessagesController.delegate = self
        fileMessagesController.performFetch()
    }
}

extension AutomationCoordinator: CoordinatorProtocol {
    func startWithOptions(options: CoordinatorOptions?) {
        // nop
    }
}

extension AutomationCoordinator: RBQFetchedResultsControllerDelegate {
    func controller(
            controller: RBQFetchedResultsController,
            didChangeObject anObject: RBQSafeRealmObject,
            atIndexPath indexPath: NSIndexPath?,
            forChangeType type: RBQFetchedResultsChangeType,
            newIndexPath: NSIndexPath?) {
        switch type {
            case .Insert:
                if controller === fileMessagesController {
                    let message = anObject.RLMObject() as! OCTMessageAbstract
                    proceedNewFileMessage(message)
                }
            case .Delete:
                break
            case .Move:
                break
            case .Update:
                break
        }
    }
}

private extension AutomationCoordinator {
    func proceedNewFileMessage(message: OCTMessageAbstract) {
        let usingWiFi = self.usingWiFi()
        switch userDefaults.autodownloadImages {
            case .Never:
                return
            case .UsingWiFi:
                if !usingWiFi {
                    return
                }
            case .Always:
                break
        }

        if !UTTypeConformsTo(message.messageFile!.fileUTI ?? "", kUTTypeImage) {
            // download images only
            return
        }

        // skip too large images
        if usingWiFi {
            if message.messageFile!.fileSize > Constants.MaxFileSizeWiFi {
                return
            }
        }
        else {
            if message.messageFile!.fileSize > Constants.MaxFileSizeWWAN {
                return
            }
        }

        // workaround for deadlock in objcTox https://github.com/Antidote-for-Tox/objcTox/issues/51
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.0 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) { [weak self] in
            self?.submanagerFiles.acceptFileTransfer(message, failureBlock: nil)
        }
    }

    func usingWiFi() -> Bool
    {
        switch reachability.connectionStatus() {
            case .Offline:
                return false
            case .Unknown:
                return false
            case .Online(let type):
                switch type {
                    case .WWAN:
                        return false
                    case .WiFi:
                        return true
                }
        }
    }
}
