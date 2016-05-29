//
//  ViewController.swift
//  DA_ipad_Prototyp
//
//  Created by Roland Prinz on 24.11.15.
//
//

import UIKit
import AVFoundation
import Parse
import AudioToolbox

extension UIImage {
    func getPixelColor(pos: CGPoint) -> UIColor {
        
        let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage))
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

extension UIColor {
    
    func getColorDifference(fromColor: UIColor) -> Int {
        // get the current color's red, green, blue and alpha values
        var red:CGFloat = 0
        var green:CGFloat = 0
        var blue:CGFloat = 0
        var alpha:CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // get the fromColor's red, green, blue and alpha values
        var fromRed:CGFloat = 0
        var fromGreen:CGFloat = 0
        var fromBlue:CGFloat = 0
        var fromAlpha:CGFloat = 0
        fromColor.getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: &fromAlpha)
        
        let redValue = (max(red, fromRed) - min(red, fromRed)) * 255
        let greenValue = (max(green, fromGreen) - min(green, fromGreen)) * 255
        let blueValue = (max(blue, fromBlue) - min(blue, fromBlue)) * 255
        
        return Int(redValue + greenValue + blueValue)
    }
    
    func getNextMatch() -> String {
        let red = UIColor(red: 0.945, green: 0.059, blue: 0.243, alpha:1.00)
        let green = UIColor(red: 0.071, green: 0.443, blue: 0.098, alpha:1.00)
        //let green = UIColor(red: 0.165, green: 0.627, blue: 0.250, alpha:1.00)
        let yellow = UIColor(red: 0.831, green: 0.612, blue: 0.137, alpha:1.00)
        let blue = UIColor(red: 0.059, green: 0.376, blue: 0.569, alpha:1.00)
        
        var bestIndex = 0
        var bestValue = 999
        
        let colors :[UIColor] = [red, green, yellow, blue]
        
        for (index, color) in colors.enumerate() {
            let diff = self.getColorDifference(color)
            if(diff < bestValue) {
                bestIndex = index
                bestValue = diff
            }
        }
        
        var name = "none"
        
        switch(bestIndex){
        case 0: name = "red"
        case 1: name = "green"
        case 2: name = "yellow"
        case 3: name = "blue"
        default: name = "none"
        }
        
        if(bestValue > 100) {
            //keine Karte gefunden
            name = "none"
        }

        //puts("Name: \(name) - value: \(bestValue).")
        return name
    }
}

// text Keys from property file
var textKeyPath = NSBundle.mainBundle().pathForResource("TextKeys", ofType: "plist")
var textKeyDict = NSDictionary(contentsOfFile: textKeyPath!)

class DiscoverViewController: UIViewController, AVSpeechSynthesizerDelegate {
    
    // GUI Variablen
    @IBOutlet var methodStatus: UILabel!
    @IBOutlet var touchStatus: UILabel!
    @IBOutlet var tapStatus: UILabel!
    @IBOutlet var singleTouchX: UILabel!
    @IBOutlet var singleTouchY: UILabel!
    @IBOutlet var singleTouch: UILabel!
    @IBOutlet var touchTotal: UILabel!
    @IBOutlet var touchTotal2: UILabel!
    @IBOutlet var speakText: UILabel!
    @IBOutlet var stateHelp: UILabel!
    @IBOutlet var stateStart: UILabel!
    @IBOutlet var stateSilence: UILabel!
    @IBOutlet var stateSettings: UILabel!
    @IBOutlet var stateLocation: UILabel!
    @IBOutlet var stateLayers: UILabel!
    @IBOutlet var stateCustomLocation: UILabel!
    @IBOutlet var stateCustomLocationSelected: UILabel!
    @IBOutlet var stateDistance: UILabel!
    @IBOutlet var preview: UIImageView!
    
    // Konfigurations Parameter
    let maxPixelX = 1366
    let maxPixelY = 1024
    let countTilesWidth = 53.5
    let countTilesHeight = 39.5

    let fireTime = 1.0
    var fireCameraTime = 2.0
    let sensitivy: CGFloat = 0.5
    let touchesForSwipe = 4
    let touchesForDrag = 1
    let minimumPressDurationTouchAndHold = 1.0
    let touchesForTapAndHold = 1
    
    let cameraSensor = false
    let defaultMap = "green"
    
    //Variablen & Definitionen
    var speech :Speech = Speech.init()
    weak var timer:NSTimer?
    weak var cameraTimer:NSTimer?
    var touchCountAll = 0
    var tileWidth: Double = 0.0
    var tileHeight: Double = 0.0
    var currentState : State = State.Start
    var currentSettingsState : SettingsState = SettingsState.Speech
    var currentSettingsStateEntered = false
    var currentHelpState :HelpState = HelpState.CurrentState
    var currentHelpStateEntered = false
    var currentLayerStateEntered = -1
    var currentLocationStateEntered = -1
    var lastState : State = State.Start
    var mapObject = Map.init()
    var activeLocation :GeoPoint!
    
    var layersAll = OrderedDictionary<String,Bool>()
    var layersActive = OrderedDictionary<String,Bool>()
    
    //Debug Settings
    var debugGestures = false
    var debugStates = false
    
    //Gesture Recognizer
    var gestureRecognizers = Set<UIGestureRecognizer>()
    let doubleTap = UITapGestureRecognizer()
    let fourFingersDoubleTap = UITapGestureRecognizer()
    let fourFingersDrippleTap = UITapGestureRecognizer()
    let swipeLeft = UISwipeGestureRecognizer()
    let swipeRight = UISwipeGestureRecognizer()
    let swipeDown = UISwipeGestureRecognizer()
    let swipeUp = UISwipeGestureRecognizer()
    let pinchRecognizer = UIPinchGestureRecognizer()
    var panRecognizer = UIPanGestureRecognizer()
    let tapAndHold = UILongPressGestureRecognizer()
    let rotationRecognizer = UIRotationGestureRecognizer()
    
    var lastRotation = ""
    
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var previewLayer : AVCaptureVideoPreviewLayer?
    var stillImageOutput = AVCaptureStillImageOutput()
    
     var audioPlayer = AVAudioPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Konfiguration der Spracheinstellungen
        speech.view = self
        self.speech.speechSynthesizer.delegate = self
        
        if(!Reachability.isConnectedToNetwork()) {
            speech.speak("Keine Verbindung zum Internet vorhanden - Applikation nicht einsatzbereit")
            return
        }
        
