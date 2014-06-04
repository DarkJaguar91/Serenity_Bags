#Serenity_Bags
##Wildstar bag replacement addon:

###Details:
Serenity_Bags is an addon to replace the standard bag addon.

####Features:
* Sorts items into seperate bag windows according to the Family Names appointed to the items by Wildstar Developers
* Adds shortcut key for salvage item: CTRL + Middle Mouse Button
* Ability to create your own Family Name for certain items thus allowing you to create a new bag for items you want to keep (Eg. A seperate bag window for Healing Gear)
  * Shortcut Key: ALT + Middle Mouse Button

###Downloads:
1. Use the Download Zip button on the left of the screen in the GitHub main page for Serenity_Bags
2. [Box Download](https://app.box.com/s/04tub2bdsqxsmtpf5jak "Serenity_Bags Addon Zip File")

###Install:
1. Download the Zip file from one of the links above
2. Unzip into its own folder (Should be Serenity\_Bags or Serenity\_Bags-master)
3. Copy that folder to: ```C:\Users\<your user name>\AppData\Roaming\NCSOFT\Wildstar\Addons\```
  * To get to: ```C:\Users\<Your user name>\AppData\Roaming\``` Type ```%APPDATA%``` into the "Run" program or your file explorers path
  * Note: The Addons folder in the path may not exist if you have not installed an addon before. Just create a new folder in the ```C:\Users\<your user name>\AppData\Roaming\NCSOFT\Wildstar\``` folder called ```Addons```
4. Start game or type ```/reloadui``` in chat

###ChangeLog:

####As of 03/06/2014:
* Added an Item Preview form to addon: I found out that the item preview form is part of the Inventory addon for carbines default UI and thus needed to add one.
* Fixed an issue were it tries to refresh the inventory without certain objects being loaded into the game yet. (May still be a few more that need be fixed)

####As of 02/06/2014:
* Changed the salvage menu system (Salvage an item by pressing: CTRL + Middle Mouse Button)
* Added a feature that allows you to set items to a Family name you choose: ALT + Middle Mouse Button on an item opens otions to create your own Bag Name for the chosen item. If you already have your own bag names, they will appear in a auto complete window to the right (click a name and it will auto type into the edit box)
* Efficiency corrections

####As of 01/06/2014.V3:
* Changed the arrangement algorithm to stop bags from moving off screen (Future updates to come) (going to add container with scroll bar)

####As of 01/06/2014.V2:
* Added empty bag slot indicator on main bag

####As of 01/06/2014:
* ~~Fixed issues with the salvaging (did not close the salvage request box and gave cannot be salvages issues when recliking salvage button)~~ 
* Added Auto sell junk feature (automatically sells junk to vendor when a vendor is opened)
* Correctly marks items as seen when closed now
* Efficiency corrections

####As of 31/05/2014:
* Currently the bag does not stay were you last moved it after a relog/reload (will fix ASAP)
* ~~There is no Salvage all button as of yet (but to salvage all you have to do is ctrl click and item (a confirm window does appear))~~
* Delete an item by draging and droping the item anywhere but a bag slot
* Right clicking the item does the normal responses
* To move the bag, move the window by your currency/bag icons
* Open trade skill items with the normal btn (placed between currency and bag icons)

