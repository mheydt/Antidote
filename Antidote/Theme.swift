//
//  Theme.swift
//  Antidote
//
//  Created by Dmytro Vorobiov on 08/10/15.
//  Copyright © 2015 dvor. All rights reserved.
//

import UIKit
import Yaml

enum ErrorTheme: ErrorType {
    case CannotParseFile(String)
    case WrongVersion(String)

    func debugDescription() -> String {
        switch self {
            case .CannotParseFile(let string):
                return "Parse error: \(string)"
            case .WrongVersion(let string):
                return "Version error: \(string)"
        }
    }
}

class Theme {
    enum Type: String {
        case LoginBackground = "login-background"
        case LoginToxLogo = "login-tox-logo"
        case LoginButtonText = "login-button-text"
        case LoginButtonBackground = "login-button-background"
        case LoginDescriptionLabel = "login-description-label"
        case LoginFormBackground = "login-form-background"
        case LoginFormText = "login-form-text"
        case LoginLinkColor = "login-link-color"

        case TranslucentBackground = "translucent-background"

        case NormalBackground = "normal-background"
        case NormalText = "normal-text"
        case LinkText = "link-text"
        case ConnectingBackground = "connecting-background"
        case ConnectingText = "connecting-text"
        case SeparatorsAndBorders = "separators-and-borders"
        case OfflineStatus = "offline-status"
        case OnlineStatus = "online-status"
        case AwayStatus = "away-status"
        case BusyStatus = "busy-status"
        case StatusBackground = "status-background"
        case FriendCellStatus = "friend-cell-status"
        case ChatListCellMessage = "chat-list-cell-message"
        case ChatListCellUnreadBackground = "chat-list-cell-unread-background"
        case ChatInputBackground = "chat-input-background"
        case ChatIncomingBubble = "chat-incoming-bubble"
        case ChatOutgoingBubble = "chat-outgoing-bubble"
        case TabBadgeBackground = "tab-badge-background"
        case TabBadgeText = "tab-badge-text"
        case TabItemActive = "tab-item-active"
        case TabItemInactive = "tab-item-inactive"
        case NotificationBackground = "notification-background"
        case NotificationText = "notification-text"
        case SettingsBackground = "settings-background"
        case CallTextColor = "call-text-color"
        case CallDeclineButtonBackground = "call-decline-button-background"
        case CallAnswerButtonBackground = "call-answer-button-background"
        case CallControlSelectedBackground = "call-control-selected-background"
        case CallControlBackground = "call-control-background"
        case CallButtonIconColor = "call-button-icon-color"
        case CallButtonSelectedIconColor = "call-button-selected-icon-color"
        case CallVideoPreviewBackground = "call-video-preview-background"
        case RoundedButtonText = "rounded-button-text"
        case RoundedPositiveButtonBackground = "rounded-positive-button-background"
        case RoundedNegativeButtonBackground = "rounded-negative-button-background"
        case EmptyScreenPlaceholderText = "empty-screen-placeholder-text"
        case FileImageBackgroundActive = "file-image-background-active"
        case FileImageCancelledText = "file-image-cancelled-text"
        case FileImageAcceptButtonTint = "file-image-accept-button-tint"
        case FileImageCancelButtonTint = "file-image-cancel-button-tint"

        // Because enums don't support enumerations we have to do this hack. Phew.
        static let allValues = [
            LoginBackground,
            LoginToxLogo,
            LoginButtonText,
            LoginButtonBackground,
            LoginDescriptionLabel,
            LoginFormBackground,
            LoginFormText,
            LoginLinkColor,
            TranslucentBackground,
            NormalBackground,
            NormalText,
            LinkText,
            ConnectingBackground,
            ConnectingText,
            SeparatorsAndBorders,
            OfflineStatus,
            OnlineStatus,
            AwayStatus,
            BusyStatus,
            StatusBackground,
            FriendCellStatus,
            ChatListCellMessage,
            ChatListCellUnreadBackground,
            ChatInputBackground,
            ChatIncomingBubble,
            ChatOutgoingBubble,
            TabBadgeBackground,
            TabBadgeText,
            TabItemActive,
            TabItemInactive,
            NotificationBackground,
            NotificationText,
            SettingsBackground,
            CallTextColor,
            CallDeclineButtonBackground,
            CallAnswerButtonBackground,
            CallControlBackground,
            CallControlSelectedBackground,
            CallButtonIconColor,
            CallButtonSelectedIconColor,
            CallVideoPreviewBackground,
            RoundedButtonText,
            RoundedPositiveButtonBackground,
            RoundedNegativeButtonBackground,
            EmptyScreenPlaceholderText,
            FileImageBackgroundActive,
            FileImageCancelledText,
            FileImageAcceptButtonTint,
            FileImageCancelButtonTint,
        ]
    }

