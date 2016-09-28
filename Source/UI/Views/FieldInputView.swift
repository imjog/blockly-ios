/*
* Copyright 2016 Google Inc. All Rights Reserved.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation

/**
 View for rendering a `FieldInputLayout`.
 */
@objc(BKYFieldInputView)
open class FieldInputView: FieldView {
  // MARK: - Properties

  /// Convenience property for accessing `self.layout` as a `FieldInputLayout`
  open var fieldInputLayout: FieldInputLayout? {
    return layout as? FieldInputLayout
  }

  /// The text field to render
  open fileprivate(set) lazy var textField: InsetTextField = {
    let textField = InsetTextField(frame: CGRect.zero)
    textField.delegate = self
    textField.borderStyle = .roundedRect
    textField.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    textField
      .addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    return textField
  }()

  // MARK: - Initializers

  /// Initializes the input field view.
  public required init() {
    super.init(frame: CGRect.zero)

    addSubview(textField)
  }

  /**
   :nodoc:
   - Warning: This is currently unsupported.
   */
  public required init?(coder aDecoder: NSCoder) {
    fatalError("Called unsupported initializer")
  }

  // MARK: - Super

  open override func refreshView(
    forFlags flags: LayoutFlag = LayoutFlag.All, animated: Bool = false)
  {
    super.refreshView(forFlags: flags, animated: animated)

    guard let fieldInputLayout = self.fieldInputLayout else {
      return
    }

    runAnimatableCode(animated) {
      if flags.intersectsWith(Layout.Flag_NeedsDisplay) {
        let text = fieldInputLayout.text
        let textField = self.textField
        if textField.text != text {
          textField.text = text
        }

        // TODO:(#27) Standardize this font
        textField.font = UIFont.systemFont(ofSize: 14 * fieldInputLayout.engine.scale)
        textField.insetPadding =
          fieldInputLayout.config.edgeInsets(for: LayoutConfig.FieldTextFieldInsetPadding)
      }
    }
  }

  open override func prepareForReuse() {
    super.prepareForReuse()

    textField.text = ""
  }

  // MARK: - Private

  fileprivate dynamic func textFieldDidChange(_ sender: UITextField) {
    self.fieldInputLayout?.updateText(self.textField.text ?? "")
  }
}

// MARK: - UITextFieldDelegate

extension FieldInputView: UITextFieldDelegate {
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    // This will dismiss the keyboard
    textField.resignFirstResponder()
    return true
  }
}

// MARK: - FieldLayoutMeasurer implementation

extension FieldInputView: FieldLayoutMeasurer {
  public static func measureLayout(_ layout: FieldLayout, scale: CGFloat) -> CGSize {
    guard let fieldInputLayout = layout as? FieldInputLayout else {
      bky_assertionFailure("`layout` is of type `\(type(of: layout))`. " +
        "Expected type `FieldInputLayout`.")
      return CGSize.zero
    }

    let textPadding = layout.config.edgeInsets(for: LayoutConfig.FieldTextFieldInsetPadding)
    let maxWidth = layout.config.float(for: LayoutConfig.FieldTextFieldMaximumWidth)
    // TODO:(#27) Use a standardized font size that can be configurable for the project
    let measureText = fieldInputLayout.text + " "
    let font = UIFont.systemFont(ofSize: 14 * scale)
    var measureSize = measureText.bky_singleLineSize(forFont: font)
    measureSize.height += textPadding.top + textPadding.bottom
    measureSize.width =
      min(measureSize.width + textPadding.leading + textPadding.trailing, maxWidth)
    return measureSize
  }
}