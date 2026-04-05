//
//  SettingsViewController.swift
//  Example-iOS
//
//  Created by JH on 2026/4/1.
//  Copyright © 2026 hughkli. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .systemGroupedBackground

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
        ])

        addSection(title: "Appearance", items: [
            ("Dark Mode", makeSwitchRow()),
            ("Font Size", makeSliderRow()),
        ])

        addSection(title: "Notifications", items: [
            ("Push Notifications", makeSwitchRow()),
            ("Email Notifications", makeSwitchRow()),
            ("Sound", makeSwitchRow()),
        ])

        addSection(title: "Privacy", items: [
            ("Analytics", makeSwitchRow()),
            ("Crash Reports", makeSwitchRow()),
        ])

        // Close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeScene)
        )
    }

    private func addSection(title: String, items: [(String, UIView)]) {
        let headerLabel = UILabel()
        headerLabel.text = title.uppercased()
        headerLabel.font = .preferredFont(forTextStyle: .caption1)
        headerLabel.textColor = .secondaryLabel

        let headerContainer = UIView()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(headerLabel)
        NSLayoutConstraint.activate([
            headerLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            headerLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -4),
            headerContainer.heightAnchor.constraint(equalToConstant: 40),
        ])
        stackView.addArrangedSubview(headerContainer)

        let sectionContainer = UIView()
        sectionContainer.backgroundColor = .secondarySystemGroupedBackground
        sectionContainer.layer.cornerRadius = 10
        sectionContainer.clipsToBounds = true

        let sectionStack = UIStackView()
        sectionStack.axis = .vertical
        sectionStack.spacing = 0
        sectionStack.translatesAutoresizingMaskIntoConstraints = false
        sectionContainer.addSubview(sectionStack)
        NSLayoutConstraint.activate([
            sectionStack.topAnchor.constraint(equalTo: sectionContainer.topAnchor),
            sectionStack.leadingAnchor.constraint(equalTo: sectionContainer.leadingAnchor),
            sectionStack.trailingAnchor.constraint(equalTo: sectionContainer.trailingAnchor),
            sectionStack.bottomAnchor.constraint(equalTo: sectionContainer.bottomAnchor),
        ])

        for (index, (name, control)) in items.enumerated() {
            let rowView = UIView()
            rowView.heightAnchor.constraint(equalToConstant: 44).isActive = true

            let label = UILabel()
            label.text = name
            label.translatesAutoresizingMaskIntoConstraints = false
            control.translatesAutoresizingMaskIntoConstraints = false

            rowView.addSubview(label)
            rowView.addSubview(control)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 16),
                label.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
                control.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -16),
                control.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            ])

            sectionStack.addArrangedSubview(rowView)

            if index < items.count - 1 {
                let separator = UIView()
                separator.backgroundColor = .separator
                separator.translatesAutoresizingMaskIntoConstraints = false
                rowView.addSubview(separator)
                NSLayoutConstraint.activate([
                    separator.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 16),
                    separator.trailingAnchor.constraint(equalTo: rowView.trailingAnchor),
                    separator.bottomAnchor.constraint(equalTo: rowView.bottomAnchor),
                    separator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),
                ])
            }
        }

        stackView.addArrangedSubview(sectionContainer)
    }

    @objc private func closeScene() {
        guard let scene = view.window?.windowScene else { return }
        UIApplication.shared.requestSceneSessionDestruction(scene.session, options: nil)
    }

    private func makeSwitchRow() -> UISwitch {
        let toggle = UISwitch()
        toggle.isOn = Bool.random()
        return toggle
    }

    private func makeSliderRow() -> UISlider {
        let slider = UISlider()
        slider.minimumValue = 12
        slider.maximumValue = 24
        slider.value = 16
        slider.widthAnchor.constraint(equalToConstant: 120).isActive = true
        return slider
    }
}
