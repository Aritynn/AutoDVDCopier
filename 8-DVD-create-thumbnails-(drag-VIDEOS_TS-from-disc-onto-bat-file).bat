@ECHO OFF
IF NOT DEFINED in_subprocess (cmd /k SET in_subprocess=y ^& %0 %*) & exit )
SETLOCAL enabledelayedexpansion

FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
SET localdatetime=%ldt:~0,4%-%ldt:~4,2%-%ldt:~6,2%-%ldt:~8,2%h%ldt:~10,2%m%ldt:~12,2%s

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Instructions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

REM Install and add folder path of the executables to the Windows Path
REM  - FFMpeg (counts total frames and extracts screens)
REM  - MediaInfo (Outputs mediainfo of .VOB and .IFO files)
REM  - TeraCopy (Copies files from disc with integrity verification)
REM  - NirCmd (Ejects disc when files have finished copying)
REM Make sure Teracopy has "Always test after copy" enabled
REM Set the output directory, screens directory, [media]info directory
REM Drag VIDEO_TS folder from DVD onto batch file and follow the instructions

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Initialization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



REM %~n1\
SET inputFolderPath=%~1
SET inputFolderDrive=%~d1

REM ##################### CHANGE THIS #############################################################
SET transferredFolderPath=M:\DVDs\
REM ###############################################################################################

FOR /F "tokens=1-5*" %%1 IN ('VOL %inputFolderDrive%') DO (
                SET driveLabelTemp=%%6 & goto finishDriveLabelling
           )
:finishDriveLabelling
SET driveLabel=!driveLabelTemp:~0,-1!

IF EXIST "!transferredFolderPath!!driveLabel!" (
    SET /P driveLabelSuffix="The folder (!driveLabel!) already exists at the destination directory. Enter an unused suffix to continue or leave blank to overwrite: "
)
SET "driveLabel=%driveLabel%%driveLabelSuffix%"

REM ##################### CHANGE THESE ############################################################
SET outputDirectory=C:\Tools\Workshop\
SET screensDirectory=%localdatetime%-%driveLabel%\screens\
SET infoDirectory=%localdatetime%-%driveLabel%\info\
REM ###############################################################################################

MKDIR "!outputDirectory!%infoDirectory%" 2> NUL
MKDIR "!outputDirectory!%screensDirectory%" 2> NUL
CD /D "!outputDirectory!"

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Copy from disc to drive %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ECHO Transferring disc data to output location...

mkdir "%transferredFolderPath%%driveLabel%" 2> NUL
teracopy.exe copy "%inputFolderPath%" "%transferredFolderPath%%driveLabel%"
nircmd.exe cdrom open %inputFolderDrive%

ECHO Finished transferring disc data to output location...

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Check for files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

IF EXIST "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_01_1.VOB" (
    SET "EpisodeFound=1"
    ECHO Continuing - Episode was found
) ELSE (
    IF EXIST "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_02_1.VOB" (
        SET "EpisodeFound=2"
        ECHO Continuing - Episode was found
    ) ELSE (
        IF EXIST "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_03_1.VOB" (
            SET "EpisodeFound=3"
            ECHO Continuing - Episode was found
        ) ELSE (
            IF EXIST "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_04_1.VOB" (
                SET "EpisodeFound=4"
                ECHO Continuing - Episode was found
            ) ELSE (
                SET "EpisodeFound=0"
                ECHO Cancelling - Episode was not found
                PAUSE
            )
        )
    )
)

IF EXIST "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_01_0.VOB" (
    SET "MenuFound=1"
    ECHO Continuing - Menu was found
) ELSE (
    IF EXIST "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_02_0.VOB" (
        SET "MenuFound=2"
        ECHO Continuing - Menu was found
    ) ELSE (
        IF EXIST "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_03_0.VOB" (
            SET "MenuFound=3"
            ECHO Continuing - Menu was found
        ) ELSE (
            IF EXIST "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_04_0.VOB" (
                SET "MenuFound=4"
                ECHO Continuing - Menu was found
            ) ELSE (
                SET "MenuFound=0"
                ECHO Cancelling - Menu was not found
                PAUSE
            )
        )
    )
)

DEL %screensDirectory%*.png >NUL 2>&1 & REM Deletes the PNGs already present in the directory

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Generates Screenshots Of Menu %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



 REM Finds duration of file in seconds
