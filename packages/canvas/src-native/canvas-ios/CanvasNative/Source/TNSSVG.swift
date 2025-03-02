//
//  TNSSVG.swift
//  CanvasNative
//
//  Created by Osei Fortune on 27/01/2021.
//
import Foundation
import UIKit
@objcMembers
@objc(TNSSVG)
public class TNSSVG: UIView {
    var data: UnsafeMutableRawPointer? = nil
    var data_size: CGSize = .zero
    var buf_size: UInt = 0
    var context: Int64 = 0
    var didInitDrawing = false
    var forceResize = false
    public var ignorePixelScaling = false {
        didSet {
            forceResize = true
        }
    }
    public var src: String? = nil {
        didSet {
            doDraw()
        }
    }
    
    public var srcPath: String? = nil {
        didSet {
            doDraw()
        }
    }
    
    func deviceScale() -> Float32 {
        if !ignorePixelScaling  {
            return Float32(UIScreen.main.nativeScale)
        }
        return 1
    }
    
    var workItem: DispatchWorkItem?
    func doDraw(){
        if self.srcPath == nil && self.src == nil {return}
        workItem?.cancel()
        workItem = DispatchWorkItem {
            [weak self] in
                guard let self =  self else {return}
                if(self.context > 0){
                    if(self.srcPath != nil){
                        guard let srcPath = self.srcPath else{return}
                        let source = srcPath as NSString
                        svg_draw_from_path(self.context, source.utf8String)
                        guard let buf = self.data?.assumingMemoryBound(to: UInt8.self) else {return}
                        context_custom_with_buffer_flush(self.context, buf, self.buf_size, Float(self.data_size.width), Float(self.data_size.height))
                        
                        DispatchQueue.main.async { [self] in
                            if(self.workItem!.isCancelled){
                                return
                            }
                            self.didInitDrawing = true
                            self.setNeedsDisplay()
                        }
                        return
                    }
                    
                    guard let src = self.src else{return}
                    let source = src as NSString
                    svg_draw_from_string(self.context, source.utf8String)
                    guard let buf = self.data?.assumingMemoryBound(to: UInt8.self) else {return}
                    context_custom_with_buffer_flush(self.context, buf, self.buf_size, Float(self.data_size.width), Float(self.data_size.height))
                    
                    DispatchQueue.main.async {
                        [self] in
                            if(self.workItem!.isCancelled){
                                return
                            }
                        self.didInitDrawing = true
                        self.setNeedsDisplay()
                    }
                }
        }
        queue.async(execute: workItem!)
    }
    

    func update(){
        let size = layer.frame.size
        let width = Float(size.width) * deviceScale()
        let height = Float(size.height) * deviceScale()
        if !size.equalTo(data_size) || forceResize {
            data?.deallocate()
            data = calloc(Int(width * height), 4)
            buf_size = UInt(width * height * 4)
            data_size = CGSize(width: CGFloat(width), height: CGFloat(height))
            if context == 0 {
                var direction = TNSTextDirection.Ltr
                if(UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft){
                    direction = TNSTextDirection.Rtl
                }
                context = context_init_context_with_custom_surface(Float(width), Float(height), deviceScale(), true, 0, 0, TextDirection(rawValue: direction.rawValue))
                doDraw()
            }else {
                context_resize_custom_surface(context, Float(width), Float(height), deviceScale(), true, 0)
                doDraw()
            }
            
            if forceResize {
                forceResize = false
            }
        }
    }
    
    public override func layoutSubviews() {
        update()
    }
    
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    private var queue: DispatchQueue
    public override init(frame: CGRect) {
        queue = DispatchQueue(label: "TNSSVG")
        super.init(frame: frame)
        backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        queue = DispatchQueue(label: "TNSSVG")
        super.init(coder: coder)
    }
    
    public override func draw(_ rect: CGRect) {
        if context > 0  && didInitDrawing {
            let width = Int(self.data_size.width)
            let height = Int(self.data_size.height)
            let ctx = CGContext(data: self.data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: self.colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
            
            guard let cgImage = ctx?.makeImage() else {return}
            let image = UIImage(cgImage: cgImage)
            image.draw(in: rect)
            
        }
    }
    
    public func toImage() -> UIImage? {
        if context > 0  && didInitDrawing {
            let width = Int(self.data_size.width)
            let height = Int(self.data_size.height)
            let ctx = CGContext(data: self.data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: self.colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
            
            guard let cgImage = ctx?.makeImage() else {return nil}
            return UIImage(cgImage: cgImage)
            
        }
        return nil
    }
    
    public func toData() -> NSData? {
        return NSMutableData(bytes: data, length: Int(buf_size))
    }
}
