//
//  ChatListTableManager.swift
//  Antidote
//
//  Created by Dmytro Vorobiov on 19/01/16.
//  Copyright © 2016 dvor. All rights reserved.
//

import Foundation

protocol ChatListTableManagerDelegate: class {
    func chatListTableManager(manager: ChatListTableManager, didSelectChat chat: OCTChat)
    func chatListTableManager(manager: ChatListTableManager, presentAlertController controller: UIAlertController)
    func chatListTableManagerWasUpdated(manager: ChatListTableManager)
}

class ChatListTableManager: NSObject {
    weak var delegate: ChatListTableManagerDelegate?

    let tableView: UITableView

    var isEmpty: Bool {
        get {
            return chatsController.numberOfRowsForSectionIndex(0) == 0
        }
    }

    private let theme: Theme
    private let avatarManager: AvatarManager
    private let dateFormatter: NSDateFormatter
    private let timeFormatter: NSDateFormatter

    private weak var submanagerChats: OCTSubmanagerChats!

    private let chatsController: RBQFetchedResultsController
    private let friendsController: RBQFetchedResultsController

    init(theme: Theme, tableView: UITableView, submanagerChats: OCTSubmanagerChats, submanagerObjects: OCTSubmanagerObjects) {
        self.tableView = tableView

        self.theme = theme
        self.avatarManager = AvatarManager(theme: theme)
        self.dateFormatter = NSDateFormatter(type: .RelativeDate)
        self.timeFormatter = NSDateFormatter(type: .Time)

        self.submanagerChats = submanagerChats

        let descriptors = [RLMSortDescriptor(property: "lastActivityDateInterval", ascending: false)]
        self.chatsController = submanagerObjects.fetchedResultsControllerForType(.Chat, sortDescriptors: descriptors)
        self.chatsController.performFetch()

        self.friendsController = submanagerObjects.fetchedResultsControllerForType(.Friend)
        self.friendsController.performFetch()

        super.init()

        tableView.delegate = self
        tableView.dataSource = self
        chatsController.delegate = self
        friendsController.delegate = self
    }
}

extension ChatListTableManager: UITableViewDataSource {
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let chat = chatsController.objectAtIndexPath(indexPath) as! OCTChat
        let friend = chat.friends.lastObject() as! OCTFriend

        let model = ChatListCellModel()
        if let data = friend.avatarData {
            model.avatar = UIImage(data: data)
        }
        else {
            model.avatar = avatarManager.avatarFromString(
                    friend.nickname,
                    diameter: CGFloat(ChatListCell.Constants.AvatarSize))
        }

        model.nickname = friend.nickname
        model.message = lastMessageTextFromChat(chat)
        if let date = chat.lastActivityDate() {
            model.dateText = dateTextFromDate(date)
        }

        model.status = UserStatus(connectionStatus: friend.connectionStatus, userStatus: friend.status)
        model.isUnread = chat.hasUnreadMessages()

        let cell = tableView.dequeueReusableCellWithIdentifier(ChatListCell.staticReuseIdentifier) as! ChatListCell
        cell.setupWithTheme(theme, model: model)

        return cell
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatsController.numberOfRowsForSectionIndex(section)
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let alert = UIAlertController(title: String(localized:"delete_chat_title"), message: nil, preferredStyle: .Alert)

            alert.addAction(UIAlertAction(title: String(localized: "alert_cancel"), style: .Default, handler: nil))
            alert.addAction(UIAlertAction(title: String(localized: "alert_delete"), style: .Destructive) { [unowned self] _ -> Void in
                let chat = self.chatsController.objectAtIndexPath(indexPath) as! OCTChat
                self.submanagerChats.removeChatWithAllMessages(chat)
            })

            delegate?.chatListTableManager(self, presentAlertController: alert)
        }
    }
}

extension ChatListTableManager: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        let chat = chatsController.objectAtIndexPath(indexPath) as! OCTChat
        delegate?.chatListTableManager(self, didSelectChat: chat)
    }
}

extension ChatListTableManager: RBQFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: RBQFetchedResultsController) {
        if controller === chatsController {
            tableView.beginUpdates()
        }
    }

   func controllerDidChangeContent(controller: RBQFetchedResultsController) {
        if controller === chatsController {
            ExceptionHandling.tryWithBlock({ [unowned self] in
                self.tableView.endUpdates()
            }) { [unowned self] _ in
                controller.reset()
                self.tableView.reloadData()
            }

            delegate?.chatListTableManagerWasUpdated(self)
        }
   }

    func controller(
            controller: RBQFetchedResultsController,
            didChangeObject anObject: RBQSafeRealmObject,
            atIndexPath indexPath: NSIndexPath?,
            forChangeType type: RBQFetchedResultsChangeType,
            newIndexPath: NSIndexPath?) {

        if controller === chatsController {
            switch type {
                case .Insert:
                    tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
                case .Delete:
                    tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
                case .Move:
                    tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
                    tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
                case .Update:
                    tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .None)
            }
        }
        else if controller === friendsController {
            guard type == .Update else {
                return
            }

            let friend = anObject.RLMObject() as! OCTFriend

            let pathsToUpdate = tableView.indexPathsForVisibleRows?.filter {
                let chat = chatsController.objectAtIndexPath($0) as! OCTChat

                return Int(chat.friends.indexOfObject(friend)) != NSNotFound
            }

            if let paths = pathsToUpdate {
                tableView.reloadRowsAtIndexPaths(paths, withRowAnimation: .None)
            }
        }
    }
}

private extension ChatListTableManager {
    func lastMessageTextFromChat(chat: OCTChat) -> String {
        guard let message = chat.lastMessage else {
            return ""
        }

        if let text = message.messageText {
            return text.text ?? ""
        }
        else if let file = message.messageFile {
            let fileName = file.fileName ?? ""
            return String(localized: message.isOutgoing() ? "chat_outgoing_file" : "chat_incoming_file") + " \(fileName)"
        }
        else if let call = message.messageCall {
            switch call.callEvent {
                case .Answered:
                    let timeString = String(timeInterval: call.callDuration)
                    return String(localized: "chat_call_finished") + " - \(timeString)"
                case .Unanswered:
                    return message.isOutgoing() ?  String(localized: "chat_unanwered_call") : String(localized: "chat_missed_call_message")
            }
        }

        return ""
    }

    func dateTextFromDate(date: NSDate) -> String {
        let isToday = NSCalendar.currentCalendar().compareDate(NSDate(), toDate: date, toUnitGranularity: .Day) == .OrderedSame

        return isToday ? timeFormatter.stringFromDate(date) : dateFormatter.stringFromDate(date)
    }
}
