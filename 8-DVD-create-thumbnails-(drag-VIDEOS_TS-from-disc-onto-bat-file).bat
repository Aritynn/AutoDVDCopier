@ECHO OFF
IF NOT DEFINED in_subprocess (cmd /k SET in_subprocess=y ^& %0 %*) & exit )
SETLOCAL enabledelayedexpansion

FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
SET localdatetime=%ldt:~0,4%-%ldt:~4,2%-%ldt:~6,2%-%ldt:~8,2%h%ldt:~10,2%m%ldt:~12,2%s

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Instructions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

REM Install and add folder path of the executables to the Windows Path
REM  - FFMpeg (counts total frames and extracts screens)
REM  - MediaInfo (Outputs mediainfo of .VOB and .IFO files)
REM  - NirCmd (Ejects disc when files have finished copying)
REM Set the output directory, screens directory, [media]info directory
REM Enable/Disable Screenshots, IFO/VOB Mediainfo, copying
REM Drag VIDEO_TS folder from DVD onto batch file and follow the instructions

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Initialization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SET inputFolderPath=%~1
SET inputFolderDrive=%~d1
SET inputFolderDirectory=%~dp1
FOR %%B in ("%inputFolderPath%\..") DO SET inputFolderFolder=%%~nxB

REM ##################### CHANGE THESE ############################################################
SET transferredFolderPath=M:\DVDs\
SET enableFolderCopy=true
REM ###############################################################################################

IF %enableFolderCopy%==true (
    FOR /F "tokens=1-5*" %%1 IN ('VOL %inputFolderDrive%') DO (
        SET driveLabelTemp=%%6 & goto finishDriveLabelling
    )
    :finishDriveLabelling
    SET driveLabel=!driveLabelTemp:~0,-1!
    
    IF EXIST "!transferredFolderPath!!driveLabel!" (
        SET /P driveLabelSuffix="The folder '!driveLabel!' already exists at the destination directory. Enter an unused suffix to continue or leave blank to overwrite: "
    )
    SET "driveLabel=%driveLabel%%driveLabelSuffix%"
    SET "transferredFolderPath=%transferredFolderPath%%driveLabel%\"
)

IF %enableFolderCopy%==false (
    SET "transferredFolderPath=!inputFolderDirectory!"
    SET "driveLabel=%inputFolderFolder%"
)

REM ##################### CHANGE THESE ############################################################
SET outputDirectory=C:\Tools\Workshop\
SET screensDirectory=%localdatetime%-%driveLabel%\screens\
SET infoDirectory=%localdatetime%-%driveLabel%\info\

SET enableScreenshots=true
SET enableIFOMediaInfo=true
SET enableVOBMediaInfo=true

SET amountOfMenuScreens=3
SET amountOfEpisodeScreens=13
SET minAmountOfMenuFrames=100
SET minAmountOfEpisodeFrames=10000
REM ###############################################################################################

SET tempFile=%outputDirectory%%infoDirectory%temp.txt

MKDIR "!outputDirectory!%infoDirectory%" 2> NUL
IF %enableScreenshots%==true (
    MKDIR "!outputDirectory!%screensDirectory%" 2> NUL
)
CD /D "!outputDirectory!"

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Copy from disc to drive %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

IF %enableFolderCopy%==true (
    FOR /F "tokens=*" %%a IN ('DIR /S %inputFolderPath%') DO (
        SET "totalSize=!lastLine!"
        SET "lastLine=%%a"
    )
    
    FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
    SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
    ECHO !currentTime! - Transferring to output location: !totalSize!
    
    ROBOCOPY "%inputFolderPath%" "%transferredFolderPath%VIDEO_TS" /E /COPY:DAT /DCOPY:T /MT:1 /R:1 /W:5 /TEE /V /TS /FP /LOG:"%outputDirectory%%infoDirectory%robocopy.log"
    REM "teracopy.exe copy "%inputFolderPath%" "%transferredFolderPath%"
    echo 
    nircmd.exe cdrom open %inputFolderDrive%
    
    FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
    SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
    ECHO !currentTime! - Finished transferring disc data to output location...
) ELSE (
    FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
    SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
    ECHO !currentTime! - Folder was not copied - Folder copying is not enabled
)

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Get IFO Info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

