<!-- @format -->

# MacOS clipboard manager

## Project information

This project was inspired by the Clipboard History (Clipboard Manager) feature in Microsoft Windows.

## Functionality

The core functionality is based on being able to view your MacOS clipboard history.

When you start the script, it listens for clipboard activity. Every time you copy something using **Command + C**, the script saves it. When you press **Command + Shift + V**, a dialog pops up displaying the last 10 copied items. Click on the text you need, press **Ok** and then paste it using Command + V.

## Running it on your device

### 1. Installing Git

If Git is not already installed on your system, follow the instructions below. Otherwise, you can skip this step.

- Install Homebrew package manager with this command or visit their website for further information (<https://brew.sh>)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

```bash
brew --version
```

- Install Git with Homebrew, and check the version

```bash
brew install git
```

```bash
git version
```

### 2. Cloning the repository

- Open the terminal and run the following command to clone the repository

```bash
git clone https://github.com/LorincziMatyas12/macbook-clipboard-history.git
```

### 3. Using the program (script)

- Run the following command to grant execute permissions to your user. You only have to do this once. (Navigate to the project folder with **cd** command, then you don't have to include the **/path/to/** in the following commands)

```bash
chmod u+x /path/to/clipboard_history.sh
```

- You can list all the files in the project folder with **ls -l**, you should see something like **-rwxr--r--** permissions.

- Running the script: Each time you restart your computer, you will need to start the program manually.

```bash
nohup /path/to/macos-clipboard-history/clipboard_history.sh --start &
```

- Clear your clipboard history:

```bash
./path/to/clipboard_history.sh --clear
```

- To see the clipboard window run the following command:

```bash
./path/to/clipboard_history.sh --show
```

- Stopping the script:

```bash
./path/to/clipboard_history.sh --stop
```

### 4. Creating a Shortcut to View Clipboard History

- Open the **Automator** app on your Mac
- Create a **Workflow**
- Add a **"Run Shell Script"** action to the workflow
- Ensure the following setting is applied in the workflow:
  - **"Workflow receives 'no input' in 'any application'"**
- For **"Run Shell Script"**, set:
  - **Shell:** `/bin/bash`
  - **Pass input:** `to stdin`
- Paste the following command into the script box:

```bash
/path/to/clipboard_history.sh --show
```

- Click the **Play** button to test it. You should see the clipboard history window
- Save the workflow
- Open **System Settings > Keyboard > Keyboard Shortcuts...**
- Navigate to **Services > General > Name_Of_The_Workflow**
- Check the checkbox, then double-click the darker **"none"** box
- Press **Command + Shift + V** to set the shortcut, then click **Done**

### 5. Possible fixes for errors

- Grant **"Full Disk Access"** for Terminal and Automator in your system settings
  - Open **System Settings** and navigate to **Privacy & Security > Full Disk Access**
  - Click on the **"+"** button and select Automator and Terminal

## Another version of the code

- This version of the code is written in apple script.
- Does the same thing but it is less bash script and more apple script.

### Using the second version of the code

- Add executable access to **"clipboard_history.appleascript"** with command:

```bash
chmod u+x clipboard_history.appleascript
```

- Run the script with:

```bash
osascript clipboard_history.applescript start
```

- Show clipboard:

```bash
osascript clipboard_history.applescript show
```

- Clear clipboard's content:

```bash
osascript clipboard_history.applescript clear
```

- Stop clipboard:

```bash
osascript clipboard_history.applescript stop
```
