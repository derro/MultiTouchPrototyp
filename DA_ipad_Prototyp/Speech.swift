//
//  Speech.swift
//  DA_ipad_Prototyp_v02
//
//  Created by Roland Prinz on 07.01.16.
//
//

import UIKit
import Foundation
import AVFoundation
import AudioToolbox

class Speech {
    
    //Objects
    let speechSynthesizer = AVSpeechSynthesizer()
    var view: DiscoverViewController!
    
    //Settings
    var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate          // 0.0 to 1.0, default is AVSpeechUtteranceDefaultSpeechRate constant.
    var speechPitchMultiplier: Float = 1.0                              // 0.5 and 2.0, default is 1.0
    var speechVolume: Float = 1.0                                       // 0.0 to 1.0, and by default it’s set to 1.0.
    
    var nextSpeechIndex = 0
    var speechArray = [String]()
    //var speechOrderedDict = OrderedDictionary<String,Bool>()
    var dataIsOrderedDict = false
    var dataIsArray = false
    var speakMultipleValues = false
    
    let soundEndSegment = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("EndSegment", ofType: "mp3")!)
    let soundEnd = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("End", ofType: "mp3")!)
    
    var lastAction :Action = Action.Nothing
    let debug = true
    
    //Init Functions
    init() {
        if !loadSettings() {
            registerDefaultSettings()
        }
    }
    
    func loadSettings() -> Bool {
        let userDefaults = NSUserDefaults.standardUserDefaults() as NSUserDefaults
        
        if let theRate: Float = userDefaults.valueForKey("rate") as? Float {
            speechRate = theRate
            speechPitchMultiplier = userDefaults.valueForKey("pitch") as! Float
            speechVolume = userDefaults.valueForKey("volume") as! Float
            return true
        }
        return false
    }

    func registerDefaultSettings() {
        speechRate = AVSpeechUtteranceDefaultSpeechRate
        speechPitchMultiplier = 1.0
        speechVolume = 1.0
        
        NSUserDefaults.standardUserDefaults().setObject(speechRate, forKey: "rate")
        NSUserDefaults.standardUserDefaults().setObject(speechPitchMultiplier, forKey: "pitch")
        NSUserDefaults.standardUserDefaults().setObject(speechVolume, forKey: "volume")
    }
    
    func saveCurrentSettings() {
        NSUserDefaults.standardUserDefaults().setObject(speechRate, forKey: "rate")
        NSUserDefaults.standardUserDefaults().setObject(speechPitchMultiplier, forKey: "pitch")
        NSUserDefaults.standardUserDefaults().setObject(speechVolume, forKey: "volume")
    }
    
    //Controller Functions
    func pauseSpeech() {
        speechSynthesizer.pauseSpeakingAtBoundary(AVSpeechBoundary.Word)
    }
    
    func stopSpeech() {
        stopSpeech(true)
    }
    
    func stopSpeech(reset :Bool) {
        speechSynthesizer.stopSpeakingAtBoundary(AVSpeechBoundary.Immediate)
        if(reset) {
            nextSpeechIndex = 0
            dataIsArray = false
            dataIsOrderedDict = false
            //speechOrderedDict.values.removeAll()
            speakMultipleValues = false
            speechArray.removeAll()
        }
    }
    
    func speak(text: String) {
        speak(text, interrupt: true);
    }
    
    func speak(text: String, interrupt: Bool) {
        if(interrupt) {
            stopSpeech()
        }
        
        let speechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.rate = speechRate
        speechUtterance.pitchMultiplier = speechPitchMultiplier
        speechUtterance.volume = speechVolume
        speechUtterance.voice = AVSpeechSynthesisVoice.init(language: "de-AT")
        view.speakText.text = text
        speechSynthesizer.speakUtterance(speechUtterance)
    }
    
    func speakArray(texts :[String]) {
        speakArray(texts,textkey: false, atIndex: 0)
    }
    
    func speakArray(texts :[String], atIndex :Int) {
        speakArray(texts,textkey: false, atIndex: atIndex)
    }
    
    func speakArray(texts :[String],textkey: Bool, atIndex :Int) {
        nextSpeechIndex = atIndex
        dataIsArray = true
        speechArray = texts
        speakNext(false,textkey: textkey)
    }
    
    func cancelToNext(action :Action) {
        
        if(dataIsArray == false) {
            return
        }
        lastAction = action
        if(action == Action.Forward) {
            if(self.nextSpeechIndex >= speechArray.count) {
                playSound(soundEnd)
            }
        }
        if(action == Action.Backward) {
            if(self.nextSpeechIndex == 0) {
                playSound(soundEnd)
            }
            
            if(!speechSynthesizer.speaking) {
                speakPrev(false)
                lastAction = Action.Nothing
            }
        }
        
        stopSpeech(false)
    }

    func speakNext(interrupt: Bool) {
        speakNext(interrupt,textkey: false)
    }
    
    func speakNext(interrupt: Bool, textkey :Bool) {
        if(debug) { puts("NEXT: index: \(nextSpeechIndex)") }
        if(self.nextSpeechIndex < speechArray.count) {
            if(interrupt) {
                stopSpeech(false)
            }
            playSound(soundEndSegment)
            var text = speechArray[nextSpeechIndex]
            
            if(textkey) {
                text = self.view.getTextKey(text)
            }

            speak(text,interrupt: false)
            speakMultipleValues = true
            nextSpeechIndex += 1
        } else {
            if(dataIsArray) {
                playSound(soundEnd)
            }
        }
    }
    
    func speakPrev(interrupt: Bool) {
        speakPrev(interrupt, textkey: false)
    }
    
    func speakPrev(interrupt: Bool, textkey :Bool) {
        var play = true
        if(nextSpeechIndex > 0) {
            nextSpeechIndex -= 1
        }
        // If not the first element - decrease another one
        if(nextSpeechIndex > 0) {
            nextSpeechIndex -= 1
        } else {
            playSound(soundEnd)
            play = false
        }
        if(debug) { puts("PREV: index: \(nextSpeechIndex)") }
        if(self.nextSpeechIndex < speechArray.count) {
            if(interrupt) {
                stopSpeech(false)
            }
            if(play) { playSound(soundEndSegment) }
            var text = speechArray[nextSpeechIndex]
         
            if(textkey) {
                text = self.view.getTextKey(text)
            }
            
            speak(text,interrupt: false)
            speakMultipleValues = true
            nextSpeechIndex += 1
        } else {
            if(dataIsArray) {
                playSound(soundEnd)
            }
        }
    }
    
    // Speak Ordered Dict Methods
    
    func speakOrderedDictionary(od :OrderedDictionary<String,Bool>) {
        speakOrderedDictionary(od, start: 0)
    }
    
    func speakOrderedDictionary(od :OrderedDictionary<String,Bool>, start :Int) {
        nextSpeechIndex = start
        dataIsOrderedDict = true
        //speechOrderedDict = od
        speakNextOfOrderedDict(od, interrupt: false)
    }
    
    func speakNextOfOrderedDict(od :OrderedDictionary<String,Bool>, interrupt: Bool) {
        if(debug) { puts("NEXT-OD: index: \(nextSpeechIndex), od-count: \(od.count)") }
        if(self.nextSpeechIndex < od.count) {
            if(interrupt) {
                stopSpeech(false)
            }
            playSound(soundEndSegment)
            let key = od.keys[nextSpeechIndex]
            let active = od.values[key]
            var text = self.view.getTextKey(key) + ": "
            if(active == true) {
                text.appendContentsOf(self.view.getTextKey("div_active"))
            } else {
                text.appendContentsOf(self.view.getTextKey("div_deactive"))
            }
            
            speak(text,interrupt: false)
            speakMultipleValues = true
            nextSpeechIndex += 1
        } else {
            if(od.count == 0) {
                let text = self.view.getTextKey("div_noLayersActive")
                speak(text,interrupt: true)
            }
            if(dataIsOrderedDict) {
                playSound(soundEnd)
            }
        }
    }
    
    func speakPrevOfOrderedDict(od :OrderedDictionary<String,Bool>, interrupt: Bool) {
        var play = true
        if(nextSpeechIndex > 0) {
            nextSpeechIndex -= 1
        }
        // If not the first element - decrease another one
        if(nextSpeechIndex > 0) {
            nextSpeechIndex -= 1
        } else {
            playSound(soundEnd)
            play = false
        }

        if(debug) { puts("NEXT-OD: index: \(nextSpeechIndex), od-count: \(od.count)") }
        if(self.nextSpeechIndex < od.count) {
            if(interrupt) {
                stopSpeech(false)
            }
            if(play) { playSound(soundEndSegment) }
            let key = od.keys[nextSpeechIndex]
            let active = od.values[key]
            var text = self.view.getTextKey(key) + ": "
            if(active == true) {
                text.appendContentsOf(self.view.getTextKey("div_active"))
            } else {
                text.appendContentsOf(self.view.getTextKey("div_deactive"))
            }
            
            speak(text,interrupt: false)
            speakMultipleValues = true
            nextSpeechIndex += 1
        } else {
            if(od.count == 0) {
                let text = self.view.getTextKey("div_noLayersActive")
                speak(text,interrupt: true)
            }
            if(dataIsOrderedDict) {
                playSound(soundEnd)
            }
        }
    }
    
    func speakWithoutDestroyingAnything(text :String) {
        stopSpeech(false)
        speak(text,interrupt: false)
    }
    
    func getCurrentIndex() -> Int {
        switch nextSpeechIndex {
        case 0..<2: return 0
        default: return (nextSpeechIndex-1)
        }
    }
    
    func getCurrentSpeechRate() -> Int {
        return Int(speechRate * 100 + 50)
    }
    
    func increaseSpeechRate(val :Float) -> Int {
        speechRate = speechRate + val
        return getCurrentSpeechRate()
    }

    func decreaseSpeechRate(val :Float) -> Int {
        speechRate = speechRate - val
        return getCurrentSpeechRate()
    }
    // Soundeffects
    
    func playSound(sound: NSURL) {
        do {
            view.audioPlayer = try AVAudioPlayer(contentsOfURL: sound)
            view.audioPlayer.prepareToPlay()
            view.audioPlayer.play()
        } catch _ {
            
        }
    }
    
    
    
}