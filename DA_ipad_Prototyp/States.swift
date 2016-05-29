//
//  States.swift
//  DA_ipad_Prototyp_v02
//
//  Created by Roland Prinz on 25.12.15.
//
//

import Foundation

enum Action : String
{
    case    Forward,
    Backward,
    Nothing
}

enum State : String
{
    case    Start = "Start",
            Help = "Help",
            Discover = "Discover",
            Settings = "Settings",
            Location = "Location",
            Layers = "Layers",
            CustomLocation = "CustomLocation",
            Distance = "Distance"    
    
    func name() -> String
    {
        return self.rawValue
    }
}

enum SettingsState : String
{
    case    Speech = "Speech"
    case    Layers = "Layers"
    case    SavedLocation = "SavedLocation"
    
    func name() -> String
    {
        return self.rawValue
    }
    
    func first() -> SettingsState {
        return SettingsState.Speech
    }
    
    func next() -> SettingsState {
        switch(self) {
        case SettingsState.Speech:
            return SettingsState.Layers
        case SettingsState.Layers:
            return SettingsState.SavedLocation
        case SettingsState.SavedLocation:
            return SettingsState.Speech
        }
    }
    
    func prev() -> SettingsState {
        switch(self) {
        case SettingsState.Speech:
            return SettingsState.SavedLocation
        case SettingsState.Layers:
            return SettingsState.Speech
        case SettingsState.SavedLocation:
            return SettingsState.Layers
        }
    }
}

enum HelpState : String
{
    case    CurrentState = "CurrentState"
    case    Global = "Global"
    
    func name() -> String
    {
        return self.rawValue
    }
    
    func first() -> HelpState {
        return HelpState.CurrentState
    }
    
    func next() -> HelpState {
        switch(self) {
        case HelpState.CurrentState:
            return HelpState.Global
        case HelpState.Global:
            return HelpState.CurrentState
        }
    }
    
    func prev() -> HelpState {
        switch(self) {
        case HelpState.CurrentState:
            return HelpState.Global
        case HelpState.Global:
            return HelpState.CurrentState
        }
    }
}
    