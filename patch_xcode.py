import os
import re

def patch_pbxproj(path):
    if not os.path.exists(path):
        print(f"File not found: {path}")
        return
    
    with open(path, 'r') as f:
        content = f.read()
    
    print("Patching project.pbxproj with Regex...")
    
    # 1. Force Manual signing everywhere
    content = re.sub(r'ProvisioningStyle = .*?;', 'ProvisioningStyle = Manual;', content)
    content = re.sub(r'CODE_SIGN_STYLE = .*?;', 'CODE_SIGN_STYLE = Manual;', content)

    # 2. Force Apple Distribution identity
    content = re.sub(r'CODE_SIGN_IDENTITY = ".*?";', 'CODE_SIGN_IDENTITY = "Apple Distribution";', content)
    content = re.sub(r'CODE_SIGN_IDENTITY\[sdk=iphoneos\*\] = ".*?";', 'CODE_SIGN_IDENTITY[sdk=iphoneos*] = "Apple Distribution";', content)

    # 3. Force the specific provisioning profile
    content = re.sub(r'PROVISIONING_PROFILE_SPECIFIER = ".*?";', 'PROVISIONING_PROFILE_SPECIFIER = "goldsham";', content)

    # 4. Force the Development Team
    content = re.sub(r'DEVELOPMENT_TEAM = ".*?";', 'DEVELOPMENT_TEAM = "ULCAFL67U6";', content)

    # 5. Clean up any leftover Developer strings
    content = content.replace('"iPhone Developer"', '"Apple Distribution"')
    content = content.replace('iPhone Developer', 'Apple Distribution')
        
    with open(path, 'w') as f:
        f.write(content)
    print("Patched project.pbxproj successfully using Regex")

patch_pbxproj('ios/Runner.xcodeproj/project.pbxproj')
