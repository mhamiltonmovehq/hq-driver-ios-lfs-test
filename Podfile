platform :ios, '8.0'

# Uncomment the next line if you're using Swift or would like to use dynamic frameworks
use_frameworks!

# Use existing workspace
workspace 'Survey'

def mm_pods
    # Pods for Mobile Mover Enterprise
    pod 'ImagePicker'
    pod 'Lightbox'
end

target 'Mobile Mover Enterprise' do
    mm_pods
end

target 'Mobile Mover' do
    mm_pods
end

# Make sure every pod is set to the latest SWIFT_VERSION
#post_install do |installer|
#    installer.pods_project.targets.each do |target|
#        target.build_configurations.each do |config|
#            config.build_settings['SWIFT_VERSION'] = '4.2'
#        end
#    end
#end
