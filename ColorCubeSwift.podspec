
Pod::Spec.new do |s|

  s.name         = "ColorCubeSwift"
  s.version      = "1.1.0"
  s.summary      = "ColorCube port to swit"
  s.module_name  = "ColorCubeSwift"

  s.description  = <<-DESC

                  A port to swift of the original ColorCube project written in Objective-C
                  https://github.com/pixelogik/ColorCube

                  DESC

  s.homepage     = "https://github.com/YamiDaisuke/ColorCubeSwift"

  s.license      = { :type => "MIT" }

  s.authors      = {
    "Franklin Cruz" => "daisuke.sysoft@gmail.com",
  }

  s.platform     = :ios, "9.1"
  s.swift_version = '4.2'

  s.source = {
    :git => "https://github.com/YamiDaisuke/ColorCubeSwift.git",
    :tag => "v#{s.version}"
  }

  s.source_files  = "src/*.swift"

end
