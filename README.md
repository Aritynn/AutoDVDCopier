# AutoDVDCopier
Drag VIDEO_TS folder from DVD onto script to automatically copy to your hard drive with error-checking, eject the disc, take screenshots and output mediainfo.

## Usage
- Install and add folder path of the executables to the Windows Path
  - FFMpeg (counts total frames and extracts screens)
  - MediaInfo (Outputs mediainfo of .VOB and .IFO files)
  - NirCmd (Ejects disc when files have finished copying)
- Set the desired settings (including the output directories)
- Drag VIDEO_TS folder from DVD onto batch file and follow the instructions

## Naming
The script extracts the name of the disc and will create a folder on the hard drive with this name to place the VIDEO_TS folder into. If it already exists, it will ask you for a suffix to add. Depending on what suffix you add, if files still exist, it will not overwrite existing files (uses the included Robocopy command).

## Screenshots
The script will try and read ```VIDEO_TS\VTS_0X_1.VOB``` AND ```VIDEO_TS\VTS_0X_0.VOB``` (with X going from 1 through 9) which are usually the first episode and menu respectively while making sure that the frame count is higher than the minimum allowed. It will then generate 3 lossless screenshots from the menu and 11 from the episode.

## Settings

### Paths
- ```transferredFolderPath``` The folder where the VIDEO_TS folder will be copied to
- ```outputDirectory``` The folder where the screenshots and mediainfo are saved
- ```screensDirectory``` The folder structure where the screens are saved to
- ```infoDirectory``` The folder structure where the MediaInfo, Robocopy log file, and temp.txt file are saved to

### Enabling/Disabling
- ```enableFolderCopy``` Enables/Disables copying of the VIDEO_TS folder (useful for taking screenshots without first copying)
- ```enableScreenshots``` Enables/Disables screenshots generation
- ```enableIFOMediaInfo``` Enables/Disables MediaInfo generation of the largest IFO file
- ```enableVOBMediaInfo``` Enables/Disables MediaInfo generation for the VOB which the screenshots are generated from

### Amount of Screenshots
- ```amountOfMenuScreens``` Amount of screenshots to take of the menu
- ```amountOfEpisodeScreens``` Amount of screenshots to take of the first episode it finds

### Minimum amount of frames to be considered
- ```minAmountOfMenuFrames``` Minimum amount of frames in the VOB file to be considered as a menu when finding the menu
- ```minAmountOfEpisodeFrames``` Minimum amount of frames in the VOB file to be considered as an episode when finding the menu

## Tips
- Run ```Windows + R``` and type ```shell:sendto```. Place the batch file in the folder that opens and give the file a good name. Then, after inserting a disc, right-click the VIDEO_TS folder and click ```Send to -> Batch file``` for easy access.
- If only screenshots or MediaInfo are needed, set ```enableFolderCopy``` to ```false```. All features can be enabled or disabled.

## Disc encryption
Normal retail DVDs include encryption. This script does not decrypt the DVDs. AnyDVD HD and DVDFab Passkey are examples of software that will decrypt the DVD for you. You will most likely need software like this to copy retail discs correctly.
