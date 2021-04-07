platform :ios, '11.0'

# Uncomment the next line if you're using Swift or would like to use dynamic frameworks
use_frameworks!

# Use existing workspace
workspace 'HQ Driver'

def mm_pods
    # Pods for Mobile Mover Enterprise
    pod 'ImagePicker'
    pod 'Optik'
#    pod 'AFNetworking', '~> 3.2.1' #4.0+ requires min of iOS 9
end

target 'HQ Driver Simulator' do
    project 'HQ Driver'
    mm_pods
end

target 'HQ Driver' do
    project 'HQ Driver'
    mm_pods
end

# Make sure every pod is set to the latest SWIFT_VERSION
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '5.0'
        end
    end
end
