
import UIKit

import MapKit
import CoreLocation

var catName=""
extension ViewController: CLLocationManagerDelegate{
  func locationManager(_ manager:CLLocationManager, didUpdateLocations locations:[CLLocation]){
    if  places.count != 0{
        places.removeAll()
    }
    if  locations.count > 0{/* Every time the LocationManager updates the location, it sends this message to its delegate, giving it the updated locations. The locations array contains all locations in chronological order, so the newest location is the last object in the array. First you check if there are any locations in the array and if there is at least one you take the newest. The next line gets the horizontal accuracy and logs it to the console. This value is a radius around the current location. If you have a value of 50, it means that the real location can be in a circle with a radius of 50 meters around the position stored in location. */
      let location = locations.last!
      print("Accuracy: \(location.horizontalAccuracy)")
      
      if location.horizontalAccuracy < 100 {/* The if statement checks if the accuracy is high enough for your purposes. 100 meters is good enough for this example and you don’t have to wait too long to achieve this accuracy. In a real app, you would probably want an accuracy of 10 meters or less, but in this case it could take a few minutes to achieve that accuracy (GPS tracking takes time). */
        
        manager.stopUpdatingLocation()
        let span = MKCoordinateSpan(latitudeDelta : 0.014, longitudeDelta : 0.014)
        let region = MKCoordinateRegion(center: location.coordinate, span:span)
        mapView.region = region
        /* The first line stops updating the location to save battery life. The next three lines zoom the mapView to the location. */
    
      //----------------------------------------------------------------------------------
        
        if !startedLoadingPOIs {/* --------
           This starts loading a list of POIs that are within a radius of 1000 meters of the
           user’s current position, and prints them to the console. */
          startedLoadingPOIs = true
          
          catName = categoryPickerTextField.text!
          let loader = PlacesLoader()
          loader.loadPOIS(location: location, radius: 500, categoryName:catName){placesDict, error in
          
            if let dict = placesDict{
              print(dict)
              guard let placesArray = dict.object(forKey: "results") as? [NSDictionary] else {return}/* The guard statement checks that the response has the expected format */
              
              for placeDict in placesArray{ /* This line iterates over the received POIs */
                //-----------------------------------------------------------------------
                /* These lines get the needed information from the dictionary. The response contains a lot more information that is not needed for this app. */
                let latitude = placeDict.value(forKeyPath:"geometry.location.lat") as! CLLocationDegrees
                let longitude = placeDict.value(forKeyPath:"geometry.location.lng") as! CLLocationDegrees
                let reference = placeDict.object(forKey: "reference") as! String
                let name = placeDict.object(forKey: "name") as! String
                let address = placeDict.object(forKey: "vicinity") as! String
                
                let location = CLLocation(latitude: latitude, longitude:longitude)
                //-----------------------------------------------------------------------
                
                let place = Place(location:location, reference:reference, name: name, address: address)/* With the extracted information a Place object is created and appended to the places array. */
                self.places.append(place)
                
                let annotation = PlaceAnnotation(location:place.location!.coordinate, title: place.placeName)/* This line creates a PlaceAnnotation that is used to show an annotation on the map view. */
                
                
                DispatchQueue.main.async {//execute in main thread
                  self.mapView.addAnnotation(annotation)
                }
              }
            }
          }
        }
      //----------------------------------------------------------------------------------
      }
    }
  }
}
// AnnotationView datasource and delegate
extension ViewController: ARDataSource {
  func ar(_ arViewController: ARViewController, viewForAnnotation: ARAnnotation) -> ARAnnotationView {
    let annotationView = AnnotationView()
    annotationView.annotation = viewForAnnotation
    annotationView.delegate = self
    annotationView.frame = CGRect(x: 0, y: 0, width: 150, height: 50)
    
    return annotationView
  }
}

extension ViewController: AnnotationViewDelegate {
  func didTouch(annotationView: AnnotationView) {
    
    if let annotation = annotationView.annotation as? Place{
      let placesLoader = PlacesLoader()
      placesLoader.loadDetailInformation(forPlace: annotation){resultDict, error in
      
        if let infoDict = resultDict?.object(forKey: "result") as? NSDictionary{
          annotation.phoneNumber = infoDict.object(forKey: "formatted_phone_number") as? String
          annotation.website = infoDict.object(forKey: "website") as? String
          
          self.showInfoView(forPlace: annotation)
        }
        
      }
    }
  }
}

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate{
  
    
  @IBOutlet var categoryPickerTextField: UITextField!
  var pickOption = ["airport", "amusement_park", "art_gallery","atm","bank","bar","cafe","casino","church","city_hall","embassy","establishment","gym","hospital","library","mosque","museum","park","pharmacy","police","post_office","restaurant","shopping_mall","stadium","synagogue","university","veterinary_care","zoo"]
  let pickerView = UIPickerView()
  
  @IBOutlet weak var mapView: MKMapView!
  
  fileprivate let locationManager = CLLocationManager()
  fileprivate var startedLoadingPOIs = false
  fileprivate var places = [Place]()
  fileprivate var arViewController: ARViewController!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    pickerView.delegate = self
    categoryPickerTextField.inputView = pickerView
    //------------------------------------------------------------------------------------
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    locationManager.startUpdatingLocation()
    locationManager.requestWhenInUseAuthorization()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func showARController(_ sender: Any) {
    arViewController = ARViewController()
    arViewController.dataSource = self
    arViewController.maxVisibleAnnotations = 30
    arViewController.headingSmoothingFactor = 0.05
    arViewController.trackingManager.userDistanceFilter = 25
    arViewController.trackingManager.reloadDistanceFilter = 50
    print(places)
    arViewController.setAnnotations(places)
    self.present(arViewController, animated: true, completion: nil)
  }
  
  func showInfoView(forPlace place:Place){
    let alert = UIAlertController(title: place.placeName , message: place.infoText, preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
    //2
    arViewController.present(alert, animated: true, completion: nil)
  }
  

  //-------------- PickerView Methods
  
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return pickOption.count
  }
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return pickOption[row]
  }
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    categoryPickerTextField.text = pickOption[row]
    self.startedLoadingPOIs = false
    let allAnnotations = self.mapView.annotations
    self.mapView.removeAnnotations(allAnnotations)
    locationManager.startUpdatingLocation()
    locationManager.requestWhenInUseAuthorization()
    self.view.endEditing(true)
  }
 }

