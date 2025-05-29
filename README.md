# own_conky
Custom made conky configuration for linux systems

Peace people on the internet!

I wanted to make a custom configured and styled conky system monitor for my desktop, i was amazed by the stuff on then net i saw, i put much effort into that shit lol.

*UPDATE* 2025.05.29.

-the script supports notebooks on fully functionally lol i dont have desktop currently so working on the special parts like fan speed etc.
-working with nvidia GPUs currently + AMD / Intel CPUs

*REQUIREMENTS:*

-nbfc (for notebook users displaying fan speeds, and actually a useful shit to control fans under linux i love it on my acer nitro 5)

*sudo apt install nbfc-linux*

go for sudo nbfc config -r for recomended configs or -l for a big list you can pick from

*nbfc config -a "Acer Nitro AN515-57"* -notebook type \n
*nbfc set -s 10* -for 10% speed \n
*nbfc set -a* -for auto \n

-conky (obviously lol)

*sudo apt-get install conky-all*

-make a folder called *conky* in /home/.config/

-paste all the files into the folder

-paste *startconky.sh* script for starting conky on terminal command name the file whatever you want for the command

*cd /usr/local/bin*

the script make a file readable for conky to display the cpu wattage real time then runs the left and right side of conky

if you are into autostart just make a systemdeamon in the /etc/systemd/system/ folder, enable and start it, hit reboot and pray for everything goes well

The icon on the top left changes based on your system, if its something special or i was just too lazy to write down your distro you can edit the script at your own risk lol, otherwise the good old default penguin guy will appear.

The display supports CPUs up to 8 cores, more will not fit with the 16 threads for the rings XD, 5 case fans beside the cpu and gpu RPMs, 4 disks on the right displaying everything, the network is changing based on Wifi or Ethernet, showing the SSID and signal % aswell...

The script and the readme is in progress might update sooner or later (or never again lmao)

See the screenshots below to check the result

![image](https://github.com/user-attachments/assets/ef6501cd-644d-4100-ae94-af68cbb493be)


-DONE-
