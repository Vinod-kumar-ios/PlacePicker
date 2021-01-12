//
//  AddressTextField.swift
//
//  Created by Vinod Kumar on 04/01/21.
//

import UIKit
import GooglePlaces

class AddressTextField: UITextField {
    
    private var timer: Timer? = nil
    private var tableView : UITableView!
    private var arrPlaces:[GMSAutocompletePrediction] = []
    private var placesClient: GMSPlacesClient!
    private let token = GMSAutocompleteSessionToken.init()
    // Create a type filter.
    private let filter = GMSAutocompleteFilter()
    public typealias AddressTextFieldItemHandler = (_ filteredResult: GMSAutocompletePrediction) -> Void
    var itemSelectionHandler: AddressTextFieldItemHandler?
    private var strLastSearched = ""
    
    override func draw(_ rect: CGRect) {
        configureTableView()
        self.addTarget(self, action: #selector(AddressTextField.textFieldDidChange), for: .editingChanged)
        self.addTarget(self, action: #selector(AddressTextField.textFieldDidEndEditing), for: .editingDidEnd)
    }
    
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        resetTableView()
    }
    
    
    //MARK:-TableView Configuration
    func configureTableView() {
        let rect = CGRect.init(x: 0, y: 45, width: self.frame.width, height: 0)
        tableView = UITableView.init(frame: rect)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.black
        tableView.register(AddressTableViewCell.self, forCellReuseIdentifier: "AddressTableViewCell")
        
        placesClient = GMSPlacesClient.shared()
        filter.type = .region
        self.superview?.addSubview(tableView)
       
    }
    
    func resetTableView() {
        if tableView != nil{
             let y = (self.frame.origin.y+self.frame.height + 5)
            let rect = CGRect.init(x: self.frame.origin.x, y: y, width: self.frame.width, height: CGFloat((arrPlaces.count*30)))
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.tableView.frame = rect
            })
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func clearTableView() {
        if tableView != nil{
            arrPlaces.removeAll()
            let y = (self.frame.origin.y+self.frame.height + 5)
            let rect = CGRect.init(x: self.frame.origin.x, y: y, width: self.frame.width, height: CGFloat((arrPlaces.count*30)))
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.tableView.frame = rect
            })
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    //MARK:-Notifications
    @objc open func textFieldDidChange() {
    
        // Detect pauses while typing
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(AddressTextField.typingDidStop), userInfo: self, repeats: false)
    }
    
    
    
    @objc open func textFieldDidEndEditing() {
        clearTableView()
    }
    
    @objc open func typingDidStop() {
        strLastSearched = self.text ?? ""
        getPlacePredictions(strSearchText: self.text ?? "")
    }
    
    
}

extension AddressTextField:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrPlaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressTableViewCell", for: indexPath) as! AddressTableViewCell
        cell.selectionStyle = .none
        
        
        let attrStri = NSMutableAttributedString.init(attributedString: arrPlaces[indexPath.row].attributedPrimaryText)
        let nsRange = NSString(string: attrStri.string).range(of: attrStri.string)
        attrStri.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0) as Any], range: nsRange)
        
        let nsRange1 = NSString(string: attrStri.string).range(of: strLastSearched, options: String.CompareOptions.caseInsensitive)
        attrStri.addAttributes([NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14.0) as Any], range: nsRange1)

        cell.lblAddress.attributedText = attrStri
        cell.lblAddress.textColor = textColor
        cell.contentView.backgroundColor = UIColor.black
        cell.createDashedLine(from: CGPoint.init(x: 10, y:cell.bounds.maxY), to: CGPoint.init(x: (frame.width - 10), y: cell.bounds.maxY), color: .white, strokeLength: 5, gapLength: 4, width: 1)
        return cell
    }
    
    
}

extension AddressTextField:UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        itemSelectionHandler!(arrPlaces[indexPath.row])
        clearTableView()
        self.resignFirstResponder()
    }
}


//MARK:-API Calling
extension AddressTextField{
    
    func getPlacePredictions(strSearchText:String){
        
        placesClient?.findAutocompletePredictions(fromQuery: strSearchText,
                                                  bounds: nil,
                                                  boundsMode: GMSAutocompleteBoundsMode.bias,
                                                  filter: filter,
                                                  sessionToken: token,
                                                  callback: { (results, error) in
                                                    self.arrPlaces.removeAll()
                                                    if let error = error {
                                                        print("Autocomplete error: \(error)")
                                                        return
                                                    }
                                                    if let results = results {
                                                        self.arrPlaces.append(contentsOf: results)
                                                    }
                                                    self.resetTableView()
        })
    }
}


class AddressTableViewCell: UITableViewCell {

    let lblAddress = UILabel()
    var perDashLength: CGFloat = 2.0
    var spaceBetweenDash: CGFloat = 2.0
    var dashColor: UIColor = UIColor.white.withAlphaComponent(0.3)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        lblAddress.frame = CGRect.init(x: 10, y: 10, width: (self.frame.width - 20), height: 30)
        self.contentView.addSubview(lblAddress)
    }
    func createDashedLine(from point1: CGPoint, to point2: CGPoint, color: UIColor, strokeLength: NSNumber, gapLength: NSNumber, width: CGFloat) {
        let shapeLayer = CAShapeLayer()

        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = width
        shapeLayer.lineDashPattern = [strokeLength, gapLength]

        let path = CGMutablePath()
        path.addLines(between: [point1, point2])
        shapeLayer.path = path
        layer.addSublayer(shapeLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
