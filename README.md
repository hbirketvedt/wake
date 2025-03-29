# wake
Macbooks sleep when the lid is closed (unless plugged in to an external monitor). To keep the Macbook awake we can use `pmset disablesleep`.

I made a convenience script `wake.sh` that disables sleep and automatically re-enables it when quit.

<br>

## `pmset disablesleep`
The `pmset` man pages have no mention of `disablesleep` but it does in fact disable sleep, even with a closed lid.

**WARNING:** The Macbook has reduced cooling ability while the lid is closed and could overheat in a confined space (such as a backpack).

Disable sleep
```
sudo pmset disablesleep 1
```

Enable sleep (default)
```
sudo pmset disablesleep 0
```

<br>

## `wake.sh`

The script simply wraps the above commands. It will disable sleep while running and re-enable when quit.

In addition, the script supports the following improvements:
- You can specify a timeout in hours, after which sleep will be automatically re-enabled.
- Sleep is also re-enabled on keypress, script termination, or terminal close.
- The script reads keypresses directly from the terminal device, ensuring correct behavior under `sudo`.
- You can install the script globally for convenient use.
- You can optionally remove the password requirement for `pmset`.

### Give executable permissions

The script needs [executable permission](https://support.apple.com/guide/terminal/make-a-file-executable-apdd100908f-06b3-4e63-8a87-32e71241bab4/2.10/mac/10.15)
```
chmod +x wake.sh
```

### Usage

Run it to disable sleep
```
sudo ./wake.sh
```

Pass a number of hours to automatically re-enable after that time
```
sudo ./wake.sh 2
```

Press any key or quit the script to re-enable sleep.

### *Make script global (optional)*

If you want to run the script from anywhere as a command, move it to `/usr/local/bin`
```
sudo mv wake.sh /usr/local/bin/wake
sudo chmod +x /usr/local/bin/wake
```

Run it anywhere
```
sudo wake
```

You can still use the timeout:
```
sudo wake 1
```

### *Remove password requirement (optional)*

The power management command `pmset` requires sudo to run. If you don't want to enter your password each time you can remove the password requirement for your user.

**WARNING:** Do this at your own risk as it obviously reduces security.

1. Open the sudo configuration editor in your terminal with `sudo visudo`
1. Add to the end of the file:
   ```
   <user> ALL=(ALL) NOPASSWD: /usr/bin/pmset
   ```
   Replace `<user>` with your username (you can check it with `whoami`)
1. Save changes with `:wq`

Run it without password
```
wake
```
