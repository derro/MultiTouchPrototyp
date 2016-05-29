//
//  Map.swift
//  DA_ipad_Prototyp_v02
//
//  Created by Roland Prinz on 05.01.16.
//
//

import Foundation
import Parse

class Map {
    //Debug?
    var debug = true
    
    //Properties
    var name :String
    var id :String
    var points = [GeoPoint]()
    var width :Double
    var height :Double
    var layers = [String]()
    var info :String
    var savedLocations = [GeoPoint]()
    var savedLocationsCurrentMap = [GeoPoint]()
    var view: DiscoverViewController!
    
    //Constants
    let maxPixelX = 1366.0
    let maxPixelY = 1024.0
    
    let mapSegmentSizeX = 19
    let mapSegmentSizeY = 13
    var mapSegmentWidth = 0
    var mapSegmentHeight = 0
    
    init() {
        self.name = "none"
        self.id = ""
        self.width = 0.0
        self.height = 0.0
        self.info = ""
        mapSegmentWidth = Int(maxPixelX) / mapSegmentSizeX
        mapSegmentHeight = Int(maxPixelY) / mapSegmentSizeY
    }
    
    func format() -> String {
        var output = "Name: \(name),\n Size: \(width) * \(height), \n points:[\n   "
        for point in points {
            output.appendContentsOf(point.format())
            output.appendContentsOf("\n   ")
        }
        output.appendContentsOf("], Layers: ")
        for layer in layers {
            output.appendContentsOf(layer)
            output.appendContentsOf(" ")
        }
        
        return output
    }
    
    func calculateGeoPoint(touchX :Double, touchY :Double) -> GeoPoint {
        let posX = touchX / maxPixelX * width
        let posY = touchY / maxPixelY * height
        
        if(debug) { puts("posx: \(posX), posY \(posY), touchX: \(touchX), touchY: \(touchY)") }
        
        let point = GeoPoint(lat: (points[0].lat - posY),lng: (points[0].lng + posX))
        point.segmentx = (Int(touchX) / mapSegmentWidth) + 1
        point.segmenty = (Int(touchY) / mapSegmentHeight) + 1
        
        if(debug) { puts("point: \(point.format())") }
        
        return point
    }
    
    func setMap(map: String) {
        if(map == "none") {
            info = ""
            name = "none"
            id = ""
            points.removeAll()
            height = 0.0
            width = 0.0
            savedLocationsCurrentMap.removeAll()
        } else {
            getMapInfoFromDatabase(map)
            savedLocationsCurrentMap.removeAll()
            
            // Berechne die Distanz -> Breite
            var xd = points[1].lat - points[0].lat
            var yd = points[1].lng - points[0].lng
            self.width = sqrt(xd*xd + yd*yd)
            
            // Berechne die Distanz -> Höhe
            xd = points[2].lat - points[0].lat
            yd = points[2].lng - points[0].lng
            self.height = sqrt(xd*xd + yd*yd)
        }
    }
    
    // Save GeoPoint with all information on the active layers -> non active ones get deleted
    func saveLocation(point :GeoPoint) {
        for key in view.layersActive.keys {
            let layer = view.layersActive[key]
            
            if(point.information.keys.contains(key)) {
                if(layer == false) {
                    point.information.removeValueForKey(key)
                }
            }

        }
        if(debug) { puts("Location saved for GeoPoint: \(point.format())")}
        savedLocations.append(point)
        savedLocationsCurrentMap.append(point)
    }
    
    func getSavedLocationAsSingleStrings(mapspecific: Bool) -> [String] {
        var allStrings = [String]()
        var i = 1;
        
        if(mapspecific) {
            for point in savedLocationsCurrentMap {
                allStrings.append(/*view.getTextKey("State_Location") + "\(i)" + "-" + */getMapSegmentLocationAsString(point) + ":\n" + point.getInfosAsString(view) + "." )
                i += 1
            }
        }
        else {
            for point in savedLocations {
                allStrings.append(/*view.getTextKey("State_Location") + "\(i)" + "-" + */getMapSegmentLocationAsString(point) + ":\n" + point.getInfosAsString(view) + "." )
                i += 1
            }
        }
        
        return allStrings
    }
    
    func getMapSegmentLocationAsString(point: GeoPoint) -> String {
        var output = view.getTextKey("div_location_segment")
        let u = UnicodeScalar(point.segmentx + 64)
        let char = Character(u)
        output.appendContentsOf("\(char)/\(point.segmenty)")
        return output
    }
    
    func deleteLocation(index :Int, mapspecific: Bool) {
        if(mapspecific) {
            let pointId = savedLocationsCurrentMap[index].id
            savedLocationsCurrentMap.removeAtIndex(index)
            for (i,point) in savedLocations.enumerate() {
                if(point.id == pointId) {
                    savedLocations.removeAtIndex(i)
                    puts("found true")
                    break
                }
            }
        } else {
            let pointId = savedLocations[index].id
            savedLocations.removeAtIndex(index)
            for (i,point) in savedLocationsCurrentMap.enumerate() {
                if(point.id == pointId) {
                    savedLocationsCurrentMap.removeAtIndex(i)
                    puts("found false")
                    break
                }
            }
        }
    }
    
    func getMapSegmentOnMap(point: GeoPoint) {
        let lat = points[0].lat - point.lat
        let lng = point.lat - points[0].lng
        
        puts("lat: \(lat), lng: \(lng)")
    }
    
    /*********************************************************************
    * ONLINE STORAGE FUNCTIONS
    *********************************************************************/
    func getMapInfoFromDatabase(map: String) {
        do {
            let query = PFQuery(className: "Map")
            query.whereKey("name", equalTo: map)
            let mapArray = try query.findObjects()
            
            self.id = mapArray[0].objectId!
            self.name = map
            self.info = mapArray[0]["info"] as! String
            
            let mapPoints = mapArray[0]["coordinates"] as! [PFGeoPoint]
            for point in mapPoints {
                let point = GeoPoint(lat: point.latitude, lng: point.longitude)
                if(debug) { puts(point.format()) }
                points.append(point)
                
            }
            if(debug) { puts("MapSize: \(points.count)") }
        } catch _ {
            puts("Error: getMapInfoFromDatabase(\(map))")
        }
    }
}