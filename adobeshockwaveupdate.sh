#!/bin/sh
#####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#   AdobeShockwaveUpdate.sh -- Installs or updates Adobe Shockwave Player
#
# SYNOPSIS
#   sudo AdobeShockwaveUpdate.sh
#
####################################################################################################
#
# HISTORY
#
#   Version: 1.1
#
#   - v.1.0 Joe Farage, 23.01.2015
#   - v.1.1 Steve Miller, 16.12.2015	:Updated to copy echo commands into JSS policy logs
#
####################################################################################################
# Script to download and install Adobe Shockwave Player.
# Only works on Intel systems.

dmgfile="Shockwave_Installer_Full_64bit.dmg"
dmgmount="Adobe Shockwave 12"
logfile="/Library/Logs/AdobeShockwaveUpdateScript.log"
PLUGINPATH="/Library/Internet Plug-Ins/DirectorShockwave.plugin"

# Are we running on Intel?
if [ '`/usr/bin/uname -p`'="i386" -o '`/usr/bin/uname -p`'="x86_64" ]; then
    ## Get OS version and adjust for use with the URL string
    OSvers_URL=$( sw_vers -productVersion )

    ## Set the User Agent string for use with curl
    userAgent="Mozilla/5.0 (Macintosh; Intel Mac OS X ${OSvers_URL}) AppleWebKit/535.6.2 (KHTML, like Gecko) Version/5.2 Safari/535.6.2"

    # Get the latest version of Shockwave available from Adobe's Get Shockwave page.
    latestver=``
    while [ -z "$latestver" ]
    do
       latestver=`/usr/bin/curl -s -L -A "$userAgent" https://get.adobe.com/shockwave/ | grep "<strong>Version" | /usr/bin/sed -e 's/<[^>][^>]*>//g' | /usr/bin/awk '{print $2}'`
    done

    echo "Latest Version is: $latestver"
    latestvernorm=`echo ${latestver}`
    # Get the version number of the currently-installed Adobe Shockwave, if any.
    if [ -e "${PLUGINPATH}" ]; then
        currentinstalledver=`/usr/bin/defaults read "${PLUGINPATH}/Contents/Info" CFBundleShortVersionString | sed 's/[r]/./g'`
        echo "Current installed version is: $currentinstalledver"
        if [ "${latestver}" != "${currentinstalledver}" ]; then
          echo "Adobe Shockwave is current. Exiting"
          exit 0
        fi
    else
        currentinstalledver="none"
        echo "Adobe Shockwave is not installed"
    fi


#	CurrVersNormalized=$( echo $latestver | sed -e 's/[.]//g' -e 's/20//' )
#	echo "CurrVersNormalized: $ASCurrVersNormalized"
    url1="https://fpdownload.macromedia.com/get/shockwave/default/english/macosx/latest/Shockwave_Installer_Full_64bit.dmg"

    #Build URL  
    url=`echo "${url1}"`
    echo "Latest version of the URL is: $url"


    # Compare the two versions, if they are different or Adobe Shockwave is not present then download and install the new version.
    if [ "${currentinstalledver}" != "${latestvernorm}" ]; then
        /bin/echo "`date`: Current Shockwave version: ${currentinstalledver}" >> ${logfile}
        /bin/echo "`date`: Available Shockwave version: ${latestver} => ${latestvernorm}" >> ${logfile}
        /bin/echo "`date`: Downloading newer version." >> ${logfile}
        /usr/bin/curl -s -o /tmp/${dmgfile} ${url}
        /bin/echo "`date`: Mounting installer disk image." >> ${logfile}
        /usr/bin/hdiutil attach /tmp/${dmgfile} -nobrowse -quiet
        /bin/echo "`date`: Installing..." >> ${logfile}
        /usr/sbin/installer -pkg "/Volumes/Adobe Shockwave 12/Shockwave_Installer_Full.pkg" -target / > /dev/null

        /bin/sleep 10
        /bin/echo "`date`: Unmounting installer disk image." >> ${logfile}
        /sbin/umount "/Volumes/Adobe Shockwave 12"
        /bin/sleep 10
        /bin/echo "`date`: Deleting disk image." >> ${logfile}
        /bin/rm /tmp/${dmgfile}

        #double check to see if the new version got updated
        newlyinstalledver=`/usr/bin/defaults read "${PLUGINPATH}/Contents/Info" CFBundleShortVersionString | sed 's/[r]/./g'`
        if [ "${latestvernorm}" = "${newlyinstalledver}" ]; then
          /bin/echo "SUCCESS: Adobe Shockwave has been updated to version ${newlyinstalledver}"
          /bin/echo "`date`: SUCCESS: Adobe Shockwave has been updated to version ${newlyinstalledver}" >> ${logfile}
        else
        	/bin/echo "ERROR: Adobe Shockwave update unsuccessful, version remains at ${currentinstalledver}."
          /bin/echo "`date`: ERROR: Adobe Shockwave update unsuccessful, version remains at ${currentinstalledver}." >> ${logfile}
          /bin/echo "--" >> ${logfile}
          exit 1
        fi

    # If Adobe Shockwave is up to date already, just log it and exit.       
    else
    	/bin/echo "Adobe Shockwave is already up to date, running ${currentinstalledver}."
      /bin/echo "`date`: Adobe Shockwave is already up to date, running ${currentinstalledver}." >> ${logfile}
      /bin/echo "--" >> ${logfile}
    fi  
else
    /bin/echo "`date`: ERROR: This script is for Intel Macs only." >> ${logfile}
fi

exit 0
