//
//  DatePickerViewController.swift
//  SwiftTweaks
//
//  Created by Antti Vekkeli on 11.8.2020.
//

import Foundation
import UIKit

internal protocol DatePickerViewControllerDelegate {
    func datePickerViewControllerDidPressDismissButton(_ tweakSelectionViewController: DatePickerViewController)
}

/// Allows the user to select an option for a StringListOption value.
internal class DatePickerViewController: UIViewController {
    private let delegate: DatePickerViewControllerDelegate
    
    private let tweak: Tweak<Date>
    private let tweakStore: TweakStore
    
    private var dateTimePickerView: DateTimePickerView!
    
    init(anyTweak: AnyTweak, tweakStore: TweakStore, delegate: DatePickerViewControllerDelegate) {
        assert(anyTweak.tweakViewDataType == .date, "Can only edit Date in this UI.")
        self.dateTimePickerView = DateTimePickerView(anyTweak: anyTweak, tweakStore: tweakStore)
        self.tweak = anyTweak.tweak as! Tweak<Date>
        self.tweakStore = tweakStore
        self.delegate = delegate
        
        super.init(nibName: nil, bundle: nil)
        
        title = tweak.tweakName
        toolbarItems = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: TweaksViewController.dismissButtonTitle, style: .done, target: self, action: #selector(self.dismissButtonTapped))
        ]
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(DatePickerViewController.restoreDefaultValue))
        self.navigationItem.rightBarButtonItem?.tintColor = AppTheme.Colors.controlDestructive
        
        view.backgroundColor = .white
        edgesForExtendedLayout = []
        
        view.addSubview(dateTimePickerView)
        dateTimePickerView.frame = view.bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    // MARK: Events
    
    @objc private func restoreDefaultValue() {
        let confirmationAlert = UIAlertController(title: "Reset This Tweak?", message: "Your other tweaks will be left alone. The default value is \(tweak.defaultValue)", preferredStyle: .actionSheet)
        confirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        confirmationAlert.addAction(UIAlertAction(title: "Reset Tweak", style: .destructive, handler: { _ in
            self.dateTimePickerView.setDateTime(self.tweak.defaultValue)
        }))
        present(confirmationAlert, animated: true, completion: nil)
    }
    
    @objc private func dismissButtonTapped() {
        delegate.datePickerViewControllerDidPressDismissButton(self)
    }
}


class DateTimePickerView: UIView {
    
    private let tweak: Tweak<Date>
    private let tweakStore: TweakStore
    
    private(set) var dateTime: Date {
        didSet {
            tweakStore.setValue(
                .date(value: dateTime,
                    defaultValue: tweak.defaultValue,
                    min: tweak.minimumValue,
                    max: tweak.maximumValue
                ),
                forTweak: AnyTweak(tweak: tweak)
            )
        }
    }
    
    func setDateTime(_ dateTime: Date) {
        var newDateTime = dateTime
        
        if let max = tweak.maximumValue, max <= newDateTime {
            newDateTime = max
        } else if let min = tweak.minimumValue, min >= newDateTime {
            newDateTime = min
        }
        
        self.dateTime = newDateTime
        
        if timePicker.date != newDateTime {
            timePicker.date = newDateTime
        }
        if datePicker.date != newDateTime {
            datePicker.date = newDateTime
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = TweakDateFormatter.dateFormatter()
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = TweakDateFormatter.dateFormatter()
        formatter.dateStyle = .none
        return formatter
    }()
        
    fileprivate var timeLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.groupTableViewBackground
        label.textColor = AppTheme.Colors.sectionHeaderTitleColor
        label.text = "Time"
        return label
    }()
    
    fileprivate var dateLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.groupTableViewBackground
        label.textColor = AppTheme.Colors.sectionHeaderTitleColor
        label.text = "Date"
        return label
    }()
    
    fileprivate var timePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.backgroundColor = .white
        picker.datePickerMode = .time
        picker.addTarget(self, action: #selector(datePickerDidChangeValue(_:)), for: .valueChanged)
        return picker
    }()
    
    fileprivate var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.backgroundColor = .white
        picker.datePickerMode = .date
        picker.addTarget(self, action: #selector(datePickerDidChangeValue(_:)), for: .valueChanged)
        return picker
    }()
    
    init(anyTweak: AnyTweak, tweakStore: TweakStore) {
        assert(anyTweak.tweakViewDataType == .date, "Can only edit Date in this UI.")
        self.tweak = anyTweak.tweak as! Tweak<Date>
        self.tweakStore = tweakStore
        self.dateTime = tweakStore.currentValueForTweak(self.tweak)
        
        super.init(frame: .zero)
        backgroundColor = UIColor.groupTableViewBackground
        
        addSubview(dateLabel)
        addSubview(datePicker)
        addSubview(timeLabel)
        addSubview(timePicker)
        
        setDateTime(dateTime) // Update pickers
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        
        dateLabel.frame = CGRect(
            origin: CGPoint(x: 16, y: bounds.minY),
            size: CGSize(width: bounds.width, height: 44))
        datePicker.frame = CGRect(
            origin: CGPoint(x: 0, y: dateLabel.frame.maxY),
            size: CGSize(width: bounds.width, height: 160))
        timeLabel.frame = CGRect(
            origin: CGPoint(x: 16, y: datePicker.frame.maxY),
            size: CGSize(width: bounds.width, height: 44))
        timePicker.frame = CGRect(
            origin: CGPoint(x: 0, y: timeLabel.frame.maxY),
            size: CGSize(width: bounds.width, height: 160))
    }
    
    @objc func datePickerDidChangeValue(_ picker: UIDatePicker) {
        if picker == datePicker {
            setDateTime(combine(date: picker.date, time: dateTime) ?? picker.date)
        }
        if picker == timePicker {
            setDateTime(combine(date: dateTime, time: picker.date) ?? picker.date)
        }
    }
    
    private func combine(date: Date, time: Date) -> Date? {
        let calendar = NSCalendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        var components = DateComponents()
        components.year = dateComponents.year
        components.month = dateComponents.month
        components.day = dateComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = timeComponents.second
        
        return calendar.date(from: components)
    }
}