        mapObject.view = self

        //Berechnung der einzelnen Sektoren Höhe und Breite
        tileWidth = Double(maxPixelX) / countTilesWidth
        tileHeight = Double(maxPixelY) / countTilesHeight
        
        // Create and configure DoubleTap Recognizer
        self.doubleTap.addTarget(self, action: "handleDoubleTap")
        self.doubleTap.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(doubleTap)
        gestureRecognizers.insert(doubleTap)
        
        // Create and configure DoubleTap Recognizer
        self.fourFingersDoubleTap.addTarget(self, action: "handleFourFingersDoubleTap")
        self.fourFingersDoubleTap.numberOfTapsRequired = 2
        self.fourFingersDoubleTap.numberOfTouchesRequired = 4
        self.view.addGestureRecognizer(fourFingersDoubleTap)
        
        // Create and configure DoubleTap Recognizer
        self.fourFingersDrippleTap.addTarget(self, action: "handleFourFingersDrippleTap")
        self.fourFingersDrippleTap.numberOfTapsRequired = 3
        self.fourFingersDrippleTap.numberOfTouchesRequired = 4
        self.view.addGestureRecognizer(fourFingersDrippleTap)
        
        // Create and configure Swip Recognizer
        self.swipeLeft.direction = .Left
        self.swipeLeft.numberOfTouchesRequired = touchesForSwipe
        self.swipeLeft.addTarget(self, action: "handleSwipeLeft:")
        gestureRecognizers.insert(swipeLeft)
        //self.view.addGestureRecognizer(self.swipeLeft)
        self.swipeRight.numberOfTouchesRequired = touchesForSwipe
        self.swipeRight.direction = .Right
        self.swipeRight.addTarget(self, action: "handleSwipeRight:")
        gestureRecognizers.insert(swipeRight)
        //self.view.addGestureRecognizer(self.swipeRight)
        self.swipeDown.numberOfTouchesRequired = touchesForSwipe
        self.swipeDown.direction = .Down
        self.swipeDown.addTarget(self, action: "handleSwipeDown:")
        gestureRecognizers.insert(swipeDown)
        //self.view.addGestureRecognizer(self.swipeDown)
        self.swipeUp.numberOfTouchesRequired = touchesForSwipe
        self.swipeUp.direction = .Up
        self.swipeUp.addTarget(self, action: "handleSwipeUp:")
        gestureRecognizers.insert(swipeUp)
        self.view.addGestureRecognizer(swipeUp)

        // Create and configure Pinch Recognizer
        self.pinchRecognizer.addTarget(self, action: "handlePinch:")
        self.view.addGestureRecognizer(pinchRecognizer)
        gestureRecognizers.insert(pinchRecognizer)
        
        // Create and configure Rotation Recognizer
        self.rotationRecognizer.addTarget(self, action: "handleRotation:")
        self.view.addGestureRecognizer(rotationRecognizer)
        gestureRecognizers.insert(rotationRecognizer)
        
        // Create and configure Pan Recognizer
        self.panRecognizer = PanDirectionGestureRecognizer(direction: PanDirection.Horizontal, target: self, action: "handlePan:")
        //self.panRecognizer.addTarget(self, action: "handlePan:")
        self.panRecognizer.maximumNumberOfTouches = touchesForDrag
        self.panRecognizer.minimumNumberOfTouches = touchesForDrag
        self.view.addGestureRecognizer(panRecognizer)
        gestureRecognizers.insert(panRecognizer)

        // Create and configure Tap and Hold (1)
        self.tapAndHold.minimumPressDuration = minimumPressDurationTouchAndHold
        self.tapAndHold.numberOfTouchesRequired = touchesForTapAndHold
        self.tapAndHold.addTarget(self, action: "handleTapAndHold:")
        self.view.addGestureRecognizer(self.tapAndHold)
        gestureRecognizers.insert(tapAndHold)
        
        // Set Start State
        changeState(State.Start)
        
        // Start Camera for Map detection
        speakText.backgroundColor = UIColor.grayColor()
        if(cameraSensor == true) {
            captureSession.sessionPreset = AVCaptureSessionPresetLow
            let devices = AVCaptureDevice.devices()
            for device in devices {
                // Make sure this particular device supports video
                if (device.hasMediaType(AVMediaTypeVideo)) {
                    // Finally check the position and confirm we've got the front camera
                    if(device.position == AVCaptureDevicePosition.Front) {
                        captureDevice = device as? AVCaptureDevice
                    }
                }
            }
            
            cameraTimer = NSTimer.scheduledTimerWithTimeInterval(fireCameraTime, target: self, selector: "fireMapCheck:", userInfo: nil, repeats: true)
        }
        
        // Configure Layers
        getAllLayers()
        
