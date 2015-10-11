//
//  GameScene.swift
//  TouchSparks
//
//  Created by Alan Browning on 10/10/15.
//  Copyright (c) 2015 Garbanzo. All rights reserved.
//

import SpriteKit
import CoreMotion

extension CGVector {
  mutating func rotateRad(rad: Float) {
    let x = Float(self.dx);
    let y = Float(self.dy);
    self.dx = CGFloat(x * cosf(rad) - y * sinf(rad));
    self.dy = CGFloat(x * sinf(rad) + y * cosf(rad));
  }
  
  mutating func rotateDeg(deg: Float) {
    let rad = Double(deg) * M_PI / 180.0;
    rotateRad(Float(rad));
  }
}

extension CGPoint {
  mutating func rotateRad(rad: Float) {
    let x = Float(self.x);
    let y = Float(self.y);
    self.x = CGFloat(x * cosf(rad) - y * sinf(rad));
    self.y = CGFloat(x * sinf(rad) + y * cosf(rad));
  }
  
  mutating func rotateDeg(deg: Float) {
    let rad = Double(deg) * M_PI / 180.0;
    rotateRad(Float(rad));
  }
  
}

class GameScene: SKScene {
  
  /// MARK: Member variables
  
  var instruction_label: SKLabelNode?;

  var shapes_being_added: [Int: SKNode] = [:];
  
  var motion_manager = CMMotionManager();
  
  var palette: [UIColor] = [];
  
  /// MARK: Scene contents
  
  func createSceneContents() {
    
    let myLabel = SKLabelNode(fontNamed:"AvenirNextCondensed-DemiBold");
    myLabel.text = "Tap to make a shape.";
    myLabel.fontSize = 45
    myLabel.fontColor = UIColor(white: 0.15, alpha: 1.0);
    //myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
    myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMaxY(self.frame) - myLabel.frame.height);
    
    self.addChild(myLabel);
    instruction_label = myLabel;
    
    palette.append(UIColor(red: 0.984, green: 0.278, blue: 0.031, alpha: 1.0));
    palette.append(UIColor(hue: 314.0/360.0, saturation: 0.25, brightness: 0.20, alpha: 1.0));
    palette.append(UIColor(hue: 86/360, saturation: 0.88, brightness: 0.35, alpha: 1.0));
    palette.append(UIColor(hue: 51/360, saturation: 1.0, brightness: 0.5, alpha: 1.0));
    palette.append(UIColor(hue: 357/360, saturation: 0.73, brightness: 0.62, alpha: 1.0));

    for idx in 0..<palette.count {
      var h, s, b, a: CGFloat;
      (h,s,b,a) = (0,0,0,0);
      palette[idx].getHue(&h, saturation: &s, brightness: &b, alpha: &a);
      palette[idx] = UIColor(hue: h, saturation: s-0.5*s, brightness: 1.0/*b+0.5*(1.0-b)*/, alpha: a);
    }
  }
  
  override func didMoveToView(view: SKView) {
    /* Setup your scene here */
    self.backgroundColor = SKColor(white: 0.1, alpha: 1.0);
    self.physicsBody = SKPhysicsBody(edgeLoopFromRect: self.frame);
    
    createSceneContents();
    
    motion_manager.deviceMotionUpdateInterval = 1.0 / 30;
    motion_manager.startDeviceMotionUpdates();
  }
  
  /// MARK: Gravity logic
  
  func changeGravityVector() {
    self.physicsWorld.gravity.rotateDeg(90.0);
  }
  
  /// MARK: Touch logic
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    /* Called when a touch begins */
    
    for touch in touches {
      
      var shape = SKShapeNode();
      let size = max(15.0, touch.majorRadius);
      
      let sample = arc4random_uniform(3);
      if (sample == 0) {
        
        let rad = size + 5.0;
        var points: [CGPoint] = [];
        for _ in 1...4 {
          points.append(CGPoint(x: 0.0, y: rad));
        }
        points[1].rotateDeg(120.0);
        points[2].rotateDeg(-120.0);
        
        let path = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, points[0].x, points[0].y)
        for p in points {
          CGPathAddLineToPoint(path, nil, p.x, p.y)
        }
        CGPathCloseSubpath(path)
        
        shape = SKShapeNode(path: path);
        shape.physicsBody = SKPhysicsBody(polygonFromPath: path);
        
      } else if (sample == 1) {
        shape = SKShapeNode(rect: CGRect(origin: CGPoint(x: -size/2.0, y: -size/2.0), size: CGSize(width: size, height: size)), cornerRadius: 5.0);
        shape.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: size, height: size), center: CGPoint(x: 0, y: 0));
      } else {
        shape = SKShapeNode(circleOfRadius: size/2.0);
        shape.physicsBody = SKPhysicsBody(circleOfRadius: size/2.0);
        shape.physicsBody?.restitution = 1;
      }
      
      //shape.fillColor = UIColor(white: 1.0, alpha: 0.5);
      let color_idx = arc4random_uniform(UInt32(palette.count));
      shape.fillColor = palette[Int(color_idx)];
      shape.strokeColor = UIColor(white: 1.0, alpha: 0.0);
      shape.position = touch.locationInNode(self);
      shape.runAction(SKAction.fadeInWithDuration(0.5), completion: { () -> Void in print("shape fade in complete") });
      
      self.addChild(shape);
      shapes_being_added[touch.hashValue] = shape;
    }
  }
  
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    for touch in touches {
      if let shape = shapes_being_added[touch.hashValue] {
        shape.position = touch.locationInNode(self);
      }
    }
  }
  
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    print("touches ended");
    
    instruction_label?.runAction(SKAction.fadeOutWithDuration(0.5));
//    if ((instruction_label) != nil) {
//      instruction_label?.runAction(SKAction.fadeOutWithDuration(0.5));
//    }
    
    // remove entry in shapes_being_added for this touch
    for touch in touches {
      shapes_being_added.removeValueForKey(touch.hashValue);
    }
  }
  
  override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    print("touches cancelled");
  }
  
  override func update(currentTime: CFTimeInterval) {
    /* Called before each frame is rendered */
    let grav = motion_manager.deviceMotion?.gravity;
    if (grav != nil) {
      let scale = 100.0;
      self.physicsWorld.gravity.dx = CGFloat(grav!.x * scale);
      self.physicsWorld.gravity.dy = CGFloat(grav!.y * scale);
    }
  }
}
