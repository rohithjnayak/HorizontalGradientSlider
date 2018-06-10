//
//  HorizontalGradientSlider.swift
//  HorizontalGradientSlider
//
//  Created by Rohith J Nayak on 20/05/18.
//  Copyright © 2018 Rohith J Nayak. All rights reserved.
//

import UIKit

class HorizontalGradientSlider: UIControl {
    
    //MARK:- Constants
    
    private static let defaultThickness:CGFloat = 2.0
    private static let defaultThumbSize:CGFloat = 20.0
    private let kCenterPointEnabledImageName:String! = "centre_line_slider_on"
    private let kCenterPointDisabledImageName:String! = "centre_line_slider_disable"
    
    //MARK:- Private Var
    
    private var _value:CGFloat = 0.0
    
    private var _thumbLayer:CALayer = {
        let thumb = CALayer()
        thumb.cornerRadius = defaultThumbSize/2.0
        thumb.bounds = CGRect(x: 0, y: 0, width: defaultThumbSize, height: defaultThumbSize)
        thumb.backgroundColor = UIColor.white.cgColor
        thumb.shadowColor = UIColor.black.cgColor
        thumb.shadowOffset = CGSize(width: 0.0, height: 2.5)
        thumb.shadowRadius = 2.0
        thumb.shadowOpacity = 0.25
        thumb.borderColor = UIColor.clear.cgColor
        thumb.borderWidth = 0.5
        return thumb
    }()
    
    private var _gradientLayer:CAGradientLayer = {
        let track = CAGradientLayer()
        track.cornerRadius = defaultThickness / 2.0
        track.startPoint = CGPoint(x: 0.0, y: 0.5)
        track.endPoint = CGPoint(x: 1.0, y: 0.5)
        track.locations = [0.0,1.0]
        track.colors = [UIColor.blue.cgColor,UIColor.orange.cgColor]
        track.borderColor = UIColor.black.cgColor
        return track
    }()
    
    private var _trackLayer:CALayer = {
        let track = CALayer()
        track.cornerRadius = defaultThickness / 2.0
        track.cornerRadius = defaultThickness/2.0
        track.backgroundColor = UIColor.gray.cgColor
        return track
    }()
    
    private var _imageLayer:CALayer = {
        let track = CALayer()
        return track
    }()
    
    private var _maskLayer:CAShapeLayer = {
        let maskLayer = CAShapeLayer()
        maskLayer.fillColor = UIColor.black.cgColor
        return maskLayer
    }()

    //MARK:- Public Var
    
    var isContinuous:Bool = true
    var actionBlock:(HorizontalGradientSlider,CGFloat) -> () = {slider,newValue in}
    
    let centerImageHeight:CGFloat! = 9.0
    let centerImageWidth:CGFloat! = 1.0
    
    @IBInspectable var thickness:CGFloat = defaultThickness {
        didSet{
            _trackLayer.cornerRadius = thickness/2.0
            self.layer.setNeedsLayout()
        }
    }
    @IBInspectable var value:CGFloat {
        get{return _value}
        set{setValue(newValue, animated:true)}
    }
    
    @IBInspectable var minColor:UIColor = UIColor.blue {didSet{updateTrackColors()}}
    @IBInspectable var maxColor:UIColor = UIColor.orange {didSet{updateTrackColors()}}
    @IBInspectable var locations:Array<Float> = [0,1] {didSet{updateTrackColors()}}
    @IBInspectable var trackColor:UIColor = UIColor.white{didSet{updateTrackColors()}}
    @IBInspectable var minimumValue:CGFloat = 0.0 // default 0.0. the current value may change if outside new min value
    @IBInspectable var maximumValue:CGFloat = 1.0 // default 1.0. the current value may change if outside new max value
    
    var thumbSize:CGFloat = defaultThumbSize {
        didSet{
            _thumbLayer.cornerRadius = thumbSize / 2.0
            _thumbLayer.bounds = CGRect(x: 0, y: 0, width: thumbSize, height: thumbSize)
            self.invalidateIntrinsicContentSize()
        }
    }
    
    //MARK:- Initializer
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        minColor = aDecoder.decodeObject(forKey: "minColor") as? UIColor ?? UIColor.lightGray
        maxColor = aDecoder.decodeObject(forKey: "maxColor") as? UIColor ?? UIColor.darkGray
        
        value = aDecoder.decodeObject(forKey: "value") as? CGFloat ?? 0.0
        minimumValue = aDecoder.decodeObject(forKey: "minimumValue") as? CGFloat ?? 0.0
        maximumValue = aDecoder.decodeObject(forKey: "maximumValue") as? CGFloat ?? 1.0
        
