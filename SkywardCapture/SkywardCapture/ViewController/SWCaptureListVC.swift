//
//  SWCaptureListVC.swift
//  SkywardCapture
//
//  Created by Rahul Umap on 08/04/19.
//  Copyright © 2019 Rahul Umap. All rights reserved.
//

import UIKit

class SWCaptureListVC: UIViewController {
    @IBOutlet weak var captureListTableView: UITableView!
    
    var httpConnection = HttpConnection()
    var ricohImages = [RicohImage]()
    let ipAddress = "192.168.1.1"
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.getImageListFromDevice), for: .valueChanged)
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func setup() {
        captureListTableView.tableFooterView = UIView(frame: .zero)
        captureListTableView.addSubview(refreshControl)
        DispatchQueue.main.async {
            self.httpConnection.setTargetIp(self.ipAddress)
            self.getImageListFromDevice()
        }
    }
    
    @objc func getImageListFromDevice() {
        ricohImages.removeAll()
        DispatchQueue.main.async {
            guard let images = self.httpConnection.getImageInfoes() else { return }
            
            for i in 0..<images.count {
                let info = images[i] as? HttpImageInfo
                var ricohImage = RicohImage()
                ricohImage.imageInfo = info
                
                let thumbData: Data? = self.httpConnection.getThumb(info?.file_id)
                
                if let thumbData = thumbData {
                    ricohImage.thumbnail = UIImage(data: thumbData)
                }
                self.ricohImages.append(ricohImage)
                self.refreshControl.endRefreshing()
            }
            self.captureListTableView.reloadData()
        }
    }
    
    
    @IBAction func addButtonAction(_ sender: Any) {
        performSegue(withIdentifier: "segueCaptureListToNewCapture", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueHotspotVC" {
            let segueDestVC = segue.destination as! SWHotspotVC
            segueDestVC.ricohImage = sender as? RicohImage
        }
    }
    
}

extension SWCaptureListVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ricohImages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RicohImageTableViewCell", for: indexPath) as? RicohImageTableViewCell
        
        let object = ricohImages[indexPath.row]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium
 
        cell?.ricohImageView.image = object.thumbnail
        cell?.imageNameLabel.text = object.imageInfo?.file_name
        cell?.capturedDateLabel.text = dateFormatter.string(from: object.imageInfo!.capture_date)
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 141
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ricohImage = ricohImages[indexPath.row]
        performSegue(withIdentifier: "segueHotspotVC", sender: ricohImage)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            DispatchQueue.global(qos: .default).async {
                let object = self.ricohImages[indexPath.row]
                if self.httpConnection.deleteImage(object.imageInfo) {
                    DispatchQueue.main.async {
                        self.ricohImages.remove(at: indexPath.row)
                        self.captureListTableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
            }
           
        }
    }
    
}
