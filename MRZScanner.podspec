Pod::Spec.new do |s|
    s.name             = 'MRZScanner'
    s.version          = '1.0.0'
    s.summary          = 'Library for scanning documents via MRZ using  Vision API'

    s.homepage         = 'https://github.com/KosyanMedia/MRZScanner'
    s.license          = 'MIT'
    s.author           = 'Roman Mazeev'
    s.source           = { :git => 'https://github.com/KosyanMedia/MRZScanner.git', :tag => s.version.to_s }

    s.swift_version = '5.7'

    s.ios.deployment_target = '13.0'
    s.watchos.deployment_target = '6.0'
    s.osx.deployment_target = '10.15'
    s.tvos.deployment_target = '13.0'

    s.source_files = 'Sources/**/*.swift'

    s.dependency 'MRZParser'

end