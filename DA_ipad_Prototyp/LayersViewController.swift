//
//  LayersViewController.swift
//  DA_ipad_Prototyp
//
//  Created by Roland Prinz on 10.12.15.
//
//

import UIKit
import AVFoundation

class LayersViewController: UIViewController, AVSpeechSynthesizerDelegate, UIGestureRecognizerDelegate {
    let touchesForSwipe = 5
    let touchesForPan = 1
    
    @IBOutlet var labelState: UILabel!
    @IBOutlet var stateSettings: UILabel!
    @IBOutlet var stateDistance: UILabel!
    @IBOutlet var stateCustomLocation: UILabel!
    @IBOutlet var stateLayers: UILabel!
    @IBOutlet var stateLocation: UILabel!
    @IBOutlet var stateSilence: UILabel!
    @IBOutlet var stateHelp: UILabel!
    @IBOutlet var speakText: UILabel!
    @IBOutlet var stateStart: UILabel!
    
    let speechSynthesizer = AVSpeechSynthesizer()
    let swipeLeft = UISwipeGestureRecognizer()
    let swipeRight = UISwipeGestureRecognizer()
    let swipeDown = UISwipeGestureRecognizer()
    let swipeUp = UISwipeGestureRecognizer()
    let doubleTap = UITapGestureRecognizer()
    let pinchRecognizer = UIPinchGestureRecognizer()
    let panRecognizer = UIPanGestureRecognizer()
    
    var currentState = "Layers"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeState(5)
        
        // Create and configure Swip Recognizer
        self.swipeLeft.direction = .Left
        self.swipeLeft.numberOfTouchesRequired = touchesForSwipe
        self.swipeLeft.addTarget(self, action: "handleSwipeLeft:")
        self.view.addGestureRecognizer(self.swipeLeft)
        swipeLeft.delegate = self
        self.swipeRight.numberOfTouchesRequired = touchesForSwipe
        self.swipeRight.direction = .Right
        self.swipeRight.addTarget(self, action: "handleSwipeRight:")
        self.view.addGestureRecognizer(self.swipeRight)
        swipeRight.delegate = self
        self.swipeDown.numberOfTouchesRequired = touchesForSwipe
        self.swipeDown.direction = .Down
        self.swipeDown.addTarget(self, action: "handleSwipeDown:")
        self.view.addGestureRecognizer(self.swipeDown)
        swipeDown.delegate = self
        self.swipeUp.numberOfTouchesRequired = touchesForSwipe
        self.swipeUp.direction = .Up
        self.swipeUp.addTarget(self, action: "handleSwipeUp:")
        self.view.addGestureRecognizer(self.swipeUp)
        swipeUp.delegate = self
        
        // Create and configure DoubleTap Recognizer
        self.doubleTap.addTarget(self, action: "handleDoubleTap")
        self.doubleTap.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(doubleTap)
        
        // Create and configure Pinch Recognizer
        self.pinchRecognizer.addTarget(self, action: "handlePinch:")
        self.view.addGestureRecognizer(pinchRecognizer)
        
        // Create and configure Pan Recognizer
        self.panRecognizer.addTarget(self, action: "handlePan:")
        self.panRecognizer.maximumNumberOfTouches = touchesForPan
        self.panRecognizer.minimumNumberOfTouches = touchesForPan
        self.view.addGestureRecognizer(panRecognizer)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func speak(text: String) {
        speakText.text = text
        let speechUtterance = AVSpeechUtterance(string: text)
        speechSynthesizer.speakUtterance(speechUtterance)
    }
    
    func changeState(number :Int) {
        let active = UIColor.init(red: 0.212, green: 0.427, blue: 0.655, alpha: 1.0)
        let inactive = UIColor.grayColor()
        
        stateHelp.backgroundColor = inactive
        stateStart.backgroundColor = inactive
        stateSilence.backgroundColor = inactive
        stateSettings.backgroundColor = inactive
        stateLocation.backgroundColor = inactive
        stateLayers.backgroundColor = inactive
        stateCustomLocation.backgroundColor = inactive
        stateDistance.backgroundColor = inactive
        
        switch(number) {
        case 0: stateStart.backgroundColor = active; currentState = "Start"
        case 1: stateHelp.backgroundColor = active; currentState = "Help"
        case 2: stateSilence.backgroundColor = active; currentState = "Discover"
        case 3: stateSettings.backgroundColor = active; currentState = "Settings"
        case 4: stateLocation.backgroundColor = active; currentState = "Location"
        case 5: stateLayers.backgroundColor = active; currentState = "Layers"
        case 6: stateCustomLocation.backgroundColor = active; currentState = "Custom Location"
        case 7: stateDistance.backgroundColor = active; currentState = "Distance"
        default: print("default clause reached")
        }
    }
    
    /********************************************************************
     * GESTURE RECOGNIZER - Swipe Left
     *********************************************************************/
    func handleSwipeLeft(gesture: UISwipeGestureRecognizer) {
        speak("Geste Wischen Links erkannt");
    }
    
    /********************************************************************
     * GESTURE RECOGNIZER - Swipe Right
     *********************************************************************/
    func handleSwipeRight(gesture: UISwipeGestureRecognizer) {
        speak("Geste Wischen Rechts erkannt");
    }
    
    /********************************************************************
     * GESTURE RECOGNIZER - Swipe Down
     *********************************************************************/
    func handleSwipeDown(gesture: UISwipeGestureRecognizer) {
       speak("Geste Wischen nach Unten erkannt");
    }
    
    /********************************************************************
     * GESTURE RECOGNIZER - Swipe Up
     *********************************************************************/
    func handleSwipeUp(gesture: UISwipeGestureRecognizer) {
        speak("Geste Wischen nach Oben erkannt");
    }
    
    /********************************************************************
     * GESTURE RECOGNIZER - Double Tab
     *********************************************************************/
    func handleDoubleTap() {
        speak("Double Tap");
    }
    
    /*********************************************************************
     * GESTURE RECOGNIZER - Pinch
     *********************************************************************/
    func handlePinch(gesture: UIPinchGestureRecognizer) {
        if(gesture.scale > 2.0) {
            if(gesture.state == UIGestureRecognizerState.Ended)
            {
                //Pinch open detected
                speak("Geste Pinch Open erkannt")
                dismissViewControllerAnimated(false, completion: nil)
                //performSegueWithIdentifier("goToDiscoverView", sender: nil)
            }
            
        }
    }
    
    /*********************************************************************
     * GESTURE RECOGNIZER - Pan
     *********************************************************************/
    func handlePan(gesture: UIPanGestureRecognizer) {
        if(gesture.state == UIGestureRecognizerState.Ended)
        {
            speak("Geste Drag erkannt")
        }
    
    }

    
    
}
