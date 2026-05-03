import os

def patch_pbxproj(path):
    if not os.path.exists(path):
        print(f"File not found: {path}")
        return
    
    with open(path, 'r') as f:
        content = f.read()
    
    # Force Manual signing and Distribution identities
    replacements = {
        'ProvisioningStyle = Automatic;': 'ProvisioningStyle = Manual;',
        'CODE_SIGN_STYLE = Automatic;': 'CODE_SIGN_STYLE = Manual;',
        'CODE_SIGN_IDENTITY = "iPhone Developer";': 'CODE_SIGN_IDENTITY = "Apple Distribution";',
        'CODE_SIGN_IDENTITY = "iPhone Distribution";': 'CODE_SIGN_IDENTITY = "Apple Distribution";',
        'CODE_SIGN_IDENTITY = "";': 'CODE_SIGN_IDENTITY = "Apple Distribution";',
        'PROVISIONING_PROFILE_SPECIFIER = "";': 'PROVISIONING_PROFILE_SPECIFIER = "goldsham";',
        'DEVELOPMENT_TEAM = "";': 'DEVELOPMENT_TEAM = "ULCAFL67U6";'
    }
    
    # Generic replacement for any iPhone Developer string to Apple Distribution
    content = content.replace('"iPhone Developer"', '"Apple Distribution"')
    content = content.replace('iPhone Developer', 'Apple Distribution')
    
    for old, new in replacements.items():
        content = content.replace(old, new)
        
    with open(path, 'w') as f:
        f.write(content)
    print("Patched project.pbxproj successfully")

patch_pbxproj('frontend/ios/Runner.xcodeproj/project.pbxproj')
