## **Introduction**
**This mobile application** is designed to work for the Micro:bit device. The **Micro:bit Educational Foundation** is a nonprofit inspiring children globally to embrace digital skills through innovative hardware, software, and free educational resources. Originating from the **BBC's Make It Digital** initiative in 2014, they've impacted over **44 million young learners** in **60+ countries**, fostering diversity in STEM education and creating pathways to a brighter digital future. If you would like to learn more about Micro:bit, here is their website: [Micro:bit](https://microbit.org).

## **Purpose**:
This app facilitates seamless data collection using the Micro:bit device and a mobile device, enabling wireless data retrieval via Bluetooth and efficient data logging. Whether deployed in diverse environments or for varying durations, users can effortlessly set up their Micro:bit device and subsequently connect to the mobile app to gather all stored data.

## **Setup Instructions**:
The app itself will work without any additional setup, but this section will pertain to what you need to setup in the Makecode editor so the app can correctly interface with the Micro:bit device. Here is the link to the makecode editor: [Makecode Editor](https://makecode.microbit.org/#).

### **Step 1: Bluetooth Logger**
In your Makecode editor, you will have to add a new extension. 
When you create a new project, your screen will most likely look like this. Click the extensions button located in the middle of the screen. 
![Extensions Button](https://github.com/masongaller/IndependentStudy/assets/89870162/d538c34e-a725-44c3-a62a-275d9f2d205c)

Paste this GitHub link into the search bar at the top of the page and search: [GitHub Link](https://github.com/bsiever/pxt-blelog)
![GitHub Link Search](https://github.com/masongaller/IndependentStudy/assets/89870162/591752bf-1c22-4c1e-a980-5fb4e07abe5f)

The extension you are looking for should look like this. Click it.
![Extension Selection](https://github.com/masongaller/IndependentStudy/assets/89870162/88852758-a9b4-4fc9-b986-6eba481baa4f)

You may get this message, just click **Remove extension(s)** and add **pxt-blelog**.
![Extension Removal](https://github.com/masongaller/IndependentStudy/assets/89870162/e5c179db-bbfd-4465-9180-c9489196f27c)

You will now have two additional extensions on your screen. One is named **"Data Logger"** and the other is **"Log Bluetooth"**.

### **Step 2: Setup Data Logger**
There are 3 necessary blocks to get started.
Under the **Log Bluetooth** tab, the **Bluetooth Data Logger Service** block. The Bluetooth data logger service sets up the Micro:bit device to be compatible with Bluetooth. It will also give the device a name so we can easily identify it on the app. If you click the plus button on the block, it will give you the additional option of adding a passphrase. This passphrase can be set to anything you would like, but in order to connect to the Micro:bit, you will be prompted with this passphrase.
![Bluetooth Data Logger](https://github.com/masongaller/IndependentStudy/assets/89870162/7ac778c8-3d7b-4a4c-80cd-0e319111b1a2)

Under the **Data Logger** tab, the **Set Columns** and **Log Data** blocks. 
The **Set Columns** block is the place for you to set up your variable names as you would like them to appear in the app. The plus and minus buttons allow you to add and remove as many variables as you would like. 
The **Log Data** block is what actually logs the input data. In the first empty space, you will select one of the variable names you created with the Set Columns block. In the second field, you specify what you want the value to be. Again, you can add and remove as many variables that you want to log using the plus and minus button. Logging additional variables that you have not already set up with Set Columns may lead to unintended side effects.
![Data Logger Setup](https://github.com/masongaller/IndependentStudy/assets/89870162/a68df163-5af1-4d29-81e5-16f4aa2f7c18)

Here is an example Makecode that I have created. It is recommended to put the data logger service and set column blocks in your **on start method block**. You can put the log data block in any configuration you wish depending on your data collection needs. In this example, I have the Micro:bit logging the Light Level and Temperature every 10 seconds.
![Example Makecode](https://github.com/masongaller/IndependentStudy/assets/89870162/e9af77dd-fe5e-483a-9e4c-3636c87143ed)

Feel free to mess around with any of the other blocks in the data logger to configure to your needs! When you are finished making your program, load it into the Micro:bit.

### **Step 3: Launch The App!**
Once the app is launched, you can click the scan button on the home screen which will look for nearby Bluetooth devices. Since we used the Bluetooth data logger service, the name of your Micro:bit should look something like this -> **uBit [NAME]**. Where **NAME** is randomly generated for your device. Ex. Mine says **uBit [Zovig]**. Everything is now setup and the data should now be streaming into the app.
