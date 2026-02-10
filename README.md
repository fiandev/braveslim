# braveslim

A powerful script to strip Brave Browser of bloated features, disable telemetry, and enhance privacy. Supports **Linux** and **Windows**.

## Features

- **Telemetry Blocking**: Blocks known Brave telemetry domains via `/etc/hosts` (Linux) or `C:\Windows\System32\drivers\etc\hosts` (Windows).
- **Privacy Enforcement**: Disables Brave Rewards, Wallet, Ads, News, VPN, Leo AI, P3A, and usage pings.
- **Multi-Profile Support**: Automatically detects and applies settings to **all** Brave user profiles.
- **Debloating**: Removes unwanted UI elements like the Rewards button and sidebar icons.
- **Backup**: Creates timestamped backups of your `Preferences` and `hosts` file before making changes.

## Linux

### Prerequisite

Make sure you have `curl` and `jq` installed on your system.

```sh
# debian, ubuntu, mint
sudo apt install curl jq

# arch, manjaro
sudo pacman -S curl jq

# fedora, red hat
sudo dnf install curl jq
```

### Run Script

<<<<<<< HEAD
<img width="706" height="490" alt="Screenshot_20260210_071057" src="https://github.com/user-attachments/assets/4e30d544-c9ef-4f1e-b9b1-4f84b5af0f48" />

Just copy and paste the following command into your terminal:
=======
Copy and paste the following command into your terminal:
>>>>>>> 17065ae (feat(windows): add debloat script and usage instructions)

```sh
curl https://raw.githubusercontent.com/fiandev/braveslim/refs/heads/master/main.sh | sh
```

For full telemetry blocking (hosts file modification), run the script directly with `sudo`:

```sh
wget https://raw.githubusercontent.com/fiandev/braveslim/refs/heads/master/main.sh
chmod +x main.sh
sudo ./main.sh
```

## Windows Usage

1.  Download the **[`main.bat`](https://raw.githubusercontent.com/fiandev/braveslim/refs/heads/master/main.bat)** file.
2.  Right-click `main.bat` and select **Run as Administrator**.
3.  Follow the prompts.

What it does on Windows:

- Closes running Brave instances.
- Modifies `Preferences` files for all profiles using PowerShell.
- Blocks telemetry domains in the Windows hosts file.
- Creates a private shortcut on your Desktop: **Brave (Private)**.
