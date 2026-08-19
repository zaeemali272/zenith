#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 whois openssl git
import os
import sys
import re
import getpass
import subprocess
import termios
import tty

def generate_sha512_hash(password):
    try:
        res = subprocess.run(["openssl", "passwd", "-6", password], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        if res.stdout.strip():
            return res.stdout.strip()
    except Exception:
        pass
    
    try:
        res = subprocess.run(["mkpasswd", "-m", "sha-512", password], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        if res.stdout.strip():
            return res.stdout.strip()
    except Exception:
        pass

    try:
        import crypt
        return crypt.crypt(password, crypt.mksalt(crypt.METHOD_SHA512))
    except Exception:
        pass

    raise RuntimeError("Could not find a tool (openssl/mkpasswd/crypt) to hash the password!")

def get_timezones():
    zones = []
    base_path = '/usr/share/zoneinfo'
    if not os.path.exists(base_path):
        return [
            "America/New_York", "America/Los_Angeles", "America/Chicago", "America/Denver",
            "Europe/London", "Europe/Paris", "Europe/Berlin", "Europe/Rome", "Europe/Madrid",
            "Asia/Karachi", "Asia/Kolkata", "Asia/Tokyo", "Asia/Shanghai", "Asia/Singapore",
            "Australia/Sydney", "Africa/Cairo", "Africa/Johannesburg", "UTC"
        ]
    
    for root, dirs, files in os.walk(base_path):
        for file in files:
            full_path = os.path.join(root, file)
            if os.path.islink(full_path):
                continue
            rel_path = os.path.relpath(full_path, base_path)
            parts = rel_path.split('/')
            
            if any(p in ['posix', 'right', 'SystemV', 'Etc', 'US'] for p in parts):
                continue
                
            regions = {'Africa', 'America', 'Antarctica', 'Arctic', 'Asia', 'Atlantic', 'Australia', 'Europe', 'Indian', 'Pacific'}
            if parts[0] in regions:
                zones.append(rel_path)
                
    return sorted(list(set(zones)))

def input_with_autocomplete(prompt, default="", suggestions=None):
    if suggestions is None:
        suggestions = []
    
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    
    buffer = ""
    try:
        tty.setraw(fd)
        while True:
            match = ""
            if buffer:
                for s in suggestions:
                    if s.lower().startswith(buffer.lower()):
                        match = s
                        break
            
            sys.stdout.write("\r\033[K" + prompt + buffer)
            
            if match and len(match) > len(buffer):
                suggestion_suffix = match[len(buffer):]
                sys.stdout.write("\033[90m" + suggestion_suffix + "\033[0m")
                sys.stdout.write("\b" * len(suggestion_suffix))
            elif not buffer and default:
                sys.stdout.write("\033[90m" + default + "\033[0m")
                sys.stdout.write("\b" * len(default))
                
            sys.stdout.flush()
            
            ch = sys.stdin.read(1)
            
            if ch in ('\r', '\n'):
                if not buffer and default:
                    buffer = default
                elif match and buffer.lower() == match.lower():
                    buffer = match
                sys.stdout.write("\n")
                sys.stdout.flush()
                return buffer
            elif ch in ('\x7f', '\x08'):
                if len(buffer) > 0:
                    buffer = buffer[:-1]
            elif ch == '\t':
                if match:
                    buffer = match
            elif ch == '\x1b':
                next1 = sys.stdin.read(1)
                next2 = sys.stdin.read(1)
                if next1 == '[':
                    if next2 == 'C':
                        if match:
                            buffer = match
            elif ord(ch) >= 32 and ord(ch) <= 126:
                buffer += ch
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

def get_user_from_vars():
    vars_path = "vars.nix"
    if os.path.exists(vars_path):
        with open(vars_path, "r") as f:
            content = f.read()
        match = re.search(r'user\s*=\s*"([^"]*)";', content)
        if match:
            return match.group(1)
    return getpass.getuser()

def sync_repo(target_dir, repo_url):
    repo_name = os.path.basename(target_dir)
    if not os.path.exists(target_dir):
        print(f"Cloning {repo_name} into {target_dir}...")
        try:
            subprocess.run(["git", "clone", repo_url, target_dir], check=True)
            print(f"✓ Cloned {repo_name} successfully.")
        except Exception as e:
            print(f"⚠️  Failed to clone {repo_name}: {e}")
    else:
        print(f"Updating {repo_name} in {target_dir} via git pull...")
        try:
            subprocess.run(["git", "-C", target_dir, "pull"], check=True)
            print(f"✓ Updated {repo_name} successfully.")
        except Exception as e:
            print(f"⚠️  Failed to pull {repo_name}: {e}")

def main():
    print("=== Zenith NixOS Installer Configuration ===")
    
    setup_vars = input_with_autocomplete("Do you want to setup/modify user and system variables? (y/N): ", default="n", suggestions=["y", "n", "yes", "no"])
    
    if setup_vars.lower() in ["y", "yes"]:
        # 1. Hardware Configuration Generation
        print("\n[1/4] Detecting & Generating NixOS hardware configuration...")
        hardware_path = "hosts/desktop/hardware-configuration.nix"
        os.makedirs(os.path.dirname(hardware_path), exist_ok=True)
        
        system_hw_config = "/etc/nixos/hardware-configuration.nix"
        if os.path.exists(system_hw_config):
            try:
                with open(system_hw_config, "r") as src, open(hardware_path, "w") as dst:
                    dst.write(src.read())
                print(f"✓ Automatically imported active system hardware config from {system_hw_config}")
            except Exception as e:
                print(f"⚠️ Could not copy system hardware config: {e}")
        else:
            try:
                is_root = (os.geteuid() == 0)
                cmd = ["nixos-generate-config", "--show-hardware-config"] if is_root else ["sudo", "nixos-generate-config", "--show-hardware-config"]
                result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
                with open(hardware_path, "w") as f:
                    f.write(result.stdout)
                print(f"✓ Generated fresh hardware configuration for this machine at {hardware_path}.")
            except Exception as e:
                print(f"⚠️  Could not generate hardware configuration: {e}")
                print("Continuing with existing hardware-configuration.nix...")

        # 2. Variable Gathering
        print("\n[2/4] Please enter the installation variables (Press Tab or Right Arrow to autocomplete suggestions/defaults):")
        
        timezones = get_timezones()
        gpus = ["intel", "amd", "nvidia"]
        locales = ["en_US.UTF-8", "en_GB.UTF-8", "de_DE.UTF-8", "fr_FR.UTF-8"]
        layouts = ["us", "uk", "fr", "de", "es"]
        
        user = input_with_autocomplete("Username: ", default=getpass.getuser())
        fullName = input_with_autocomplete("Full Name: ", default=getpass.getuser())
        email = input_with_autocomplete("Email: ", default="")
        hostname = input_with_autocomplete("Hostname: ", default="nixos")
        timeZone = input_with_autocomplete("Timezone/Country/City: ", default="Asia/Karachi", suggestions=timezones)
        locale = input_with_autocomplete("Locale: ", default="en_US.UTF-8", suggestions=locales)
        keyboardLayout = input_with_autocomplete("Keyboard Layout: ", default="us", suggestions=layouts)
        gpu = input_with_autocomplete("GPU (intel/amd/nvidia): ", default="intel", suggestions=gpus)
        
        # Password Prompt
        password = ""
        while not password:
            password = getpass.getpass("Enter password for user account: ")
            if not password:
                print("Password cannot be empty!")
                
        print("Hashing password (SHA-512)...")
        password_hash = generate_sha512_hash(password)
        
        # 3. Replacing variables in vars.nix
        print("\n[3/4] Updating vars.nix...")
        vars_path = "vars.nix"
        if not os.path.exists(vars_path):
            print(f"❌ Error: {vars_path} not found!")
            sys.exit(1)
            
        with open(vars_path, "r") as f:
            content = f.read()
            
        replacements = {
            "user": user,
            "fullName": fullName,
            "email": email,
            "hostname": hostname,
            "timeZone": timeZone,
            "locale": locale,
            "keyboardLayout": keyboardLayout,
            "gpu": gpu
        }
        
        missed = []
        for var, val in replacements.items():
            pattern = re.compile(rf'({var}\s*=\s*")[^"]*(";)')
            content, n = pattern.subn(rf'\g<1>{val}\g<2>', content)
            if n == 0:
                missed.append(var)

        # The password hash belongs in vars.nix, which is where user.nix reads it
        # from (`hashedPassword = vars.hashedPassword;`). This used to regex
        # modules/core/user.nix for `hashedPassword = "..."` -- a literal that does
        # not appear in that file -- so the substitution matched nothing, and the
        # script printed a tick anyway. Anyone who ran the installer was left on the
        # fallback password while being told their own had been set.
        if re.search(r'hashedPassword\s*=\s*"', content):
            content = re.sub(r'(hashedPassword\s*=\s*")[^"]*(";)',
                             r'\g<1>' + password_hash + r'\g<2>', content)
        else:
            content = re.sub(r'\{',
                             '{\n  hashedPassword = "' + password_hash + '";',
                             content, count=1)

        if missed:
            print("WARNING: could not set in vars.nix: " + ", ".join(missed))

        with open(vars_path, "w") as f:
            f.write(content)

        # Read it back and prove it, instead of trusting the regex.
        with open(vars_path) as f:
            written = f.read()
        if password_hash in written:
            print("OK: vars.nix updated, password hash written")
        else:
            print("ERROR: password hash was NOT written to vars.nix. You would be "
                  "left on the fallback password; set hashedPassword by hand.")
            sys.exit(1)

    else:
        print("\nSkipping user and system variables setup.")
        user = get_user_from_vars()

    # Synchronize repositories (clone if absent, git pull if present)
    print(f"\nSynchronizing dotfiles and shell repositories for user '{user}'...")
    user_zenith_dir = f"/home/{user}/zenith"
    os.makedirs(user_zenith_dir, exist_ok=True)

    sync_repo(os.path.join(user_zenith_dir, "zenith-shell"), "https://github.com/zaeemali272/zenith-shell.git")
    sync_repo(os.path.join(user_zenith_dir, "Hyprland-dots"), "https://github.com/zaeemali272/Hyprland-dots.git")

    # Ensure ~/.config symlinks point to the writable cloned repos
    config_dir = f"/home/{user}/.config"
    os.makedirs(config_dir, exist_ok=True)

    hypr_link = os.path.join(config_dir, "hypr")
    quickshell_link = os.path.join(config_dir, "quickshell")

    if not os.path.exists(hypr_link) and not os.path.islink(hypr_link):
        os.symlink(os.path.join(user_zenith_dir, "Hyprland-dots"), hypr_link)
        print("✓ Created symlink ~/.config/hypr -> ~/zenith/Hyprland-dots")

    if not os.path.exists(quickshell_link) and not os.path.islink(quickshell_link):
        os.symlink(os.path.join(user_zenith_dir, "zenith-shell"), quickshell_link)
        print("✓ Created symlink ~/.config/quickshell -> ~/zenith/zenith-shell")

    print("\nSetup complete. Ready to proceed with build/switch.")

if __name__ == "__main__":
    main()