    init(yamlString: String) throws {
        guard let dictionary = Yaml.load(yamlString).value?.dictionary else {
            throw ErrorTheme.CannotParseFile(String(localized:"theme_error_cannot_open"))
        }

        try checkVersion(dictionary)

        mappedColors = try createMappedColors(fromDictionary: dictionary)
        try validateMappedColors(mappedColors)
    }

    func colorForType(type: Type) -> UIColor {
        return mappedColors[type.rawValue]!
    }

    var loginNavigationBarColor: UIColor {
        // https://developer.apple.com/library/ios/qa/qa1808/_index.html
        let colorDelta: CGFloat = 0.08

        var (red, green, blue, alpha) = colorForType(.LoginButtonBackground).components()

        red = max(0.0, red - colorDelta)
        green = max(0.0, green - colorDelta)
        blue = max(0.0, blue - colorDelta)

        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    private var mappedColors: [String: UIColor]!
}

private extension Theme {
    struct Constants {
        static let VersionValue = 1
        static let VersionKey = "version"
        static let ColorsKey = "colors"
        static let ValuesKey = "values"
    }

    func checkVersion(dictionary: [Yaml: Yaml]) throws {
        guard let version = dictionary[Yaml.String(Constants.VersionKey)]?.int else {
            throw ErrorTheme.CannotParseFile(String(localized:"theme_error_cannot_open"))
        }

        guard version == Constants.VersionValue else {
            throw ErrorTheme.WrongVersion(String(localized: "theme_error_cannot_open"))
        }
    }

    func createMappedColors(fromDictionary dictionary: [Yaml: Yaml]) throws -> [String: UIColor] {
        let colorsDict = try parseDictionary(dictionary, forKey: Constants.ColorsKey) { (string: String) -> UIColor? in
            return UIColor(hexString: string)
        }
        let valuesDict = try parseDictionary(dictionary, forKey: Constants.ValuesKey) { (string: String) -> String? in
            return string
        }

        var mappedColors = [String: UIColor]()

        for (key, value) in valuesDict {
            guard let color = colorsDict[value] else {
                throw ErrorTheme.CannotParseFile(String(localized: "theme_error_cannot_open", value))
            }

            mappedColors[key] = color
        }

        return mappedColors
    }

    func parseDictionary<T>(dictionary: [Yaml: Yaml], forKey key: String, modifyValue: String -> T?) throws -> [String: T] {
        guard let yamlDict = dictionary[Yaml.String(key)]?.dictionary else {
            throw ErrorTheme.CannotParseFile(String(localized: "theme_error_cannot_open", key))
        }

        var resultDict = [String: T]()

        for (keyYaml, valueYaml) in yamlDict {
            guard let key = keyYaml.string,
                  let originalValue = valueYaml.string,
                  let valueToSet = modifyValue(originalValue) else {
                throw ErrorTheme.CannotParseFile(String(localized: "theme_error_cannot_open", keyYaml.description, valueYaml.description))
            }

            resultDict[key] = valueToSet
        }

        return resultDict
    }

    func validateMappedColors(dictionary: [String: UIColor]) throws {
        for type in Type.allValues {
            guard let _ = dictionary[type.rawValue] else {
                throw ErrorTheme.CannotParseFile(String(localized: "theme_error_cannot_open", type.rawValue))
            }
        }
    }
}

