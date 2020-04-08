# No Face-Touch project

## Installation and Usage

### Website
[Offical app Website](https://sites.google.com/d/1qzfLlL8PLylVsKk7v1anWFwWKd_z00MN/p/136BS4jahodWvdjo-YWIOxO9dFwGnpBIq)

### APK
[Click here to download the APK file](https://github.com/sirslab/COVID-19-DoNTYF-wear/raw/master/app/build/outputs/apk/debug/app-debug.apk)

## TODOs
- [ ] Aggiungere file per salvataggio preferenze (Privacy, Soglia, Mano)
- [x] Mettere il testo della privacy scrollabile
- [ ] Aggiungere un bip
## Prova tommi
[![](https://mermaid.ink/img/eyJjb2RlIjoicGllIHRpdGxlIFBldHMgYWRvcHRlZCBieSB2b2x1bnRlZXJzXG5cdFwiRG9nc1wiIDogMzg2XG5cdFwiQ2F0c1wiIDogODVcblx0XCJSYXRzXCIgOiAxNVxuXHRcdFx0XHRcdCIsIm1lcm1haWQiOnsidGhlbWUiOiJkZWZhdWx0In0sInVwZGF0ZUVkaXRvciI6ZmFsc2V9)](https://mermaid-js.github.io/mermaid-live-editor/#/edit/eyJjb2RlIjoicGllIHRpdGxlIFBldHMgYWRvcHRlZCBieSB2b2x1bnRlZXJzXG5cdFwiRG9nc1wiIDogMzg2XG5cdFwiQ2F0c1wiIDogODVcblx0XCJSYXRzXCIgOiAxNVxuXHRcdFx0XHRcdCIsIm1lcm1haWQiOnsidGhlbWUiOiJkZWZhdWx0In0sInVwZGF0ZUVkaXRvciI6ZmFsc2V9)

## The idea behind the app
To help us stopping to touch our faces we developed a simple and free app that let your smartwatch vibrate and ring as soon as you get closer to your face. The face is detected by using a small cheap magnet at your necklace.  
The smartwatch is worn on the arm whose hand more frequently touches your face. We are using it on the left arm but you can choose the one you like. Of course we cannot alert if the hand without the smartwatch touches your face but we hope that preventing one hand only to touch our face can help us building safe habits for both hands. In any case for sure we reduce the risk by a factor 2. 

## WearOS app flow
We developed a WearOS standalone app that reads magnetometer measurements and detects the proximity with a magnet attached to a necklace or an ad-hoc accessory worn close to the face.
The app is composed of the following activities:
- Main activity: shows logos and collects users' agreements on using accelerometer and magnetometer data from the smartwatch
- Secondary activity: asks to the user which hand is wearing the smartwatch, then starts the calibration procedure. After the calibration, the app displays the norm of the magnetic field currently measured and provides alert whenever that value crosses a threshold. The user interface allows to manually adjust the threshold.

The calibration procedure fills a list with magnetometer measurements and takes the average as baseline value. Then, the user is asked to move his hand close to the magnetic necklace, in order to register the maximum value of magnetic field and 
automatically set a threshold equal to MAX*$1/3$.
The threshold scaling was defined empirically during the app debugging, any different suggestion to make the detection more robust will be taken into consideration.

After the calibration, the app estimates the hand orientation through accelerometer readings (for this reason we ask to the user where is he wearing the smartwatch). The app sends a vibration whenever the hand turns upward and the sensed magnetic field exceeds the current threshold.

Considering that the magnetic field shows substantial fluctutations in the enviroment, mostly due to EM sources and ferromagnetic materials, the baseline value is updated frequently. In particular, when the accelerometer data suggest that the hand is not pointing upward, the alerts (vibrations) are disabled and the magnetic field measurements are collected in the list to update the baseline value. 

## Block diagram

### Hand Selection Screen
![](Hand_choice_block.png)

### Calibration Screen
![](Block_calib_screen.png)
