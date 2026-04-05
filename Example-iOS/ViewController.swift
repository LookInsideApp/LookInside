//
//  ViewController.swift
//  Example-iOS
//
//  Created by JH on 2026/3/31.
//  Copyright © 2026 hughkli. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let sceneInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UIWindowScene Example"
        view.backgroundColor = .systemBackground

        setupViews()
        updateSceneInfo()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSceneInfo()
    }

    private func setupViews() {
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

        stackView.addArrangedSubview(sceneInfoLabel)

        // Scene action buttons
        let openDetailButton = makeActionButton(
            title: "Open Detail Scene",
            systemImage: "doc.text.magnifyingglass",
            action: #selector(openDetailScene)
        )
        stackView.addArrangedSubview(openDetailButton)

        let openSettingsButton = makeActionButton(
            title: "Open Settings Scene",
            systemImage: "gearshape",
            action: #selector(openSettingsScene)
        )
        stackView.addArrangedSubview(openSettingsButton)

        // Separator
        let separatorLabel = UILabel()
        separatorLabel.text = "Sample Controls"
        separatorLabel.font = .preferredFont(forTextStyle: .subheadline)
        separatorLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(separatorLabel)

        // Sample views
        let sampleViews: [(String, UIView)] = [
            ("UILabel", makeSampleLabel()),
            ("UIImageView", makeSampleImageView()),
            ("UIButton", makeSampleButton()),
            ("UISwitch", makeSampleSwitch()),
            ("UISlider", makeSampleSlider()),
            ("UITextField", makeSampleTextField()),
            ("UISegmentedControl", makeSampleSegmentedControl()),
        ]

        for (name, sampleView) in sampleViews {
            let rowView = makeRow(title: name, contentView: sampleView)
            stackView.addArrangedSubview(rowView)
        }
    }

    private func updateSceneInfo() {
        guard let windowScene = view.window?.windowScene else {
            sceneInfoLabel.text = "No WindowScene"
            return
        }
        let activationState = switch windowScene.activationState {
        case .foregroundActive: "ForegroundActive"
        case .foregroundInactive: "ForegroundInactive"
        case .background: "Background"
        case .unattached: "Unattached"
        @unknown default: "Unknown"
        }
        let sceneCount = UIApplication.shared.connectedScenes.count
        sceneInfoLabel.text = "Scene: \(windowScene.title ?? "untitled")\nState: \(activationState)\nConnected Scenes: \(sceneCount)"
    }

    // MARK: - Scene Actions

    @objc private func openDetailScene() {
        let userActivity = NSUserActivity(activityType: "detail")
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil)
    }

    @objc private func openSettingsScene() {
        let userActivity = NSUserActivity(activityType: "settings")
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil)
    }

    // MARK: - UI Factories

    private func makeActionButton(title: String, systemImage: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("  \(title)", for: .normal)
        button.setImage(UIImage(systemName: systemImage), for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.addTarget(self, action: action, for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }

    private func makeSampleLabel() -> UILabel {
        let label = UILabel()
        label.text = "Hello, Lookin!"
        label.textColor = .label
        return label
    }

    private func makeSampleImageView() -> UIImageView {
        let imageView = UIImageView(image: UIImage(systemName: "eye.fill"))
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        return imageView
    }

    private func makeSampleButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Sample Button", for: .normal)
        return button
    }

    private func makeSampleSwitch() -> UISwitch {
        let toggle = UISwitch()
        toggle.isOn = true
        return toggle
    }

    private func makeSampleSlider() -> UISlider {
        let slider = UISlider()
        slider.value = 0.5
        return slider
    }

    private func makeSampleTextField() -> UITextField {
        let textField = UITextField()
        textField.placeholder = "Type something..."
        textField.borderStyle = .roundedRect
        return textField
    }

    private func makeSampleSegmentedControl() -> UISegmentedControl {
        let segmentedControl = UISegmentedControl(items: ["Light", "Dark", "Auto"])
        segmentedControl.selectedSegmentIndex = 2
        return segmentedControl
    }

    private func makeRow(title: String, contentView: UIView) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 8

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .caption1)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(titleLabel)
        containerView.addSubview(contentView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            contentView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
        ])

        return containerView
    }
}
