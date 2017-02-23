//
//  OpenGL.swift
//  CameraTest
//
//  Created by Peter Strand on 2017-02-01.
//  Copyright © 2017 Nena Innovation AB. All rights reserved.
//

import Foundation

import GLKit
import OpenGLES
import CoreVideo

func BUFFER_OFFSET(_ i: Int) -> UnsafeRawPointer? {
  return UnsafeRawPointer(bitPattern: i)
}

class OpenGL : NSObject, GLKViewDelegate {
  
  var program: GLuint = 0
  
  var a_position: GLuint = 0
  var a_texCoord: GLuint = 0
  var u_sampler: GLint = 0
  var u_transform: GLint = 0
  
  var transformMatrix: GLKMatrix4 = GLKMatrix4Identity
  
  var vertexArray: GLuint = 0
  var vertexBuffer: GLuint = 0
  var textureId1: GLuint = 0
  
  var context: EAGLContext? = nil
  var glk_view: GLKView! = nil
  
  var displayLink: CADisplayLink? = nil
  
  
  deinit {

    self.tearDownGL()
    
    if EAGLContext.current() === self.context {
      EAGLContext.setCurrent(nil)
    }
  }
  
  func setImage(_ image: CGImage) {
    let width = image.width
    let height = image.height
    
    let pixels = UnsafeMutablePointer<UInt8>.allocate(capacity: 4 * width * height)
    print("Allocated image buffer with size \(width)x\(height)")
    let cs = CGColorSpaceCreateDeviceRGB()
    
    let bitmapInfo = CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedLast.rawValue);
    
    let img_gc = CGContext(data: pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: cs, bitmapInfo: bitmapInfo.rawValue);
   
    img_gc?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    
    glGenTextures(1, &textureId1)
    glBindTexture(GLenum(GL_TEXTURE_2D), textureId1);
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST);
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_NEAREST);
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE);
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE);
    glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, Int32(width), Int32(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), pixels);

  }

  func setup(_ view: GLKView, image: CGImage) {
    
    
    self.glk_view = view
    
    self.context = EAGLContext(api: .openGLES2)
    
    if !(self.context != nil) {
      print("Failed to create ES context")
    }
    
    if let glk = self.glk_view {
      glk.context = self.context!
      glk.drawableColorFormat = .RGBA8888
      glk.drawableDepthFormat = .format24
    }

    EAGLContext.setCurrent(self.context)
    
    setImage(image)
    

    if(self.loadShaders() == false) {
      print("Failed to load shaders")
    }
    
    glEnable(GLenum(GL_DEPTH_TEST))
    
    glGenVertexArraysOES(1, &vertexArray)
    glBindVertexArrayOES(vertexArray)
    
    glGenBuffers(1, &vertexBuffer)
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
    var vertexData: [GLfloat] = [
      -1.0, -1.0, 0.0,  0, 0,
       1.0, -1.0, 0.0,  1, 0,
      -1.0,  1.0, 0.0,  0, 1,
      -1.0,  1.0, 0.0,  0, 1,
       1.0, -1.0, 0.0,  1, 0,
       1.0,  1.0, 0.0,  1, 1,
      ]

    glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(MemoryLayout<GLfloat>.size * vertexData.count), &vertexData, GLenum(GL_STATIC_DRAW))
    
    glEnableVertexAttribArray(a_position)
    glVertexAttribPointer(a_position, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 20, BUFFER_OFFSET(0))
    glEnableVertexAttribArray(a_texCoord)
    glVertexAttribPointer(a_texCoord, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 20, BUFFER_OFFSET(12))
    
    glBindVertexArrayOES(0)

    glk_view.delegate = self
    
    self.displayLink = CADisplayLink(target: self, selector: #selector(displayLinkUpdate))
    self.displayLink?.preferredFramesPerSecond = 60
    self.displayLink?.add(to: .current, forMode: .defaultRunLoopMode)

  }
  
  var lastTimestamp: TimeInterval = 0
  func displayLinkUpdate(_ displayLink : CADisplayLink) {
    let elapsedTime = Float(displayLink.timestamp  - self.lastTimestamp)
    
    self.glk_view.display()
    
    update(elapsedTime)
    self.lastTimestamp = displayLink.timestamp;
    
  }
  
  func tearDownGL() {
    EAGLContext.setCurrent(self.context)
    
    glDeleteBuffers(1, &vertexBuffer)
    glDeleteVertexArraysOES(1, &vertexArray)
    
    if program != 0 {
      glDeleteProgram(program)
      program = 0
    }
  }
  
  // MARK: - GLKView and GLKViewController delegate methods
  
  func update(_ delta: Float) {
    let aspect = fabsf(Float(self.glk_view.bounds.size.width / self.glk_view.bounds.size.height))
    let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), aspect, 0.1, 100.0)
    
    let baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -3.0)
//    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, rotation, 0.0, 1.0, 0.0)
    
    // Compute the model view matrix for the object rendered with GLKit
    var modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -1.5)
