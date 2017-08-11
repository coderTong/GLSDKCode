

Pod::Spec.new do |s|

  s.name         = "GLSDKCode"
  s.version      = "1.x.x-local"
  s.summary      = "GLSDKCode"

  s.description  = "GLSDKCode"

  s.homepage     = "https://github.com/coderTong/GLSDKCode"
  

  s.license      = "Commercial"
 
  s.author       = { "CodeTomWu" => "coderwutong@gmail.com" }
  

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/coderTong/GLSDKCode.git", :commit => "804d8052547c5fd166889eb61598e2940b8b332c" }


  s.source_files  = "GLSDKCode", "GLSDKCode/GLSDKCode/**/*.*"
  s.exclude_files = "GLSDKCodeTests"


  

  s.resources = "**/*.{fsh,vsh}"
  


  s.frameworks = "UIKit",  "QuartzCore", "OpenGLES", "MediaPlayer", "AudioToolbox", "AVFoundation", "CoreMedia", "CFNetwork"


  s.requires_arc = true




end
