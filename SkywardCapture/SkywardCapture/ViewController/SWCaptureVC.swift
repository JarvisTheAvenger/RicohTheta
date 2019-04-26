//
//  SWCaptureVC.swift
//  SkywardCapture
//
//  Created by Rahul Umap on 08/04/19.
//  Copyright © 2019 Rahul Umap. All rights reserved.
//

import UIKit
import SceneKit
import CoreMotion
import SpriteKit
    
class SWCaptureVC: UIViewController {
    @IBOutlet weak var sceneView: SCNView!
    
    let scene = SCNScene()
    var startScale = 0.0
    var prevLocation = CGPoint.zero
    @objc var panSpeed = CGPoint(x: 0.005, y: 0.005)
    var prevBounds = CGRect.zero
    var httpConnection = HttpConnection()
    
    lazy var cameraNode: SCNNode = {
        let node = SCNNode()
        let camera = SCNCamera()
        node.camera = camera
        return node
    }()
    
    var xFov: CGFloat {
        return yFov * sceneView.bounds.width / sceneView.bounds.height
    }
    
    var yFov: CGFloat {
        get {
            if #available(iOS 11.0, *) {
                return cameraNode.camera?.fieldOfView ?? 0
            } else {
                return CGFloat(cameraNode.camera?.yFov ?? 0)
            }
        }
        set {
            if #available(iOS 11.0, *) {
                cameraNode.camera?.fieldOfView = newValue
            } else {
                cameraNode.camera?.yFov = Double(newValue)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.httpConnection.setTargetIp("192.168.1.1")
        setup()
    }
    
    func setup() {
        // Set the scene
        scene.rootNode.addChildNode(cameraNode)
        yFov = 35
        
        sceneView.scene = scene
        sceneView.backgroundColor = UIColor.black
        
        let panGestureRec = UIPanGestureRecognizer(target: self, action: #selector(handlePan(panRec:)))
        sceneView.addGestureRecognizer(panGestureRec)
        
        let pinchRec = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(pinchRec:)))
        sceneView.addGestureRecognizer(pinchRec)
     
        let tap = UILongPressGestureRecognizer(target: self, action: #selector(handleTap(rec:)))
        sceneView.addGestureRecognizer(tap)
       
        let material = SCNMaterial()
        material.diffuse.mipFilter = .nearest
        material.diffuse.magnificationFilter = .linear
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(-1, 1, 1)
        material.diffuse.wrapS = .mirror
        material.cullMode = .front
        
        let sphere = SCNSphere(radius: 8)
        sphere.segmentCount = 300
        
        httpConnection.startLiveView { (data) in
            DispatchQueue.main.async {
               let image = UIImage(data: data!)
                material.diffuse.contents = image
            }
        }
        
        sphere.firstMaterial = material
        let sphereNode = SCNNode()
        sphereNode.geometry = sphere
        
        scene.rootNode.addChildNode(sphereNode)
    }
    
    
    // MARK: Gesture handling
    
    //Method called when tap
    //Method called when tap
    @objc func handleTap(rec: UITapGestureRecognizer){
        if rec.state == .ended {
            let location: CGPoint = rec.location(in: sceneView)
            let hits = sceneView.hitTest(location, options: nil)
            
            if !hits.isEmpty {
                let result: SCNHitTestResult = hits[0]
                addHotspot(result: result, parentNode: result.node)
            }
        }
    }
    
    func addHotspot(result : SCNHitTestResult, parentNode : SCNNode? = nil) {
        let sphere = SCNSphere(radius: 1)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.diffuse.mipFilter = .nearest
        material.diffuse.magnificationFilter = .linear
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(-1, 1, 1)
        material.diffuse.wrapS = .repeat
        material.cullMode = .front
        material.isDoubleSided = true
        
        sphere.firstMaterial = material
        
        let sphereNode = SCNNode()
        sphereNode.geometry = sphere
        sphereNode.position = result.worldCoordinates
        
        parentNode?.addChildNode(sphereNode)
    }
  
    @objc private func handlePan(panRec: UIPanGestureRecognizer) {
        if panRec.state == .began {
            prevLocation = CGPoint.zero
        } else if panRec.state == .changed {
            let modifiedPanSpeed = panSpeed
            let location = panRec.translation(in: sceneView)
            let orientation = cameraNode.eulerAngles
            var newOrientation = SCNVector3Make(orientation.x + Float(location.y - prevLocation.y) * Float(modifiedPanSpeed.y),
                                                orientation.y + Float(location.x - prevLocation.x) * Float(modifiedPanSpeed.x),
                                                orientation.z)
            
            newOrientation.x = max(min(newOrientation.x, 1.1), -1.1)
            
            cameraNode.eulerAngles = newOrientation
            prevLocation = location
            
        }
    }
    
    @objc func handlePinch(pinchRec: UIPinchGestureRecognizer) {
        if pinchRec.numberOfTouches != 2 {
            return
        }
        
        let zoom = Double(pinchRec.scale)
        switch pinchRec.state {
        case .began:
            startScale = Double(cameraNode.camera!.fieldOfView)
        case .changed:
            let fov = startScale / zoom
            if fov > 20 && fov < 80 {
                cameraNode.camera!.fieldOfView = CGFloat(fov)
            }
        default:
            break
        }
    }
    
    @IBAction func captureButtonAction(_ sender: Any) {
        httpConnection.takePicture()
    }
}

