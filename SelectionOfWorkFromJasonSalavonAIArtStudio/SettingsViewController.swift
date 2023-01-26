//
//  SettingsViewController.swift
//  VisionDetection
//
//  Created by Jason Salavon Studio on 11/12/21.
//  Copyright © 2021 Jason Salavon Studio. All rights reserved.
//

import UIKit

/*
 The SettingsViewController controls the hamburger settings menu that slides out of the right side of the MainViewController.
 
 Get to the AboutViewController and UsageTipsViewController from here.
 */
class SettingsViewController: UIViewController {
    
    weak var settingsDelegate: SettingsDelegate?
    override var prefersStatusBarHidden: Bool { return true }
    private let sliderValues: [Float] = [0.5, 0.625, 0.75, 0.875, 1.0, 1.125, 1.25, 1.375, 1.5]
    var numTiles: Int = 1
    var numRows: Int = 1
    var numColumns: Int = 1
    var animationID: Int = 1

    @IBOutlet weak var tileBackgroundSwitch: UISwitch!
    @IBOutlet weak var rotationToggleSwitch: UISwitch!
    @IBOutlet weak var rowCountSlider: UISlider!
    @IBOutlet weak var columnCountSlider: UISlider!
    @IBOutlet weak var rowCountLabel: UILabel!
    @IBOutlet weak var columnCountLabel: UILabel!
    @IBOutlet weak var animationButton: UIButton!
    
    // MARK: LIFECYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Switch values for UI
        tileBackgroundSwitch.isOn = UserDefaults.standard.bool(forKey: "tileBackgroundSwitch")
        rotationToggleSwitch.isOn = (settingsDelegate?.getRotationToggle())!
        
        rowCountSlider.value = Float(UserDefaults.standard.integer(forKey: "tileRowCount"))
        columnCountSlider.value = Float(UserDefaults.standard.integer(forKey: "tileColumnCount"))
        updateRowAndColumnLabels()
        
        animationID = UserDefaults.standard.integer(forKey: "animationID")
        setAnimationText()
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    // END OF LIFECYCLE

    // MARK: IB ACTIONS
    /// Segues
    @IBAction func dismissSettingsView(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func aboutButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "settingsToAbout", sender: self)
    }
    
    @IBAction func usageTipsButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "settingsToUsageTips", sender: self)
    }
    
    @IBAction func rotationToggle(_ sender: UISwitch) {
        settingsDelegate?.setRotationToggle(to: sender.isOn)
    }
    
//    @IBAction func restorePurchasesButtonTapped(_ sender: UIButton) {
//        settingsDelegate?.restorePurchasedItems()  
//        dismissSettingsView(sender)
//    }
    
    @IBAction func tileBackgroundToggle(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "tileBackgroundSwitch")
        settingsDelegate?.switchTileBackground(to: sender.isOn)
    }
    
    @IBAction func tileRowSliderChanged(_ sender: UISlider) {
        numRows = Int(sender.value)
        settingsDelegate?.setupTilesByGrid(rowCount: numRows, columnCount: numColumns)
        UserDefaults.standard.set(numRows, forKey: "tileRowCount")
        rowCountLabel.text = "\(numRows)"
    }
    
    @IBAction func tileColumnSliderChanged(_ sender: UISlider) {
        numColumns = Int(sender.value)
        settingsDelegate?.setupTilesByGrid(rowCount: numRows, columnCount: numColumns)
        UserDefaults.standard.set(numColumns, forKey: "tileColumnCount")
        columnCountLabel.text = "\(numColumns)"
    }
    
    @IBAction func animationButtonTapped(_ sender: UIButton) {
        animationID += 1
        if animationID > 4 { animationID = 1 }
        
        setAnimationText()
        settingsDelegate?.setAnimation(id: animationID)
        UserDefaults.standard.set(animationID, forKey: "animationID")
    }
    // END OF IB ACTIONS
    
    
    // MARK: UI METHODS
    func setAnimationText() {
        switch (animationID) {
        case 1:
            animationButton.setTitle("Free", for: .normal)
        case 2:
            animationButton.setTitle("Orbit", for: .normal)
        case 3:
            animationButton.setTitle("Flow", for: .normal)
        case 4:
            animationButton.setTitle("Swim", for: .normal)
        default:
            animationButton.setTitle("Free", for: .normal)
        }
    }
    
    private func updateRowAndColumnLabels() {
        numRows = Int(rowCountSlider.value)
        rowCountLabel.text = "\(numRows)"
        
        numColumns = Int(columnCountSlider.value)
        columnCountLabel.text = "\(numColumns)"
    }
    // END OF UI METHODS
}


protocol SettingsDelegate: class {
    func setupTilesByCount(count: Int)
    func setupTilesByGrid(rowCount: Int, columnCount: Int)
    func switchTileBackground(to newValue: Bool)
    func setRotationToggle(to newValue: Bool)
    func getRotationToggle() -> Bool
    func setAnimation(id: Int)
}