IF %enableIFOMediaInfo%==true (
    FOR /F "tokens=*" %%a IN ('DIR /B /S /O:S "%transferredFolderPath%VIDEO_TS\"') DO (
        IF "%%~xa" == ".IFO" (
            SET "ifoFile=%%a"
        )
    )

    mediainfo.exe "!ifoFile!">%tempFile%
    TYPE %tempFile% | FINDSTR /V /B /L /C:"Complete name" >>"%outputDirectory%%infoDirectory%IFO-mediainfo.txt"

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
    FOR /L %%a IN (1, 1, 99) DO (

		SET "tempVtsNumber=0%%a"
		SET vtsNumber=!tempVtsNumber:~-2!

        IF EXIST "%transferredFolderPath%VIDEO_TS\VTS_!vtsNumber!_1.VOB" (

			echo VTS_!vtsNumber!_1.VOB

            REM Finds duration of file in frames
            ffmpeg.exe -i "%transferredFolderPath%VIDEO_TS\VTS_!vtsNumber!_1.VOB" -map 0:v:0 -c copy -progress - -nostats -f null - > %tempFile% 2>&1
            REM Extracts the 13th last line of the ffmpeg output for the frame count
            FOR /F "delims=" %%b in (%tempFile%) do (
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
			echo !lastBut12!
            FOR /F "tokens=2 delims==" %%c in ("!lastBut12!") do (
                SET "episodeFrameCount=%%c"
            )

            IF !episodeFrameCount! GEQ %minAmountOfEpisodeFrames% (
                SET EpisodeFound=!vtsNumber!

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
    )

    SET MenuFound=0
    FOR /L %%a IN (1, 1, 99) DO (

		SET "tempVtsNumber=0%%a"
		SET vtsNumber=!tempVtsNumber:~-2!

        IF EXIST "%transferredFolderPath%VIDEO_TS\VTS_!vtsNumber!_0.VOB" (
            REM Finds duration of file in frames
            ffmpeg.exe -i "%transferredFolderPath%VIDEO_TS\VTS_!vtsNumber!_0.VOB" -map 0:v:0 -c copy -progress - -nostats -f null - > %tempFile% 2>&1

            REM Extracts the 13th last line of the ffmpeg output for the frame count
            FOR /F "delims=" %%b in (%tempFile%) do (
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
                SET MenuFound=!vtsNumber!

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
        ECHO !currentTime! - Menu was not found - Menu screenshots have not been saved
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

    IF !MenuFound! GEQ 1 (
        FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
        SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
        ECHO !currentTime! - Generating menu screenshots...

        SET /A interval= !menuFrameCount! / %amountOfMenuScreens% & REM Divides the frameCount by N to have an interval the length of 1/N of the video to generate a screenshot at that interval

        REM Extracts screen at each interval and names the file as the frame number
        ffmpeg.exe -analyzeduration 2147483647^
         -probesize 2147483647^
         -i "%transferredFolderPath%VIDEO_TS\VTS_!MenuFound!_0.VOB"^
         -loglevel error^
         -vf [in]setpts=PTS,select="not(mod(n\,!interval!))",scale=iw*sar:ih[out]^
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

    IF !EpisodeFound! GEQ 1 (
        FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
        SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
        ECHO !currentTime! - Generating episode screenshots...
        
        SET /A interval= !episodeFrameCount! / %amountOfEpisodeScreens% & REM Divides the frameCount by N to have an interval the length of 1/N of the video to generate a screenshot at that interval

        REM Extracts screen at each interval and names the file as the frame number
        ffmpeg.exe -analyzeduration 2147483647^
         -probesize 2147483647^
         -i "%transferredFolderPath%VIDEO_TS\VTS_!EpisodeFound!_1.VOB"^
         -loglevel error^
         -vf [in]setpts=PTS,select="not(mod(n\,!interval!))",scale=iw*sar:ih[out]^
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
    IF !EpisodeFound! GEQ 1 (
        ECHO [CENTER]Information:[/CENTER] >"%outputDirectory%%infoDirectory%VOB-description.txt"
        ECHO Name: >>"%outputDirectory%%infoDirectory%VOB-description.txt"
        ECHO Source: FORMAT ^( DISTRIBUTOR ^| Region NNNN ^| NNNN minutes ^| NNNN-disc set ^| DATE ^) >>"%outputDirectory%%infoDirectory%VOB-description.txt"
        ECHO Ripper: AnyDVD HD 7.6.9.1 >>"%outputDirectory%%infoDirectory%VOB-description.txt"
        ECHO. >>"%outputDirectory%%infoDirectory%VOB-description.txt"
        ECHO [SPOILER=VOB MediaInfo] >>"%outputDirectory%%infoDirectory%VOB-description.txt"
        mediainfo.exe "%transferredFolderPath%VIDEO_TS\VTS_0!EpisodeFound!_1.VOB" >%tempFile%
        TYPE %tempFile% | FINDSTR /V /B /L /C:"Complete name" >>"%outputDirectory%%infoDirectory%VOB-description.txt"
        ECHO [/SPOILER] >>"%outputDirectory%%infoDirectory%VOB-description.txt"
        ECHO. >>"%outputDirectory%%infoDirectory%VOB-description.txt"
        ECHO [CENTER] >>"%outputDirectory%%infoDirectory%VOB-description.txt"
        ECHO Screenshots: >>"%outputDirectory%%infoDirectory%VOB-description.txt"
        ECHO. >>"%outputDirectory%%infoDirectory%VOB-description.txt"
        ECHO [/CENTER] >>"%outputDirectory%%infoDirectory%VOB-description.txt"

        FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
        SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
        ECHO !currentTime! - Finished extracting VOB mediainfo
    ) ELSE (
        FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
        SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
        ECHO !currentTime! - No VOB MediaInfo was generated - No episode was found
    )
) ELSE (
    FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
    SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
    ECHO !currentTime! - No VOB MediaInfo was generated - VOB MediaInfo is not enabled
)

REM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Done %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DEL %tempFile% >NUL 2>&1 & REM Deletes the temp file

FOR /F "usebackq tokens=1,2 delims==" %%i in (`WMIC OS GET LocalDateTime /VALUE 2^>NUL`) DO IF '.%%i.'=='.LocalDateTime.' SET ldt=%%j
SET currentTime=!ldt:~0,4!-!ldt:~4,2!-!ldt:~6,2!-!ldt:~8,2!h!ldt:~10,2!m!ldt:~12,2!s
ECHO !currentTime! - Done

pause