        // Everything done -> let's start :)
        speech.speak("Applikation geladen. Viel Spaß damit!")        
    }
    
    func getTextKey(key :String) -> String {
        return textKeyDict?.objectForKey(key) as! String
    }
    
    /******************************
        CAMERA / MAP CHECK
    *******************************/
    
    func fireMapCheck(timer: NSTimer) {
        if captureDevice != nil && !captureSession.running {
            beginSession()
         }
        
        saveToCamera()
    }
    
    func mapChanged(newMap: String) {
        cameraTimer?.invalidate()
        
        if(cameraSensor == false)
        {
            if(newMap == "none") {
                mapObject.setMap(newMap)
                speech.speak(getTextKey("Map_"+newMap) + getTextKey("Transition_DiscToStart"))
                changeState(State.Start)
            }
            else {
                mapObject.setMap(newMap)
                speech.speak(getTextKey("Map_"+newMap) + getTextKey("Transition_StartToDisc"))
                changeState(State.Discover)
                speech.speak(mapObject.info, interrupt: false)
            }
            
        } else {
            if(mapObject.name == "none") {
                mapObject.setMap(newMap)
                speech.speak(getTextKey("Map_"+newMap) + getTextKey("Transition_StartToDisc"))
                changeState(State.Discover)
                fireCameraTime = 10.0
                speech.speak(mapObject.info, interrupt: false)
            } else {
                if(newMap == "none") {
                    mapObject.setMap(newMap)
                    speech.speak(getTextKey("Map_"+newMap) + getTextKey("Transition_DiscToStart"))
                    changeState(State.Start)
                    fireCameraTime = 2.0
                } else {
                    mapObject.setMap(newMap)
                    speech.speak("Neue " + getTextKey("Map_"+newMap) + getTextKey("Transition_StartToDisc"))
                    changeState(State.Discover)
                    fireCameraTime = 10.0
                    speech.speak(mapObject.info, interrupt: false)
                }
            }
        }
        
        //Change Backgroundcolor in GUI
        switch(mapObject.name) {
        case "none": speakText.backgroundColor = UIColor.grayColor()
        case "red": speakText.backgroundColor = UIColor(red: 0.945, green: 0.059, blue: 0.243, alpha:1.00)
        case "green": speakText.backgroundColor = UIColor(red: 0.071, green: 0.443, blue: 0.098, alpha:1.00)
        case "yellow": speakText.backgroundColor = UIColor(red: 0.831, green: 0.612, blue: 0.137, alpha:1.00)
        case "blue": speakText.backgroundColor = UIColor(red: 0.059, green: 0.376, blue: 0.569, alpha:1.00)
        default: speakText.backgroundColor = UIColor.grayColor()
        }
        
        cameraTimer = NSTimer.scheduledTimerWithTimeInterval(fireCameraTime, target: self, selector: "fireMapCheck:", userInfo: nil, repeats: true)
    }
    
    func beginSession() {
        try? captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        //previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        //self.view.layer.addSublayer(previewLayer!)
        //previewLayer?.frame = self.view.layer.frame
        
        let stillImageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
        if captureSession.canAddOutput(stillImageOutput){
            stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            captureSession.addOutput(stillImageOutput)
            
            self.stillImageOutput = stillImageOutput
        }
        
        captureSession.startRunning()
    }
    
    func saveToCamera() {
        var mapType = "none"
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                let image = UIImage(data: imageData)
                
                self.preview.image = image
                //UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
                
                let width = (image?.size.width)! - 100
                let height = (image?.size.height)! - 100
                
                let y = (image?.size.height)! / 2
                let x = (image?.size.width)! / 2
                
                
                
                let color1 = image!.getPixelColor(CGPointMake(100, 100)).getNextMatch()
                let color2 = image!.getPixelColor(CGPointMake(x, y)).getNextMatch()
                let color3 = image!.getPixelColor(CGPointMake(width, height)).getNextMatch()
                let color4 = image!.getPixelColor(CGPointMake(100, width)).getNextMatch()
                
                //puts("color1: \(color1), color2: \(color2), color3: \(color3), color4: \(color4)")
                //Check if all values are the same
                
                if(color1 == color2 && color2 == color3 && color3 == color4) {
                    mapType = color1
                }
                
                if(mapType != self.mapObject.name) {
                    self.mapChanged(mapType)
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /******************************
     GESTURE RECOGNIZER
     ******************************/
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func changeTouchCount(number :Int) {
        touchCountAll = number
        touchTotal2.text = String(number)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        changeTouchCount((event?.allTouches()?.count)!)
        
        if let touch = touches.first {
            let tapCount = touch.tapCount
            tapStatus.text = "\(tapCount) taps"
            let point = touch.locationInView(self.view)
            singleTouchX.text = String(point.x)
            singleTouchY.text = String(point.y)
        }
       
        if(currentState == State.Discover || currentState == State.Location || currentState == State.Distance) {
            timer?.invalidate()
            if(debugGestures) {print("Began - Anzahl \(event?.allTouches()?.count)")}
            
            if(touchCountAll==1){
                timer = NSTimer.scheduledTimerWithTimeInterval(fireTime, target: self, selector: "fireTapAndHoldOne:", userInfo: event, repeats: false)
            } else if(touchCountAll==2 && currentState != State.Location) {
                timer = NSTimer.scheduledTimerWithTimeInterval(fireTime, target: self, selector: "fireTapAndHoldTwo:", userInfo: event, repeats: false)
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        changeTouchCount((event?.allTouches()?.count)!)
        
        if(currentState == State.Discover || currentState == State.Location || currentState == State.Distance) {
            if let touch = touches.first {
                let tapCount = touch.tapCount
                tapStatus.text = "\(tapCount) taps"
                let point = touch.locationInView(self.view)
                singleTouchX.text = String(point.x)
                singleTouchY.text = String(point.y)

                let locationNow = touch.locationInView(self.view)
                let locationPrev = touch.previousLocationInView(self.view)
                
                if(!distanceWithinRange(locationNow, p2: locationPrev, distanceRange: sensitivy)) {
                    timer?.invalidate()
                    if(debugGestures) { print("Moved - Anzahl \(event?.allTouches()?.count)") }
                    
                    if(touchCountAll==1 && currentState != State.Location){
                        if timer == nil {
                            timer = NSTimer.scheduledTimerWithTimeInterval(fireTime, target: self, selector: "fireTapAndHoldOne:", userInfo: event, repeats: false)
                        }
                    } else if(touchCountAll==2 && currentState != State.Location) {
                        if timer == nil {
                            timer = NSTimer.scheduledTimerWithTimeInterval(fireTime, target: self, selector: "fireTapAndHoldTwo:", userInfo: event, repeats: false)
                        }
                    }
                } else {
                    if(debugGestures) { print("movement within range") }
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touchCount = touches.count
        changeTouchCount((event?.allTouches()?.count)! - touchCount)
        
        if(currentState == State.Discover || currentState == State.Location || currentState == State.Distance) {
            if let touch = touches.first {
                let tapCount = touch.tapCount
                tapStatus.text = "\(tapCount) taps"
                let point = touch.locationInView(self.view)
                singleTouchX.text = String(point.x)
                singleTouchY.text = String(point.y)
            }
            
            timer?.invalidate()
            if(debugGestures) { print("Ended - Anzahl \(event?.allTouches()?.count)") }
            if(touchCountAll==1 && currentState != State.Location){
                if timer == nil {
                    timer = NSTimer.scheduledTimerWithTimeInterval(fireTime, target: self, selector: "fireTapAndHoldOne:", userInfo: event, repeats: false)
                }
            } else if(touchCountAll==2 && currentState != State.Location) {
                if timer == nil {
                    timer = NSTimer.scheduledTimerWithTimeInterval(fireTime, target: self, selector: "fireTapAndHoldTwo:", userInfo: event, repeats: false)
                }
            }
            if(touchCountAll==0){
                if(currentState == State.Location || currentState == State.Distance) {
                    changeState(State.Discover)
                    speech.stopSpeech()
                    activeLocation = nil
                }
            }
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        let touchCount = touches!.count
        changeTouchCount((event?.allTouches()?.count)! - touchCount)
        
        if(currentState == State.Discover || currentState == State.Location || currentState == State.Distance) {
            timer?.invalidate()
            if(debugGestures) { print("Cancelled - Anzahl \(event?.allTouches()?.count)") }
            if(touchCountAll==1 && currentState != State.Location){
                if timer == nil {
                    timer = NSTimer.scheduledTimerWithTimeInterval(fireTime, target: self, selector: "fireTapAndHoldOne:", userInfo: event, repeats: false)
                }
            } else if(touchCountAll==2 && currentState != State.Location) {
                if timer == nil {
                    timer = NSTimer.scheduledTimerWithTimeInterval(fireTime, target: self, selector: "fireTapAndHoldTwo:", userInfo: event, repeats: false)
                }
            }
            if(touchCountAll==0){
                if(currentState == State.Location || currentState == State.Distance) {
                    changeState(State.Discover)
                    speech.stopSpeech()
                    activeLocation = nil
                }
            }
        }
    }
    
    func distanceWithinRange(p1:CGPoint, p2:CGPoint, distanceRange:CGFloat) -> Bool {
        var result = false
        
        let p1x = p1.x
        let p1y = p1.y
        let p2x = p2.x
        let p2y = p2.y
        
        // calculate the distance between p1 and p2
        let dx = abs(p2x-p1x)
        let dy = abs(p2y-p1y)
        
        if(debugGestures) { print("dx: \(dx), dy: \(dy)") }
        
        // if the distance between BOTH p1 and p2 is less than or equal todistanceRange
        // then set result to 'true', otherwise result will be the default value of 'false'
        if(dx <= distanceRange) {
            if(dy <= distanceRange) {
                result = true
            }
        }
        
        return result
    }
    
    func fireTapAndHoldOne(timer: NSTimer) {
        speech.stopSpeech()
        changeState(State.Location)
        let event = timer.userInfo as! UIEvent
        let touches = event.allTouches()
        
        //let touches = timer.userInfo as! Set<UITouch>
        if let touch = touches!.first {
            let location = touch.locationInView(self.view)
            let x = Double(location.x)
            let y = Double(location.y)
            let calculatedGeoPoint = mapObject.calculateGeoPoint(x, touchY: y)
            
            calculatedGeoPoint.retrieveAllInfos({ (streetname) in
                self.activeLocation = calculatedGeoPoint
                self.speech.speakArray(calculatedGeoPoint.getInfosAsArrayForActiveLayers(self))
            })
        }
    }
    
    func fireTapAndHoldTwo(timer: NSTimer) {
        changeState(State.Distance)
        let event = timer.userInfo as! UIEvent
        let touches = event.allTouches()
        
        var x1 :Double = 0.0
        var y1 :Double = 0.0
        var x2 :Double = 0.0
        var y2 :Double = 0.0
        
        for (index, touch) in (touches?.enumerate())! {
            let location = touch.locationInView(self.view)
            let x = Double(location.x)
            let y = Double(location.y)
            if(index == 0) {
                x1 = x
                y1 = y
            }
            if(index == 1) {
                x2 = x
                y2 = y
            }
        }
        
        let point1 = mapObject.calculateGeoPoint(x1, touchY: y1)
        let point2 = mapObject.calculateGeoPoint(x2, touchY: y2)
        
        point1.getDistanceToPoint(point2, completion: { (distanz) in
            self.speech.speak(self.getTextKey("Transition_DiscToDist") + distanz + self.getTextKey("Transition_DiscToDist_2"))
        })
    }
    
    func changeState(state :State) {
        let active = UIColor.init(red: 0.212, green: 0.427, blue: 0.655, alpha: 1.0)
        
        disableAllGestureRecognizer()
        if(debugStates) { puts("transition from state: \(currentState.name()) - to state: \(state.name())") }
        
        switch(state) {
        case State.Start: stateStart.backgroundColor = active;
            //view.addGestureRecognizer(tapAndHold)                 // go to Help
            view.addGestureRecognizer(pinchRecognizer)              // go to Settings
            if(!cameraSensor) {
                view.addGestureRecognizer(doubleTap)                // go to Discover
            }
            view.addGestureRecognizer(rotationRecognizer)           // go to Help / Settings
            timer?.invalidate()
        case State.Help: stateHelp.backgroundColor = active;
            //view.addGestureRecognizer(tapAndHold)                 // go to Start
            view.addGestureRecognizer(pinchRecognizer)              // go to Start
            view.addGestureRecognizer(swipeLeft)                    // navigation in Help
            view.addGestureRecognizer(swipeRight)                   // navigation in Help
            view.addGestureRecognizer(rotationRecognizer)           // go to Help / Settings
            view.addGestureRecognizer(doubleTap)                    // navigation in Settings
            pinchRecognizer.requireGestureRecognizerToFail(swipeRight)
            pinchRecognizer.requireGestureRecognizerToFail(swipeLeft)
            changeSubStateHelp(HelpState.CurrentState, first: true)
        case State.Discover: stateSilence.backgroundColor = active;
            //view.addGestureRecognizer(pinchRecognizer)              // go to Layers
            view.addGestureRecognizer(swipeUp);                     // go to Custom Locations
            if(!cameraSensor) {
                view.addGestureRecognizer(doubleTap)                // go to Start
            }
            //view.addGestureRecognizer(rotationRecognizer)           // go to Help / Settings
            //pinchRecognizer.requireGestureRecognizerToFail(swipeUp)
        case State.Settings: stateSettings.backgroundColor = active;
            view.addGestureRecognizer(pinchRecognizer)              // go to Start
            view.addGestureRecognizer(swipeLeft)                    // navigation in Settings
            view.addGestureRecognizer(swipeRight)                   // navigation in Settings
            view.addGestureRecognizer(doubleTap)                    // navigation in Settings
            //view.addGestureRecognizer(panRecognizer)                // navigation in Settings
            view.addGestureRecognizer(rotationRecognizer)           // go to Help / Settings
            pinchRecognizer.requireGestureRecognizerToFail(swipeRight)
            pinchRecognizer.requireGestureRecognizerToFail(swipeLeft)
            changeSubStateSettings(SettingsState.Speech, first: true)
        case State.Location: stateLocation.backgroundColor = active;
            view.addGestureRecognizer(swipeDown);                   // navigation in Location
            view.addGestureRecognizer(swipeRight);                  // navigation in Location
            view.addGestureRecognizer(swipeLeft);                   // navigation in Location
        case State.Layers: stateLayers.backgroundColor = active;
            view.addGestureRecognizer(swipeLeft)                    // navigation in Layers
            view.addGestureRecognizer(swipeRight)                   // navigation in Layers
            view.addGestureRecognizer(swipeUp)                      // navigation in Layers
            view.addGestureRecognizer(swipeDown)                    // navigation in Layers
            view.addGestureRecognizer(doubleTap)                    // navigation in Layers
            //view.addGestureRecognizer(panRecognizer)                // navigation in Layers
            view.addGestureRecognizer(rotationRecognizer)           // go to Help / Settings
            view.addGestureRecognizer(pinchRecognizer)              // go to Discover
            pinchRecognizer.requireGestureRecognizerToFail(swipeRight)
            pinchRecognizer.requireGestureRecognizerToFail(swipeLeft)
            pinchRecognizer.requireGestureRecognizerToFail(swipeDown)
            pinchRecognizer.requireGestureRecognizerToFail(swipeUp)
            speech.speakOrderedDictionary(layersActive)
        case State.CustomLocation: stateCustomLocation.backgroundColor = active;
            view.addGestureRecognizer(swipeUp)
            view.addGestureRecognizer(swipeDown)                    // go to Discover
            view.addGestureRecognizer(pinchRecognizer)              // select custom location
            view.addGestureRecognizer(swipeLeft)                    // navigation in Layers
            view.addGestureRecognizer(swipeRight)                   // navigation in Layers
            view.addGestureRecognizer(rotationRecognizer)           // go to Help / Settings
            view.addGestureRecognizer(doubleTap)                    // go to Details
            pinchRecognizer.requireGestureRecognizerToFail(swipeRight)
            pinchRecognizer.requireGestureRecognizerToFail(swipeLeft)
            pinchRecognizer.requireGestureRecognizerToFail(swipeDown)
            pinchRecognizer.requireGestureRecognizerToFail(swipeUp)
            speech.speakArray(mapObject.getSavedLocationAsSingleStrings(true))
        case State.Distance: stateDistance.backgroundColor = active;
        }
        lastState = currentState
        currentState = state
    }
    
    func changeSubStateSettings(subState :SettingsState,  first: Bool) {
        currentSettingsState = subState
        
        switch(subState) {
        case SettingsState.Speech:
            speech.speak(getTextKey("State_Settings_Speech"), interrupt: !first)
        case SettingsState.Layers:
            speech.speak(getTextKey("State_Settings_Layers"), interrupt: !first)
        case SettingsState.SavedLocation:
            speech.speak(getTextKey("State_Settings_SavedLocation"), interrupt: !first)
        }
    }
    
    func changeSubStateHelp(subState :HelpState,  first: Bool) {
        currentHelpState = subState
        
        switch(subState) {
        case HelpState.CurrentState:
            speech.speak(getTextKey("State_Help_CurrentState"), interrupt: !first)
        case HelpState.Global:
            speech.speak(getTextKey("State_Help_Global"), interrupt: !first)
        }
    }
    
    func disableAllGestureRecognizer() {
        let inactive = UIColor.whiteColor()
        
        stateHelp.backgroundColor = inactive
        stateStart.backgroundColor = inactive
        stateSilence.backgroundColor = inactive
        stateSettings.backgroundColor = inactive
        stateLocation.backgroundColor = inactive
        stateLayers.backgroundColor = inactive
        stateCustomLocation.backgroundColor = inactive
        stateDistance.backgroundColor = inactive

        for recognizer in gestureRecognizers {
            view.removeGestureRecognizer(recognizer)
        }
    }
    
    /********************************************************************
     * GESTURE RECOGNIZER - Double Tab
     *********************************************************************/
    
    func handleDoubleTap() {
        switch(currentState) {
        case State.Start:
            if(cameraSensor == false) {
                mapChanged(defaultMap);
            }
        case State.Discover:
            if(cameraSensor == false) {
                mapChanged("none");
            }
        case State.Settings:
            if(!currentSettingsStateEntered) {
                speech.stopSpeech()
                currentSettingsStateEntered = true
                if(currentSettingsState == SettingsState.Layers) {
                    view.addGestureRecognizer(swipeUp)
                    view.addGestureRecognizer(swipeDown)
                    pinchRecognizer.requireGestureRecognizerToFail(swipeDown)
                    pinchRecognizer.requireGestureRecognizerToFail(swipeUp)
                    speech.speak(getTextKey("State_Settings_" + currentSettingsState.name()) + getTextKey("div_selected"))
                    speech.speakOrderedDictionary(layersAll)
                } else if(currentSettingsState == SettingsState.SavedLocation) {
                    view.addGestureRecognizer(swipeUp)
                    pinchRecognizer.requireGestureRecognizerToFail(swipeUp)
                    speech.speakArray(mapObject.getSavedLocationAsSingleStrings(false))
                } else if(currentSettingsState == SettingsState.Speech) {
                    speech.speak(getTextKey("div_settings_speech") + "\(speech.getCurrentSpeechRate())%")
                }
            } else {
                currentSettingsStateEntered = false
                if(currentSettingsState == SettingsState.Layers) {
                    view.removeGestureRecognizer(swipeUp)
                    view.removeGestureRecognizer(swipeDown)
                } else if(currentSettingsState == SettingsState.SavedLocation) {
                    view.removeGestureRecognizer(swipeUp)
                } else if(currentSettingsState == SettingsState.Speech) {
                    speech.saveCurrentSettings()
                }
                speech.stopSpeech(true)
                speech.speak(getTextKey("Transition_StartToSett"));
                changeSubStateSettings(SettingsState.Speech, first: true)
            }
        case State.Layers:
            if(currentLayerStateEntered == -1) {
                currentLayerStateEntered = speech.getCurrentIndex()
                speech.stopSpeech(true)
                let allPOI = getAllPointsForOneLayer(currentLayerStateEntered)
                speech.speakArray(allPOI)
                
            } else {
                speech.speak(getTextKey("Transition_DiscToLaye"));
                speech.speakOrderedDictionary(layersActive,start: currentLayerStateEntered)
                currentLayerStateEntered = -1
            }
        case State.Help:
            if(!currentHelpStateEntered) {
                speech.stopSpeech()
                currentHelpStateEntered = true
                if(currentHelpState == HelpState.CurrentState) {
                    var helpArray = [String]()
                    helpArray.append(getTextKey(("Help_State_" + lastState.name())))
                    speech.speakArray(helpArray)
                } else if(currentHelpState == HelpState.Global) {
                    var helpArray = [String]()
                    helpArray.append(getTextKey("Help_Global_General"))
                    helpArray.append(getTextKey("Help_Global_Gestures"))
                    speech.speakArray(helpArray)
                }
            } else {
                currentHelpStateEntered = false
                speech.stopSpeech(true)
                speech.speak(getTextKey("Transition_toHelp"));
                changeSubStateHelp(HelpState.CurrentState, first: true)
            }
        case State.CustomLocation:
            if(currentLocationStateEntered == -1) {
                if(mapObject.savedLocationsCurrentMap.count > 0) {
                    currentLocationStateEntered = speech.getCurrentIndex()
                    speech.stopSpeech(true)
                    
                    let point = mapObject.savedLocationsCurrentMap[currentLocationStateEntered]
                    self.speech.speakArray(point.getInfosAsArray(self))

                }
            } else {
                //TODO? speech.speak(getTextKey("Transition_DiscToLaye"));
                let array = mapObject.getSavedLocationAsSingleStrings(true)
                speech.stopSpeech(true)
                if(currentLocationStateEntered < array.count) {
                    speech.speakArray(array, atIndex: currentLocationStateEntered)
                } else {
                    speech.speakArray(array)
                }
                
                currentLocationStateEntered = -1
            }
        default:
            puts("Geste 'Double Tap' erkannt")
        }
    }
    
    /*********************************************************************
     * GESTURE RECOGNIZER - FourFingers DoubleTap
     *********************************************************************/
    func handleFourFingersDoubleTap() {
        speech.speak(self.getTextKey("div_currentState") + getTextKey("State_" + currentState.name()))
    }
    
    /*********************************************************************
     * GESTURE RECOGNIZER - FourFingers DrippleTap
     *********************************************************************/
    func handleFourFingersDrippleTap() {
        speech.speak(getTextKey("Help_State_" + currentState.name()))
    }
    
    /*********************************************************************
     * GESTURE RECOGNIZER - Swipe Left
     *********************************************************************/
    func handleSwipeLeft(gesture: UISwipeGestureRecognizer) {
        switch(currentState) {
        case State.Settings:
            if(!currentSettingsStateEntered) {
                let newState = currentSettingsState.next()
                currentSettingsState = newState
                speech.speak(getTextKey("State_Settings_" + currentSettingsState.name()))
            } else if(currentSettingsState == SettingsState.Layers) {
                speech.speakPrevOfOrderedDict(layersAll, interrupt: true)
            } else if(currentSettingsState == SettingsState.SavedLocation) {
                speech.cancelToNext(Action.Backward)
            } else if(currentSettingsState == SettingsState.Speech) {
                if(speech.getCurrentSpeechRate() > 50) {
                    speech.decreaseSpeechRate(0.1)
                    speech.speak("\(speech.getCurrentSpeechRate())%")
                } else {
                    speech.playSound(speech.soundEnd)
                }
            }
        case State.Location:
            speech.cancelToNext(Action.Backward)
        case State.Help:
            if(!currentHelpStateEntered) {
                let newState = currentHelpState.next()
                currentHelpState = newState
                speech.speak(getTextKey("State_Help_" + currentHelpState.name()))
            } else if(currentHelpState == HelpState.Global) {
                speech.cancelToNext(Action.Backward)
            }
        case State.Layers:
            if(currentLayerStateEntered == -1) {
                speech.speakPrevOfOrderedDict(layersActive, interrupt: true)
            } else {
                speech.cancelToNext(Action.Backward)
            }
            //speech.speakPrev(true,textkey: true)
            //speech.speak(getTextKey("Gesture_gesture") + getTextKey("Gesture_swipeLeft") + getTextKey("Gesture_recognized"))
        case State.CustomLocation:
            speech.cancelToNext(Action.Backward)
            //speech.speak(getTextKey("Gesture_gesture") + getTextKey("Gesture_swipeLeft") + getTextKey("Gesture_recognized"))
        default:
            puts("Geste 'Wischen Links' erkannt")
        }
    }
    
    /*********************************************************************
     * GESTURE RECOGNIZER - Swipe Right
     *********************************************************************/
    func handleSwipeRight(gesture: UISwipeGestureRecognizer) {
        switch(currentState) {
        case State.Settings:
            if(!currentSettingsStateEntered) {
                let newState = currentSettingsState.prev()
                currentSettingsState = newState
                speech.speak(getTextKey("State_Settings_" + currentSettingsState.name()))
            } else if(currentSettingsState == SettingsState.Layers) {
                speech.speakNextOfOrderedDict(layersAll, interrupt: true)
            } else if(currentSettingsState == SettingsState.SavedLocation) {
                speech.cancelToNext(Action.Forward)
            } else if(currentSettingsState == SettingsState.Speech) {
                if(speech.getCurrentSpeechRate() < 150) {
                    speech.increaseSpeechRate(0.1)
                    speech.speak("\(speech.getCurrentSpeechRate())%")
                } else {
                    speech.playSound(speech.soundEnd)
                }
            }
        case State.Location:
            speech.cancelToNext(Action.Forward)
        case State.Layers:
            if(currentLayerStateEntered == -1) {
                speech.speakNextOfOrderedDict(layersActive, interrupt: true)
            } else {
                speech.cancelToNext(Action.Forward)
            }
        case State.Help:
            if(!currentHelpStateEntered) {
                let newState = currentHelpState.prev()
                currentHelpState = newState
                speech.speak(getTextKey("State_Help_" + currentHelpState.name()))
            } else if(currentHelpState == HelpState.Global) {
                speech.cancelToNext(Action.Forward)
            }
        case State.CustomLocation:
            speech.cancelToNext(Action.Forward)
            //speech.speak(getTextKey("Gesture_gesture") + getTextKey("Gesture_swipeRight") + getTextKey("Gesture_recognized"))
        default:
            puts("Geste 'Wischen Rechts' erkannt")
        }
    }
    
    /*********************************************************************
    * GESTURE RECOGNIZER - Swipe Down
    *********************************************************************/
    func handleSwipeDown(gesture: UISwipeGestureRecognizer) {
        switch(currentState) {
        case State.Settings:
            if(currentSettingsStateEntered && currentSettingsState == SettingsState.Layers) {
                deactivateLayer()
            } else {
                speech.speak(getTextKey("Gesture_gesture") + getTextKey("Gesture_swipeDown") + getTextKey("Gesture_recognized"))
            }
        case State.Location:
            if(activeLocation != nil) { mapObject.saveLocation(activeLocation) }
            speech.speak(getTextKey("State_Location") + getTextKey("div_saved"))
        case State.Layers:
            deactivateLayer()
        case State.CustomLocation:
            speech.speak(getTextKey("Transition_CustToDisc"))
            changeState(State.Discover)
        default:
            puts("Geste 'Wischen Runter' erkannt")
        }
    }
    
    /*********************************************************************
     * GESTURE RECOGNIZER - Swipe Up
     *********************************************************************/
    func handleSwipeUp(gesture: UISwipeGestureRecognizer) {
        switch(currentState) {
        case State.Discover:
            //speech.speak(getTextKey("Transition_DiscToCust"))
            changeState(State.CustomLocation)
        case State.Settings:
            if(currentSettingsStateEntered && currentSettingsState == SettingsState.Layers) {
                activateLayer()
            } else if(currentSettingsState == SettingsState.SavedLocation) {
                let currentIndex = speech.getCurrentIndex()
                mapObject.deleteLocation(currentIndex,mapspecific: false)
                speech.stopSpeech(true)
                speech.speak(getTextKey("State_Location") + getTextKey("div_deleted"))
                let array = mapObject.getSavedLocationAsSingleStrings(false)
                if(currentIndex < array.count) {
                  speech.speakArray(array, atIndex: currentIndex)
                } else {
                    speech.speakArray(array)
                }
            }
        case State.CustomLocation:
            if(currentLocationStateEntered == -1) {
                speech.stopSpeech(true)
                speech.speakArray(mapObject.getSavedLocationAsSingleStrings(true))
                //speech.speak(getTextKey("Gesture_gesture") + getTextKey("Gesture_swipeUp") + getTextKey("Gesture_recognized"))
            } else {
                mapObject.deleteLocation(currentLocationStateEntered, mapspecific: true)
                speech.stopSpeech(true)
                speech.speak(getTextKey("div_deleted"))
                handleDoubleTap()
            }
        case State.Layers:
            activateLayer()
        default:
            puts("Geste 'Wischen Vor' erkannt")
        }
    }
    
    /*********************************************************************
     * GESTURE RECOGNIZER - Pinch
     *********************************************************************/
    func handlePinch(gesture: UIPinchGestureRecognizer) {
        if(gesture.scale > 2.0) {
            if(gesture.state == UIGestureRecognizerState.Ended)
            {
                switch(currentState) {
                    case State.Start:
                        speech.speak(getTextKey("Transition_StartToSett"));
                        changeState(State.Settings)
                    case State.Discover:
                        speech.speak(getTextKey("Transition_DiscToLaye"));
                        changeState(State.Layers)
                    default:
                        puts("Geste 'Pinch Open' erkannt")
                }
            }
        }
        
        if(gesture.scale < 0.5) {
            if(gesture.state == UIGestureRecognizerState.Ended)
            {
                switch(currentState) {
                case State.Settings:
                    if(currentSettingsStateEntered) {
                        handleDoubleTap()
                    } else {
                        speech.stopSpeech()
                        speech.speak(getTextKey("Transition_SettToStart"));
                        changeState(lastState)
                        //changeState(State.Start)
                        currentSettingsStateEntered = false
                    }
                case State.Help:
                    currentHelpStateEntered = false
                    speech.speak(getTextKey("Transition_fromHelp"));
                    changeState(lastState)
                case State.Layers:
                    if(currentLayerStateEntered == -1) {
                        speech.speak(getTextKey("Transition_LayeToDisc"));
                        changeState(State.Discover)
                    } else {
                        handleDoubleTap()
                    }
                case State.CustomLocation:
                    if(currentLocationStateEntered == -1) {
                        speech.speak(getTextKey("Transition_CustToDisc"))
                        changeState(State.Discover)
                    } else {
                        handleDoubleTap()
                    }
                default:
                    puts("Geste 'Pinch Close' erkannt")
                }
            }
        }
    }
    
    /*********************************************************************
     * GESTURE RECOGNIZER - Rotation
     *********************************************************************/
    func handleRotation(gesture: UIRotationGestureRecognizer) {

        if(gesture.state == UIGestureRecognizerState.Began)
        {
            if(gesture.rotation > 0.25 && gesture.rotation < 1.9) {
                speech.speak(getTextKey("Rotation_Help"));
                lastRotation = "Help"
            }
            if(gesture.rotation < -0.25 && gesture.rotation > -1.9) {
                speech.speak(getTextKey("Rotation_Settings"));
                lastRotation = "Settings"
            }
            if(gesture.rotation < 0.25 && gesture.rotation > -0.25 && lastRotation != "Back") {
                speech.speak(getTextKey("Rotation_Back"));
                lastRotation = "Back"
            }
        }
        
        if(gesture.state == UIGestureRecognizerState.Changed)
        {
            if(gesture.rotation > 0.25 && gesture.rotation < 1.9 && lastRotation != "Help") {
                speech.speak(getTextKey("Rotation_Help"));
                lastRotation = "Help"
            }
            if(gesture.rotation < -0.25 && gesture.rotation > -1.9 && lastRotation != "Settings") {
                speech.speak(getTextKey("Rotation_Settings"));
                lastRotation = "Settings"
            }
            if(gesture.rotation < 0.25 && gesture.rotation > -0.25 && lastRotation != "Back") {
                speech.speak(getTextKey("Rotation_Back"));
                lastRotation = "Back"
            }
        }
        
        if(gesture.state == UIGestureRecognizerState.Ended)
        {
            if(gesture.rotation > 0.25 && gesture.rotation < 1.9) {
                changeState(State.Help)
            }
            if(gesture.rotation < -0.25 && gesture.rotation > -1.9) {
                changeState(State.Settings)
            }
            lastRotation = ""
        }
    }
    
    /*********************************************************************
     * GESTURE RECOGNIZER - Pan
     *********************************************************************/
    func handlePan(gesture: UIPanGestureRecognizer) {
        if(gesture.state == UIGestureRecognizerState.Ended)
        {
            switch(currentState) {
            case State.Settings:
                speech.speak(getTextKey("Gesture_gesture") + getTextKey("Gesture_drag") + getTextKey("Gesture_recognized"))
            case State.Location:
                speech.speak(getTextKey("Gesture_gesture") + getTextKey("Gesture_drag") + getTextKey("Gesture_recognized"))
            case State.Layers:
                speech.speak(getTextKey("Gesture_gesture") + getTextKey("Gesture_drag") + getTextKey("Gesture_recognized"))
            default:
                puts("Geste 'Drag' erkannt")
            }
        }
    }
    
    /********************************************************************
     * GESTURE RECOGNIZER - ONE Touch (Menü Hilfe)
     *********************************************************************/
    /*
    func handleTapAndHold(gesture: UILongPressGestureRecognizer) {
        
        if(gesture.state == UIGestureRecognizerState.Began)
        {
            // Gesture: Tap & Hold
            speech.speak(getTextKey("Transition_toHelp"))
            changeState(State.Help)
        } else if(gesture.state == UIGestureRecognizerState.Cancelled || gesture.state == UIGestureRecognizerState.Ended)
        {
            // Gesture: Hands off
            speech.speak(getTextKey("Transition_fromHelp"))
            changeState(State.Start)
        }
    }*/
    
    /********************************************************************
    *********************************************************************
    * ONLINE STORAGE FUNCTIONS
    *********************************************************************
    *********************************************************************/
    func getAllLayers() {
        var allLayers = [PFObject]()
        
        do {
            let query = PFQuery(className: "Layers")
            query.whereKey("active", equalTo: true)
            query.orderByAscending("defaultOrder")
            allLayers = try query.findObjects()
            
            for obj in allLayers {
                let layername = obj["key"] as! String
                layersAll[layername] = true
                layersActive[layername] = true
            }
        } catch _ {
            puts("Error: getAllLayers()")
        }
    }
    
    func getAllPointsForOneLayer(idx :Int) -> [String] {
        
        var mapData = [PFObject]()
        var output = [String]()
        
        do {
            let ne = PFGeoPoint(latitude:mapObject.points[1].lat, longitude:mapObject.points[1].lng)
            let sw = PFGeoPoint(latitude:mapObject.points[2].lat, longitude:mapObject.points[2].lng)
            
            let currentIndex = idx
            let key = layersActive.keys[currentIndex]
            //puts("\(key)")
            
            let innerQuery = PFQuery(className: "Layers")
            innerQuery.whereKey("key", equalTo: key)
            
            let query = PFQuery(className: "MapData")
            query.whereKey("layer", matchesQuery: innerQuery)
            query.whereKey("active", equalTo: true)
            query.whereKey("location", withinGeoBoxFromSouthwest:sw, toNortheast:ne)
            
            mapData = try query.findObjects()
            
            for obj in mapData {
                let geoPoint = obj["location"] as! PFGeoPoint
                
                let point = GeoPoint(lat: geoPoint.latitude, lng: geoPoint.longitude)
                point.information[key] = (obj["message"] as! String)
                
                output.append(obj["message"] as! String)
                //puts("\(point.format())")
            }
        } catch _ {
            puts("Error: getAllLayers()")
        }
        
        return output
    }
    
    func deactivateLayer() {
        var currentIndex = (speech.nextSpeechIndex - 1)
        if(currentIndex < 0 ) { currentIndex = 0 }
        
        if(currentState == State.Settings) {
            layersAll[currentIndex] = false
            if(layersActive.keys.contains(layersAll.keys[currentIndex])) {
                let idxToDelete = layersActive.keys.indexOf(layersAll.keys[currentIndex])
                //puts(layersActive.description)
                //puts("index to delete: \(idxToDelete)")
                layersActive.keys.removeAtIndex(idxToDelete!)
                layersActive.values.removeValueForKey(layersAll.keys[currentIndex])
                puts(layersActive.description)
            }
            speech.speakWithoutDestroyingAnything(getTextKey("State_Layers_Singular") + getTextKey(layersAll.keys[currentIndex]) + getTextKey("div_deactivated"))
        } else {
            layersActive[currentIndex] = false
            speech.speakWithoutDestroyingAnything(getTextKey("State_Layers_Singular") + getTextKey(layersActive.keys[currentIndex]) + getTextKey("div_deactivated"))
        }
    }
    
    func activateLayer() {
        var currentIndex = (speech.nextSpeechIndex - 1)
        if(currentIndex < 0 ) { currentIndex = 0 }
        
        if(currentState == State.Settings) {
            layersAll[currentIndex] = true
            speech.speakWithoutDestroyingAnything(getTextKey("State_Layers_Singular") + getTextKey(layersAll.keys[currentIndex]) + getTextKey("div_activated"))
            layersActive[layersAll.keys[currentIndex]] = true
            puts(layersActive.description)
        } else {
            layersActive[currentIndex] = true
            speech.speakWithoutDestroyingAnything(getTextKey("State_Layers_Singular") + getTextKey(layersActive.keys[currentIndex]) + getTextKey("div_activated"))
        }
        
    }
    
    // Delegates for Location Modus
    func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didFinishSpeechUtterance utterance: AVSpeechUtterance) {
        if(speech.dataIsArray == false || currentState != State.Location && currentSettingsState != SettingsState.SavedLocation && currentState != State.CustomLocation && currentHelpState != HelpState.Global && currentLayerStateEntered == -1 || !speech.speakMultipleValues) {
            puts("return1")
            return
        }
        if(speech.lastAction == Action.Backward) {
            speech.speakPrev(false)
            //puts("prev")
        } else {
            speech.speakNext(false)
            //puts("next")
        }
        
        speech.lastAction = Action.Nothing
    }
    
    func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didCancelSpeechUtterance utterance: AVSpeechUtterance) {
        if(speech.dataIsArray == false || currentState != State.Location && currentSettingsState != SettingsState.SavedLocation && currentState != State.CustomLocation && currentHelpState != HelpState.Global && currentLayerStateEntered == -1 || !speech.speakMultipleValues) {
            puts("return2")
            return
        }
        puts("\(speech.getCurrentIndex())")
        //speech.speakNext(false)
        
        
        if(speech.lastAction == Action.Backward) { // && speech.getCurrentIndex() > 0
            speech.speakPrev(false)
            speech.lastAction = Action.Nothing
            //puts("prev")
        } else {
            speech.speakNext(false)
            //puts("next")
        }
    }

}