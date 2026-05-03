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
        '"iPhone Developer"': '"Apple Distribution"',
        'iPhone Developer': 'Apple Distribution',
        'PROVISIONING_PROFILE_SPECIFIER = "";': 'PROVISIONING_PROFILE_SPECIFIER = "goldsham";'
    }
    
    for old, new in replacements.items():
        content = content.replace(old, new)
        
    with open(path, 'w') as f:
        f.write(content)
    print("Patched project.pbxproj successfully")

patch_pbxproj('frontend/ios/Runner.xcodeproj/project.pbxproj')
