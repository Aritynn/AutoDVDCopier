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
SET enableScreenshots=true
SET enableIFOMediaInfo=true
SET enableVOBMediaInfo=true
SET amountOfMenuScreens=3
SET amountOfEpisodeScreens=11
SET minAmountOfMenuFrames=100
SET minAmountOfEpisodeFrames=10000
REM ###############################################################################################

MKDIR "!outputDirectory!%infoDirectory%" 2> NUL
IF %enableScreenshots%==true (
    MKDIR "!outputDirectory!%screensDirectory%" 2> NUL
)
CD /D "!outputDirectory!"

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Copy from disc to drive %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
ECHO !currentTime! - Transferring disc data to output location...

mkdir "%transferredFolderPath%%driveLabel%" 2> NUL
teracopy.exe copy "%inputFolderPath%" "%transferredFolderPath%%driveLabel%"
nircmd.exe cdrom open %inputFolderDrive%

FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
ECHO !currentTime! - Finished transferring disc data to output location...

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Get IFO Info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

IF %enableIFOMediaInfo%==true (
    FOR /F "tokens=*" %%a IN ('DIR /B /S /O:S "%transferredFolderPath%%driveLabel%\VIDEO_TS\"') DO (
        IF "%%~xa" == ".IFO" (
            SET "ifoFile=%%a"
        )
    )
    mediainfo.exe "!ifoFile!">"%outputDirectory%%infoDirectory%IFO-mediainfo.txt"

    FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
    SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
    ECHO !currentTime! - Finished extracting IFO mediainfo
) ELSE (
    ECHO No IFO MediaInfo was generated - IFO MediaInfo is not enabled
)

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Check for files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SET checkForVOBFiles=false
IF %enableScreenshots%==true (
    SET checkForVOBFiles=true
)

IF %enableVOBMediaInfo%==true (
    SET checkForVOBFiles=true
)

IF !checkForVOBFiles!==true (
    SET EpisodeFound=0
    FOR /L %%a IN (1, 1, 9) DO (
        IF EXIST "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_0%%a_1.VOB" (
            REM Finds duration of file in frames
            ffmpeg.exe -i "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_0%%a_1.VOB" -map 0:v:0 -c copy -progress - -nostats -f null - > temp.txt 2>&1

            REM Extracts the 13th last line of the ffmpeg output for the frame count
            FOR /F "delims=" %%b in (temp.txt) do (
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
                SET "lastLine=%%b"
            )
            FOR /F "tokens=2 delims==" %%c in ("!lastBut12!") do (
                SET "episodeFrameCount=%%c"
            )

            IF !episodeFrameCount! GEQ %minAmountOfEpisodeFrames% (
                SET EpisodeFound=%%a

                FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
                SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
                ECHO !currentTime! - Continuing - Episode was found

                goto :breakEpisodeFinder
            )
        )
    )
    :breakEpisodeFinder
    IF !EpisodeFound!==0 (
        FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
        SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
        ECHO !currentTime! - Episode was not found - Episode screenshots and VOB mediainfo have not been saved
        PAUSE
    )

    SET MenuFound=0
    FOR /L %%a IN (1, 1, 9) DO (
        IF EXIST "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_0%%a_0.VOB" (
            REM Finds duration of file in frames
            ffmpeg.exe -i "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_0%%a_0.VOB" -map 0:v:0 -c copy -progress - -nostats -f null - > temp.txt 2>&1

            REM Extracts the 13th last line of the ffmpeg output for the frame count
            FOR /F "delims=" %%b in (temp.txt) do (
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
                SET "lastLine=%%b"
            )
            FOR /F "tokens=2 delims==" %%c in ("!lastBut12!") do (
                SET "menuFrameCount=%%c"
            )

            IF !menuFrameCount! GEQ %minAmountOfMenuFrames% (
                SET MenuFound=%%a

                FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
                SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
                ECHO !currentTime! - Continuing - Menu was found

                goto :breakMenuFinder
            )
        )
    )
    :breakMenuFinder
    IF !MenuFound!==0 (
        FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
        SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
        ECHO !currentTime! - Menu was not found - Menu screenshots and VOB mediainfo have not been saved
        PAUSE
    )
)

IF NOT !checkForVOBFiles!==true (
    FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
    SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
    ECHO !currentTime! - Episode and Menu were not searched for - Screenshots and VOB MediaInfo are not enabled
)

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Generate Screenshots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

IF %enableScreenshots%==true (
    DEL %screensDirectory%*.png >NUL 2>&1 & REM Deletes the PNGs already present in the directory

    REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Generates Screenshots Of Menu %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    IF %MenuFound% GEQ 0 (
        FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
        SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
        ECHO !currentTime! - Generating menu screenshots...

        SET /A interval= !menuFrameCount! / %amountOfMenuScreens% & REM Divides the frameCount by N to have an interval the length of 1/N of the video to generate a screenshot at that interval

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

        FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
        SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
        ECHO !currentTime! - Finished generating menu screenshots
    ) ELSE (
        FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
        SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
        ECHO !currentTime! - No menu screenshots were created - No menu was found
    )

    REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Generates Screenshots of First Episode %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    IF %EpisodeFound% GEQ 0 (
        FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
        SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
        ECHO !currentTime! - Generating episode screenshots...
        
        SET /A interval= !episodeFrameCount! / %amountOfEpisodeScreens% & REM Divides the frameCount by N to have an interval the length of 1/N of the video to generate a screenshot at that interval

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
        
        FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
        SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
        ECHO !currentTime! - Finished generating episode screenshots
    ) ELSE (
        FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
        SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
        ECHO !currentTime! - No episode screenshots were created - No episode was found
    )

) ELSE (
    FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
    SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
    ECHO !currentTime! - No screenshots were generated - Screenshots are not enabled
)

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Get VOB Info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

IF %enableVOBMediaInfo%==true (
    ECHO [SPOILER]>"%outputDirectory%%infoDirectory%VOB-description.txt"
    mediainfo.exe "%transferredFolderPath%%driveLabel%\VIDEO_TS\VTS_0%EpisodeFound%_1.VOB">>"%outputDirectory%%infoDirectory%VOB-description.txt"
    ECHO [/SPOILER]>>"%outputDirectory%%infoDirectory%VOB-description.txt"

    FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
    SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
    ECHO !currentTime! - Finished extracting VOB mediainfo
) ELSE (
    FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
    SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
    ECHO !currentTime! - No VOB MediaInfo was generated - VOB MediaInfo is not enabled
)

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Done %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
ECHO !currentTime! - Done

pause