        thickness = aDecoder.decodeObject(forKey: "thickness") as? CGFloat ?? 2.0
        
        commonSetup()
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        
        aCoder.encode(minColor, forKey: "minColor")
        aCoder.encode(maxColor, forKey: "maxColor")
        
        aCoder.encode(value, forKey: "value")
        aCoder.encode(minimumValue, forKey: "minimumValue")
        aCoder.encode(maximumValue, forKey: "maximumValue")
        
        aCoder.encode(thickness, forKey: "thickness")
        
    }
    
    //MARK:- Private Methods
    
    private func commonSetup() {
        self.layer.delegate = self
        self.layer.addSublayer(_trackLayer)
        self.layer.addSublayer(_gradientLayer)
        _gradientLayer.mask = _maskLayer
        self.layer.addSublayer(_imageLayer)
        self.layer.addSublayer(_thumbLayer)
    }
    
    private func getCenterImage(WithEnabledState:Bool) -> UIImage?{
        let imageName:String = WithEnabledState ?kCenterPointEnabledImageName:kCenterPointDisabledImageName
        return UIImage(named: imageName)
    }
    
    private func drawSliderCenterImage(forState inState:Bool){
        if let centerImage:UIImage = getCenterImage(WithEnabledState: inState){
            _imageLayer.contents = centerImage.cgImage
        }
    }
    
    
    private func getCurrentMaskPath() ->UIBezierPath{
        
        let h = self.bounds.height * 0.5
        
        let centerBottomPoint = CGPoint(x: self.bounds.midX, y: self.bounds.minY)
        let centerTopPoint = CGPoint(x: self.bounds.midX, y: h)
        
        let locationPoint = locationForValue(self.value)
        
        let currentValueBottomPoint = CGPoint(x: locationPoint.x, y: self.bounds.minY)
        let currentValueTopPoint = CGPoint(x: locationPoint.x,y: h)
        
        let bezierPath = UIBezierPath()
        bezierPath.move(to: centerBottomPoint)
        bezierPath.addLine(to: centerTopPoint)
        bezierPath.addLine(to: currentValueTopPoint)
        bezierPath.addLine(to: currentValueBottomPoint)
        bezierPath.close()
        
        return bezierPath
    }
    
    private func valueForLocation(_ point:CGPoint)->CGFloat {
        
        let left = self.bounds.origin.x
        let w = self.bounds.width
        
        
        let diff = CGFloat(self.maximumValue - self.minimumValue)
        
        let perc = max(min((point.x - left) / w ,1.0), 0.0)
        
        return (perc * diff) + CGFloat(self.minimumValue)
    }
    
    private func locationForValue(_ value:CGFloat)->CGPoint {
        
        var  knobPoint:CGPoint = CGPoint.zero;
        
        knobPoint.y = self.bounds.midY;
        
        let maxX = self.bounds.width;
        let minX = self.bounds.minX;
        
        let knobX = (value - minimumValue)*((maxX-minX)/(maximumValue-minimumValue))+minX;
        
        knobPoint.x = knobX
        
        return knobPoint;
        
    }
    
    private func updateTrackColors() {
        
        _trackLayer.backgroundColor = trackColor.cgColor
        _gradientLayer.colors = [minColor.cgColor,maxColor.cgColor]
        _gradientLayer.locations = locations as [NSNumber]? //[0.0,1.0]
    }
    
    private func thumbColorForValue(_ value:CGFloat)->UIColor {
        
        var minRed:CGFloat = 0.0,minGreen:CGFloat = 0.0,minBlue:CGFloat = 0.0,minAlpha:CGFloat = 0.0
        
        minColor.getRed(&minRed, green: &minGreen, blue: &minBlue, alpha: &minAlpha)
        
        var maxRed:CGFloat = 0.0,maxGreen:CGFloat = 0.0,maxBlue:CGFloat = 0.0,maxAlpha:CGFloat = 0.0
        
        maxColor.getRed(&maxRed, green: &maxGreen, blue: &maxBlue, alpha: &maxAlpha)
        let resultRed = minRed + (value-self.minimumValue) * ((maxRed - minRed)/(self.maximumValue - self.minimumValue));
        let resultGreen = minGreen + (value-self.minimumValue) * ((maxGreen - minGreen)/(self.maximumValue - self.minimumValue));
        let resultBlue = minBlue + (value-self.minimumValue) * ((maxBlue - minBlue)/(self.maximumValue - self.minimumValue));
        let resultAlpha = minAlpha + (value-self.minimumValue) * ((maxAlpha - minAlpha)/(self.maximumValue - self.minimumValue));
        
        return UIColor(red: resultRed, green: resultGreen, blue: resultBlue, alpha: resultAlpha)
        
    }
    
    private func updatemaskLayer(animated:Bool){
        _maskLayer.path = getCurrentMaskPath().cgPath
    }
    
    private func updateThumbPosition(animated:Bool){
        let diff = maximumValue - minimumValue
        let perc = CGFloat((value - minimumValue) / diff)
        
        let halfHeight = self.bounds.height / 2.0
        let trackWidth = _trackLayer.bounds.width - thumbSize
        let left = _trackLayer.position.x - trackWidth/2.0
        
        if !animated{
            CATransaction.begin() //Move the thumb position without animations
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)
            _thumbLayer.position = CGPoint(x: left + (trackWidth * perc), y: halfHeight)
            CATransaction.commit()
        }else{
            _thumbLayer.position = CGPoint(x: left + (trackWidth * perc), y: halfHeight)
        }
        _thumbLayer.backgroundColor = self.thumbColorForValue(self.value).cgColor
    }
    
    private func getCenterImageDimension() -> CGSize{
        
        if let img = getCenterImage(WithEnabledState: true){
            return img.size
        }
        return CGSize(width: 9, height: 9)
    }
    
    //MARK:- Public Methods
    
    func setValue(_ value:CGFloat, animated:Bool = true) {
        _value = max(min(value,self.maximumValue),self.minimumValue)
        updatemaskLayer(animated:animated)
        updateThumbPosition(animated: animated)
    }
    
    func setSliderDisableStateThumbColor(_ inColor:CGColor){
        _thumbLayer.backgroundColor = inColor
    }
    
    func enableSliderThumbColor(){
        _thumbLayer.backgroundColor = self.thumbColorForValue(self.value).cgColor
    }
    
    func setSliderDisableStateGradientColor(_ inColor:CGColor){
        _gradientLayer.colors = [inColor]
        _gradientLayer.locations = [1]
    }
    
    func drawSliderCenterImageForState(_ inState:Bool){
        drawSliderCenterImage(forState: inState)
    }
    
    //MARK:- Overrides

    override var intrinsicContentSize: CGSize {
        get {
            return CGSize(width: UIViewNoIntrinsicMetric, height: thumbSize)
        }
    }
    
    override var alignmentRectInsets: UIEdgeInsets {
        get {
            return UIEdgeInsetsMake(4.0, 2.0, 4.0, 2.0)
        }
    }
    
    override func layoutSublayers(of layer: CALayer) {
        commonSetup()
        if layer != self.layer {return}
        
        let w = self.bounds.width
        let h = self.bounds.height
        let left:CGFloat = 2.0
        
        _trackLayer.bounds = CGRect(x: 0, y: 0, width: w, height: thickness)
        _trackLayer.position = CGPoint(x: w/2.0 + left, y: h/2.0)
        
        let imageWidth = getCenterImageDimension().width
        let imageHeight = getCenterImageDimension().height
        
        _imageLayer.bounds = CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)
        _imageLayer.position = CGPoint(x: w/2.0 + left, y: h/2.0)
        
        _gradientLayer.bounds = CGRect(x: 0, y: 0, width: w, height: thickness)
        _gradientLayer.position = CGPoint(x: w/2.0 + left, y: h/2.0)
        
        updateThumbPosition(animated: false)
        updatemaskLayer(animated: false)
    }
    

    //MARK: - Touch Tracking
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let pt = touch.location(in: self)
        
        let center = _thumbLayer.position
        let diameter = max(thumbSize,44.0)
        let r = CGRect(x: center.x - diameter/2.0, y: center.y - diameter/2.0, width: diameter, height: diameter)
        if r.contains(pt){
            sendActions(for: UIControlEvents.touchDown)
            return true
        }
        return false
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        
        let pt = touch.location(in: self)
        let newValue = valueForLocation(pt)
        setValue(newValue, animated: false)
        if(isContinuous){
            sendActions(for: UIControlEvents.valueChanged)
            actionBlock(self,newValue)
        }
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if let pt = touch?.location(in: self){
            let newValue = valueForLocation(pt)
            setValue(newValue, animated: false)
        }
        actionBlock(self,_value)
        sendActions(for: [UIControlEvents.valueChanged, UIControlEvents.touchUpInside])
    }
}
