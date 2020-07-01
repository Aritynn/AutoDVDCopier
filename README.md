# AutoDVDCopier
Drag VIDEO_TS folder from DVD onto script to automatically copy to your hard drive, check for integrity, eject the disc, take screenshots and output mediainfo.

## Usage
- Install and add folder path of the executables to the Windows Path
  - FFMpeg (counts total frames and extracts screens)
  - MediaInfo (Outputs mediainfo of .VOB and .IFO files)
  - TeraCopy (Copies files from disc with integrity verification)
  - NirCmd (Ejects disc when files have finished copying)
- Make sure Teracopy has "Always test after copy" enabled to allow integrity checking
- Set the output directory, screens directory and info directory
- Drag VIDEO_TS folder from DVD onto batch file and follow the instructions

## Naming
The script extracts the name of the disc and will create a folder on the hard drive with this name to place the VIDEO_TS folder into. If it already exists, it will ask you for a suffix to add. If you leave the suffix blank, it will bring up TeraCopy's menu to ask if you want to overwrite, skip, etc.

## Screenshots
The script will try and read ```VIDEO_TS\VTS_0X_1.VOB``` AND ```VIDEO_TS\VTS_0X_0.VOB``` (with X going from 1 through 9) which are usually the first episode and menu respectively while making sure that the frame count is higher than the minimum allowed. It will then generate 3 lossless screenshots from the menu and 11 from the episode.

## Settings

- ```transferredFolderPath``` The folder where the VIDEO_TS folder will be copied to
- ```enableFolderCopy``` Enables/Disables copying of the VIDEO_TS folder (useful for taking screenshots without first copying)
- ```outputDirectory``` The folder where the screenshots and mediainfo are saved
- ```screensDirectory``` The name of the screens folder inside the outputDirectory
- ```infoDirectory``` The name of the MediaInfo folder inside the outputDirectory
- ```enableScreenshots``` Enables/Disables screenshots generation
- ```enableIFOMediaInfo``` Enables/Disables MediaInfo generation of the largest IFO file
- ```enableVOBMediaInfo``` Enables/Disables MediaInfo generation for the VOB which the screenshots are generated from
- ```amountOfMenuScreens``` Amount of screenshots to take of the menu
- ```amountOfEpisodeScreens``` Amount of screenshots to take of the first episode it finds
- ```minAmountOfMenuFrames``` Minimum amount of frames in the VOB file to be considered as a menu when finding the menu
- ```minAmountOfEpisodeFrames``` Minimum amount of frames in the VOB file to be considered as an episode when finding the menu

## Tips
- Run ```Windows + R``` and type ```shell:sendto```. Place the batch file in the folder that opens and give the file a good name. Then, after inserting a disc, right-click the VIDEO_TS folder and click ```Send to -> Batch file``` for easy access.
- If only screenshots or MediaInfo are needed, set ```enableFolderCopy``` to ```false```. All features can be enabled or disabled.

## Disc encryption
Normal retail DVDs include encryption. This script does not decrypt the DVDs. AnyDVD HD and DVDFab Passkey are examples of software that will decrypt the DVD for you. You will most likely need software like this to copy retail discs correctly.
