//
//  TabBarBadgeItem.swift
//  Antidote
//
//  Created by Dmytro Vorobiov on 17.01.16.
//  Copyright © 2016 dvor. All rights reserved.
//

import UIKit
import SnapKit

private struct Constants {
    static let ImageAndTextContainerYOffset = 2.0
    static let ImageAndTextOffset = 3.0

    static let BadgeTopOffset = -5.0
    static let BadgeHorizontalOffset = 5.0
    static let BadgeMinimumWidth = 22.0
    static let BadgeHeight: CGFloat = 18.0
}

class TabBarBadgeItem: TabBarAbstractItem {
    override var selected: Bool {
        didSet {
            let color = theme.colorForType(selected ? .TabItemActive : .TabItemInactive)

            textLabel.textColor = color
            imageView.tintColor = color
        }
    }

    var image: UIImage? {
        didSet {
            imageView.image = image?.imageWithRenderingMode(.AlwaysTemplate)
        }
    }
    var text: String? {
        didSet {
            textLabel.text = text
        }
    }

    var badgeText: String? {
        didSet {
            badgeTextWasUpdated()
        }
    }

    private let theme: Theme

    private var imageAndTextContainer: UIView!
    private var imageView: UIImageView!
    private var textLabel: UILabel!

    private var badgeContainer: UIView!
    private var badgeLabel: UILabel!

    private var button: UIButton!

    init(theme: Theme) {
        self.theme = theme

        super.init(frame: CGRectZero)

        backgroundColor = .clearColor()

        createViews()
        installConstraints()

        badgeTextWasUpdated()
    }

    required convenience init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Actions
extension TabBarBadgeItem {
    func buttonPressed() {
        didTapHandler?()
    }
}

private extension TabBarBadgeItem {
    func createViews() {
        imageAndTextContainer = UIView()
        imageAndTextContainer.backgroundColor = .clearColor()
        addSubview(imageAndTextContainer)

        imageView = UIImageView()
        imageView.backgroundColor = .clearColor()
        imageAndTextContainer.addSubview(imageView)

        textLabel = UILabel()
        textLabel.textColor = theme.colorForType(.NormalText)
        textLabel.textAlignment = .Center
        textLabel.backgroundColor = .clearColor()
        textLabel.font = UIFont.systemFontOfSize(10.0)
        imageAndTextContainer.addSubview(textLabel)

        badgeContainer = UIView()
        badgeContainer.backgroundColor = theme.colorForType(.TabBadgeBackground)
        badgeContainer.layer.masksToBounds = true
        badgeContainer.layer.cornerRadius = Constants.BadgeHeight / 2
        addSubview(badgeContainer)

        badgeLabel = UILabel()
        badgeLabel.textColor = theme.colorForType(.TabBadgeText)
        badgeLabel.textAlignment = .Center
        badgeLabel.backgroundColor = .clearColor()
        badgeLabel.font = UIFont.systemFontOfSize(14.0, weight: UIFontWeightLight)
        badgeContainer.addSubview(badgeLabel)

        button = UIButton()
        button.backgroundColor = .clearColor()
        button.addTarget(self, action: "buttonPressed", forControlEvents: .TouchUpInside)
        addSubview(button)
    }

    func installConstraints() {
        imageAndTextContainer.snp_makeConstraints {
            $0.centerX.equalTo(self)
            $0.centerY.equalTo(self).offset(Constants.ImageAndTextContainerYOffset)
        }

        imageView.snp_makeConstraints {
            $0.top.equalTo(imageAndTextContainer)
            $0.centerX.equalTo(imageAndTextContainer)
        }

        textLabel.snp_makeConstraints {
            $0.top.equalTo(imageView.snp_bottom).offset(Constants.ImageAndTextOffset)
            $0.centerX.equalTo(imageAndTextContainer)
            $0.bottom.equalTo(imageAndTextContainer)
        }

        badgeContainer.snp_makeConstraints {
            $0.left.equalTo(imageAndTextContainer.snp_left)
            $0.top.equalTo(imageAndTextContainer.snp_top).offset(Constants.BadgeTopOffset)
            $0.width.greaterThanOrEqualTo(Constants.BadgeMinimumWidth)
            $0.height.equalTo(Constants.BadgeHeight)
        }

        badgeLabel.snp_makeConstraints {
            $0.left.equalTo(badgeContainer).offset(Constants.BadgeHorizontalOffset)
            $0.right.equalTo(badgeContainer).offset(-Constants.BadgeHorizontalOffset)
            $0.centerY.equalTo(badgeContainer)
        }

        button.snp_makeConstraints {
            $0.edges.equalTo(self)
        }
    }

    func badgeTextWasUpdated() {
        badgeLabel.text = badgeText
        badgeContainer.hidden = (badgeText == nil) || badgeText!.isEmpty
    }
}
