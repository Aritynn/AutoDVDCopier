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
The script will try and read ```VIDEO_TS\VTS_01_1.VOB``` AND ```VIDEO_TS\VTS_01_0.VOB``` which are usually the first episode and menu respectively. It will then generate 3 lossless screenshots from the menu and 11 from the episode.

## Disc encryption
Normal retail DVDs include encryption. This script does not decrypt the DVDs. AnyDVD HD and DVDFab Passkey are examples of software that will decrypt the DVD for you. You will most likely need software like this to copy retail discs correctly.