//    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, rotation, 1.0, 1.0, 1.0)
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix)
    
    // Compute the model view matrix for the object rendered with ES2
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, 1.5)
//    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, rotation, 1.0, 1.0, 1.0)
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix)
    
    transformMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix)
    
    transformMatrix = GLKMatrix4Identity
    
  }
  
  func glkView(_ view: GLKView, drawIn rect: CGRect) {
    glClearColor(0.85, 0.65, 0.65, 1.0)
    glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
    
    glUseProgram(program)
    glBindVertexArrayOES(vertexArray)

    withUnsafePointer(to: &transformMatrix, {
      $0.withMemoryRebound(to: Float.self, capacity: 16, {
        glUniformMatrix4fv(self.u_transform, 1, 0, $0)
      })
    })
    
    glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
 
  }
  
  // MARK: -  OpenGL ES 2 shader compilation
  
  func loadShaders() -> Bool {
    var vertShader: GLuint = 0
    var fragShader: GLuint = 0
    
    // Create shader program.
    program = glCreateProgram()
    
    // Create and compile vertex shader.
    guard let vertShaderPathname = Bundle.main.path(forResource: "Shader", ofType: "vert") else {
      print("Failed to find vertex shader")
      return false
    }
    if self.compileShader(&vertShader, type: GLenum(GL_VERTEX_SHADER), file: vertShaderPathname) == false {
      print("Failed to compile vertex shader")
      return false
    }
    
    // Create and compile fragment shader.
    guard let fragShaderPathname = Bundle.main.path(forResource: "Shader", ofType: "frag") else {
      print("Failed to find fragment shader")
      return false
    }
    if !self.compileShader(&fragShader, type: GLenum(GL_FRAGMENT_SHADER), file: fragShaderPathname) {
      print("Failed to compile fragment shader")
      return false
    }
    
    // Attach vertex shader to program.
    glAttachShader(program, vertShader)
    
    // Attach fragment shader to program.
    glAttachShader(program, fragShader)
    
    
    // Link program.
    if !self.linkProgram(program) {
      print("Failed to link program: \(program)")
      
      if vertShader != 0 {
        glDeleteShader(vertShader)
        vertShader = 0
      }
      if fragShader != 0 {
        glDeleteShader(fragShader)
        fragShader = 0
      }
      if program != 0 {
        glDeleteProgram(program)
        program = 0
      }
      
      return false
    }
    
    self.u_transform = glGetUniformLocation(program, "u_transform")
    self.u_sampler = glGetUniformLocation(program, "u_sampler")
    a_position = GLuint(glGetAttribLocation(program, "a_position"))
    a_texCoord = GLuint(glGetAttribLocation(program, "a_texCoord"))
    
    // Release vertex and fragment shaders.
    if vertShader != 0 {
      glDetachShader(program, vertShader)
      glDeleteShader(vertShader)
    }
    if fragShader != 0 {
      glDetachShader(program, fragShader)
      glDeleteShader(fragShader)
    }
    
    return true
  }
  
  
  func compileShader(_ shader: inout GLuint, type: GLenum, file: String) -> Bool {
    var status: GLint = 0
    var source: UnsafePointer<Int8>
    do {
      source = try NSString(contentsOfFile: file, encoding: String.Encoding.utf8.rawValue).utf8String!
    } catch {
      print("Failed to load vertex shader")
      return false
    }
    var castSource: UnsafePointer<GLchar>? = UnsafePointer<GLchar>(source)
    
    shader = glCreateShader(type)
    glShaderSource(shader, 1, &castSource, nil)
    glCompileShader(shader)

    glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &status)

    if status == 0 {
      var logLength: GLint = 0
      glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
      if logLength > 0 {
        let log = UnsafeMutablePointer<GLchar>.allocate(capacity:Int(logLength))
        glGetShaderInfoLog(shader, logLength, &logLength, log)
        NSLog("Shader compile log: \n%s", log)
        log.deallocate(capacity: Int(logLength))
      }
    }
    
    if status == 0 {
      glDeleteShader(shader)
      return false
    }
    return true
  }
  
  func linkProgram(_ prog: GLuint) -> Bool {
    var status: GLint = 0
    glLinkProgram(prog)
    
    //#if defined(DEBUG)
    //        var logLength: GLint = 0
    //        glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
    //        if logLength > 0 {
    //            var log = UnsafeMutablePointer<GLchar>(malloc(Int(logLength)))
    //            glGetShaderInfoLog(shader, logLength, &logLength, log)
    //            NSLog("Shader compile log: \n%s", log)
    //            free(log)
    //        }
    //#endif
    
    glGetProgramiv(prog, GLenum(GL_LINK_STATUS), &status)
    if status == 0 {
      return false
    }
    
    return true
  }
  
  func validateProgram(prog: GLuint) -> Bool {
    var logLength: GLsizei = 0
    var status: GLint = 0
    
    glValidateProgram(prog)
    glGetProgramiv(prog, GLenum(GL_INFO_LOG_LENGTH), &logLength)
    if logLength > 0 {
      var log: [GLchar] = [GLchar](repeating: 0, count: Int(logLength))
      glGetProgramInfoLog(prog, logLength, &logLength, &log)
      print("Program validate log: \n\(log)")
    }
    
    glGetProgramiv(prog, GLenum(GL_VALIDATE_STATUS), &status)
    var returnVal = true
    if status == 0 {
      returnVal = false
    }
    return returnVal
  }
}

