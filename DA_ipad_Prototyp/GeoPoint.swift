//
//  GeoPoint.swift
//  DA_ipad_Prototyp_v02
//
//  Created by Roland Prinz on 05.01.16.
//
//

import Foundation
import Parse

class GeoPoint {
    var lat :Double
    var lng :Double
    var information = [String: String]()
    var debug = true
    var segmentx = 0
    var segmenty = 0
    var id = 0.0    
    
    init(lat: Double, lng: Double) {
        self.lat = lat
        self.lng = lng
        id = NSDate().timeIntervalSince1970
    }
    
    // Textoutput of coordinates
    func format() -> String {
        var output = String(format: "Pos: \(segmentx)/\(segmenty), Lat: %.5f, Long: %.5f \n", self.lat, self.lng)
        for info in information {
            output.appendContentsOf("key:")
            output.appendContentsOf(info.0)
            output.appendContentsOf(", info:")
            output.appendContentsOf(info.1)
            output.appendContentsOf("\n")
        }
        return output
    }
    
    // Function to retrieve all information to this GeoPoint and store it in dictionary
    func retrieveAllInfos( completion: (result: String) -> Void) {
        getStreetName({ (streetname) in
            self.getPOI()
            completion(result: streetname)
        })
    }
    
    func getStreetName(completion: (result: String) -> Void) {
        let query = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(lat),\(lng)&location_type=ROOFTOP&result_type=street_address&key=<<APIKEY>>"
        if(debug){ puts("QUERY: \(query)") }
        
        guard let url = NSURL(string: query) else {
            print("Error - getStreetName(): cannot create URL")
            return
        }
        let urlRequest = NSURLRequest(URL: url)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest, completionHandler: { (data, response, error) in
            let json = JSON(data: data!)
            let streetname = "\(json["results"][0]["address_components"][1]["short_name"]) \(json["results"][0]["address_components"][0]["short_name"])"
            self.information["streetnames"] = streetname
            completion(result: streetname);
        })
        task.resume()
    }

    func getPOI() {
        do {
            let point = PFGeoPoint(latitude:self.lat, longitude:self.lng)
            let query = PFQuery(className:"MapData")
            query.includeKey("layer")
            query.whereKey("location", nearGeoPoint:point, withinKilometers:0.02)

            let allPOIs = try query.findObjects()
            for obj in allPOIs {
                if((obj["layer"]["active"]! as! Bool) == true) {
                    let key = (obj["layer"]["key"]! as! String)
                    if(information.keys.contains(key)){
                        puts("double")
                        let message = information[key]! + " . Des weiteren: " + (obj["message"] as! String)
                        information.updateValue(message, forKey: key)
                    }
                    else {
                        information[(obj["layer"]["key"]! as! String)] = (obj["message"] as! String)
                    }
                    
                
                }
            }
        } catch _ {
            puts("Error: getPOI()")
        }
    }
    
    func getDistanceToPoint(to: GeoPoint, completion: (result: String) -> Void) {
        let query = "https://maps.googleapis.com/maps/api/distancematrix/json?origins=\(lat),\(lng)&destinations=\(to.lat),\(to.lng)&mode=walking&language=de-DE&key=<<APIKEY>>"
        
        if(debug){ puts("QUERY: \(query)") }
        
        guard let url = NSURL(string: query) else {
            print("Error - getDistanceToPoint(): cannot create URL")
            return
        }
        let urlRequest = NSURLRequest(URL: url)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest, completionHandler: { (data, response, error) in
            let json = JSON(data: data!)
            let distance = json["rows"][0]["elements"][0]["distance"]["value"]
            //let duration = json["rows"][0]["elements"][0]["duration"]["text"]
            
            let all = "\(distance) Meter"
            //let all = "\(distance) \(duration)"
            
            completion(result: all);
        })
        task.resume()
    }
    
    func getInfosAsArray(view: DiscoverViewController) -> [String] {
        var array = [String]()
        for info in information {
            var output = ""
            output.appendContentsOf(view.getTextKey(info.0))
            output.appendContentsOf(": ")
            output.appendContentsOf(info.1)
            array.append(output)
            if(debug) { puts("\(output)") }
        }
        
        return array
    }
    
    func getInfosAsString(view: DiscoverViewController) -> String {
        var string = ""
        for info in information {
            string.appendContentsOf(view.getTextKey(info.0))
            string.appendContentsOf(": ")
            string.appendContentsOf(info.1)
            string.appendContentsOf("\n")
        }
        if(debug) { puts("\(string)") }

        return string

    }
    
    func getInfosAsArrayForActiveLayers(view: DiscoverViewController) -> [String] {
        var array = [String]()
        
        puts(view.layersActive.description)
        for key in view.layersActive.keys {
            let layer = view.layersActive[key]
            //puts("layer element 0 : \(layer) and key: \(key)")
            
            if(information.keys.contains(key)) {
                var output = ""
                let info = information[key]
                output.appendContentsOf(view.getTextKey(key))
                output.appendContentsOf(": ")
                output.appendContentsOf(info!)
                
                if(layer == true) {
                    array.append(output)
                    if(debug) { puts("visible: \(output)") }
                }
                else {
                    if(debug) { puts("not visible: \(output)") }
                }
            }
            else {
                if(debug) { puts("no data for key: \(key)") }
            }
        }
        return array
    }
}