ffmpeg.exe -i "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_0%MenuFound%_0.VOB" -map 0:v:0 -c copy -progress - -nostats -f null - > temp.txt 2>&1

REM Extracts the 13th last line of the ffmpeg output for the frame count
FOR /F "delims=" %%a in (temp.txt) do (
    SET "lastBut12=!lastBut11!"
    SET "lastBut11=!lastBut10!"
    SET "lastBut10=!lastBut9!"
    SET "lastBut9=!lastBut8!"
    SET "lastBut8=!lastBut7!"
    SET "lastBut7=!lastBut6!"
    SET "lastBut6=!lastBut5!"
    SET "lastBut5=!lastBut4!"
    SET "lastBut4=!lastBut3!"
    SET "lastBut3=!lastBut2!"
    SET "lastBut2=!lastBut1!"
    SET "lastBut1=!lastLine!"
    SET "lastLine=%%a"
    )
FOR /F "tokens=2 delims==" %%b in ("!lastBut12!") do (
    SET "frameCount=%%b"
)

SET /A interval= !frameCount! / 3 & REM Divides the framecount by N to have an interval the length of 1/N of the video to generate a screenshot at that interval

REM Extracts screen at each interval and names the file as the frame number
ffmpeg.exe -analyzeduration 2147483647^
 -probesize 2147483647^
 -i "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_0%MenuFound%_0.VOB"^
 -loglevel error^
 -vf [in]setpts=PTS,select="not(mod(n\,!interval!))"[out]^
 -vsync 0^
 -stats^
 -f image2^
 -start_number 0^
 -frame_pts 1^
 "%outputDirectory%%screensDirectory%a_menu-%%d-%driveLabel%.png"

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Generates Screenshots of First Episode %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 REM Finds duration of file in seconds
ffmpeg.exe -i "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_0%EpisodeFound%_1.VOB" -map 0:v:0 -c copy -progress - -nostats -f null - > temp.txt 2>&1

REM Extracts the 13th last line of the ffmpeg output for the frame count
FOR /F "delims=" %%a in (temp.txt) do (
    SET "lastBut12=!lastBut11!"
    SET "lastBut11=!lastBut10!"
    SET "lastBut10=!lastBut9!"
    SET "lastBut9=!lastBut8!"
    SET "lastBut8=!lastBut7!"
    SET "lastBut7=!lastBut6!"
    SET "lastBut6=!lastBut5!"
    SET "lastBut5=!lastBut4!"
    SET "lastBut4=!lastBut3!"
    SET "lastBut3=!lastBut2!"
    SET "lastBut2=!lastBut1!"
    SET "lastBut1=!lastLine!"
    SET "lastLine=%%a"
    )
FOR /F "tokens=2 delims==" %%b in ("!lastBut12!") do (
    SET "frameCount=%%b"
)

SET /A interval= !frameCount! / 11 & REM Divides the framecount by N to have an interval the length of 1/N of the video to generate a screenshot at that interval

REM Extracts screen at each interval and names the file as the frame number
ffmpeg.exe -analyzeduration 2147483647^
 -probesize 2147483647^
 -i "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_0%EpisodeFound%_1.VOB"^
 -loglevel error^
 -vf [in]setpts=PTS,select="not(mod(n\,!interval!))"[out]^
 -vsync 0^
 -stats^
 -f image2^
 -start_number 0^
 -frame_pts 1^
 "%outputDirectory%%screensDirectory%b_episode-%%d-%driveLabel%.png"

DEL "%outputDirectory%%screensDirectory%*-0-*.png" >NUL 2>&1

ECHO Finished generating screenshots

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Get VOB Info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ECHO [SPOILER]>"%outputDirectory%%infoDirectory%VOB-description.txt"
mediainfo.exe "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_0%EpisodeFound%_1.VOB">>"%outputDirectory%%infoDirectory%VOB-description.txt"
ECHO [/SPOILER]>>"%outputDirectory%%infoDirectory%VOB-description.txt"

ECHO Finished extracting VOB mediainfo

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Get IFO Info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FOR /F "tokens=*" %%a IN ('DIR /B /S /O:S "%transferredFolderPath%%driveLabel%\VIDEO_TS\"') DO (
    IF "%%~xa" == ".IFO" (
        SET "ifoFile=%%a"
    )
)
mediainfo.exe "!ifoFile!">"%outputDirectory%%infoDirectory%IFO-mediainfo.txt"

ECHO Finished extracting IFO mediainfo

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Done %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ECHO Done

pause
