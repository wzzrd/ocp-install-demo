@ECHO OFF
setlocal

set PROJECT_HOME=%~dp0
set DOCKER_MAJOR_VER=17
set DOCKER_MINOR_VER=03
set OC_MAJOR_VER=v3
set OC_MINOR_VER=5
set OC_MINI_VER=5
set OCP_VERSION=%OC_MAJOR_VER%.%OC_MINOR_VER%

REM sets RAM usage limit for OCP.
set VBOX_MEMORY=12288

REM wipe screen.
cls

echo.
echo ##############################################################
echo ##                                                          ##   
echo ##  Setting up your very own                                ##
echo ##                                                          ##   
echo ##    ###  ####  ##### #   #  #### #   # ##### ##### #####  ##
echo ##   #   # #   # #     ##  # #     #   #   #   #       #    ##
echo ##   #   # ####  ###   # # #  ###  #####   #   ####    #    ##
echo ##   #   # #     #     #  ##     # #   #   #   #       #    ##
echo ##    ###  #     ##### #   # ####  #   # ##### #       #    ##
echo ##                                                          ##   
echo ##    ####  ###  #   # #####  ###  ##### #   # ##### #####  ##
echo ##   #     #   # ##  #   #   #   #   #   ##  # #     #   #  ##
echo ##   #     #   # # # #   #   #####   #   # # # ###   #####  ##
echo ##   #     #   # #  ##   #   #   #   #   #  ## #     #  #   ##
echo ##    ####  ###  #   #   #   #   # ##### #   # ##### #   #  ##
echo ##                                                          ##   
echo ##      ####  #      ###  ##### #####  ###  ##### #   #     ##   
echo ##      #   # #     #   #   #   #     #   # #   # ## ##     ##   
echo ##      ####  #     #####   #   ####  #   # ##### # # #     ##   
echo ##      #     #     #   #   #   #     #   # #  #  #   #     ##   
echo ##      #     ##### #   #   #   #      ###  #   # #   #     ##   
echo ##                                                          ##   
echo ##  https://github.com/redhatdemocentral/ocp-install-demo   ##
echo ##                                                          ##   
echo ##############################################################
echo.

REM Ensure Docker is installed

call where docker >nul 2>&1

if %ERRORLEVEL% NEQ 0 (
  echo Docker is required but not installed yet... download here: https://store.docker.com/search?offering=community&type=edition
  GOTO :EOF
) else (
  echo Docker is installed... checking for valid version...
)

call docker ps >nul 2>&1

if %ERRORLEVEL% NEQ 0 (
  echo Docker deamon is not running... or is running insecurely...
  echo.
  echo Check for instructions to run the docker deamon securely see this projects Readme.md file.
  echo.
  echo.
  GOTO :EOF
)

echo Verified the Docker deamon is running...
echo.

REM Check docker version
for /f "delims=*" %%i in ('docker version ^| findstr -i Version') do (
  for /F "tokens=2 delims= " %%A in ('echo %%i') do ( 
    set dockerVerFull=%%A	
  )
  
  GOTO :endDockerLoop
)

:endDockerLoop

for /F "tokens=1,2,3 delims=." %%a in ('echo %dockerVerFull%') do (
  set dockerverone=%%a
  set dockervertwo=%%b
  set dockerverthree=%%c
)

if %dockerverone% EQU %DOCKER_MAJOR_VER% if %dockervertwo% GEQ %DOCKER_MINOR_VER% ( 
GOTO :passDockerTestContinue
)

REM Print Failure 
echo Docker engine version %dockerverone%.%dockervertwo% found... need %DOCKER_MAJOR_VER%.%DOCKER_MINOR_VER% or higher, please update: https://store.docker.com/search?offering=community&type=edition
echo
GOTO :EOF



:passDockerTestContinue

echo Valid version of docker engine found... %dockerverone%.%dockervertwo%
echo.

REM Ensure OpenShift command line tools available.
call oc help >nul 2>&1

if %ERRORLEVEL% NEQ 0 (
  echo OpenShift CLI tooling is required but not installed yet... download here: https://drive.google.com/open?id=0B9WSViV5BZ4aVXV5U3F4LVVmWVk
  GOTO :EOF
) else (
  echo OpenShift command line tools installed... checking for valid version...
  echo.
)

for /f "delims=*" %%i in ('oc version ^| findstr -i oc') do (
  for /F "tokens=2 delims= " %%A in ('echo %%i') do ( 
	set verFull=%%A	
  )
)

for /F "tokens=1,2,3 delims=." %%a in ('echo %verFull%') do (
  set verone=%%a
  set vertwo=%%b
  set verthree=%%c
)

if %OC_MAJOR_VER% EQU %verone% if %OC_MINOR_VER% EQU %vertwo% if %OC_MINI_VER% EQU %verthree% (
 echo Version of installed OpenShift command line tools correct... %verfull%
 echo.
 GOTO :passOcTestContinue
)

echo Version of installed OpenShift command line tools is %verone%.%vertwo%.%verthree%, must be %OC_MAJOR_VER%.%OC_MINOR_VER%.%OC_MINI_VER%...
echo.
echo Download for Windows here: https://drive.google.com/open?id=0B9WSViV5BZ4aVXV5U3F4LVVmWVk
GOTO :EOF

:passOcTestContinue

echo Setting up OpenShift docker machine...
echo.
call docker-machine create --driver virtualbox --virtualbox-cpu-count "2" --virtualbox-memory "%VBOX_MEMORY%" --engine-insecure-registry 172.30.0.0/16 --virtualbox-boot2docker-url https://github.com/boot2docker/boot2docker/releases/download/v1.13.1/boot2docker.iso openshift

if %ERRORLEVEL% NEQ 0 (
 echo.
 echo Error occurred during openshift docker machine creation...
 echo.
 echo Cleaning out existing 'openshift' machine...
 echo.
 call docker-machine rm -f openshift
 
 echo Setting up new OpenShift docker machine...
 echo.
 call docker-machine create --driver virtualbox --virtualbox-cpu-count "2" --virtualbox-memory "%VBOX_MEMORY%" --engine-insecure-registry 172.30.0.0/16 --virtualbox-boot2docker-url https://github.com/boot2docker/boot2docker/releases/download/v1.13.1/boot2docker.iso openshift

 if %ERRORLEVEL% NEQ 0 (
  echo.
  echo Problem with docker machine creation that I can't resolve, please raise an issue and add error output:
  echo.
  echo    https://github.com/redhatdemocentral/ocp-install-demo/issues/new
  echo.
  GOTO :EOF
 )
)

echo Installing OCP with cluster up...
echo.

call oc cluster up --image=registry.access.redhat.com/openshift3/ose --host-data-dir=/var/lib/boot2docker/ocp-data  --docker-machine=openshift --host-config-dir=/var/lib/boot2docker/ocp-config --use-existing-config=true --host-pv-dir=/var/lib/boot2docker/ocp-pv

if %ERRORLEVEL% NEQ 0 (
  echo.
  echo There was an issue starting OCP. If you feel the need, raise an issue and add error output:
  echo.
  echo    https://github.com/redhatdemocentral/ocp-install-demo/issues/new
  echo.
  GOTO :EOF
)

echo.
echo Logging in as admin user...
echo.
oc login -u system:admin

for /f "delims=" %%i in ('oc status ^| findstr -i -c:"My Project"') do (
  for /F "tokens=8 delims= " %%A in ('echo %%i') do ( 
    set OCP_IP=%%A	
  )
)

echo Updating JBoss image streams...
echo.
call oc create -n openshift -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/jboss-image-streams.json

if %ERRORLEVEL% NEQ 0 (
	echo.
	echo Problem with accessing JBoss EAP product streams for OCP.
	echo.
  echo Trying again.
	echo.
  call oc create -n openshift -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/jboss-image-streams.json
	
	if %ERRORLEVELS% NEQ 0 (
		echo Failed again, exiting, check output messages and network connectivity before running install again.
		echo.
    call docker-machine rm -f openshift
		GOTO :EOF
  )
)

echo.
echo Updating Fuse image streams...
echo.
call oc create -n openshift -f https://raw.githubusercontent.com/jboss-fuse/application-templates/master/fis-image-streams.json

if %ERRORLEVEL% NEQ 0 (
	echo.
	echo Problem with accessing Fuse Integration product streams for OCP.
	echo.
  echo Trying again.
	echo.
  call oc create -n openshift -f https://raw.githubusercontent.com/jboss-fuse/application-templates/master/fis-image-streams.json
	
	if %ERRORLEVELS% NEQ 0 (
		echo Failed again, exiting, check output messages and network connectivity before running install again.
		echo.
    call docker-machine rm -f openshift
		GOTO :EOF
  )
)

echo.
echo Updating EAP templates...
echo.
call oc create -n openshift -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/eap/eap70-basic-s2i.json

if %ERRORLEVEL% NEQ 0 (
	echo.
	echo Problem with accessing JBoss EAP product streams for OCP.
	echo.
  echo Trying again.
	echo.
  call oc create -n openshift -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/eap/eap70-basic-s2i.json
	
	if %ERRORLEVELS% NEQ 0 (
		echo Failed again, exiting, check output messages and network connectivity before running install again.
		echo.
    call docker-machine rm -f openshift
		GOTO :EOF
  )
)

echo. 
echo Updating Decision Server templates...
echo.
call oc create -n openshift -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/decisionserver/decisionserver63-basic-s2i.json

if %ERRORLEVEL% NEQ 0 (
	echo.
	echo Problem with accessing JBoss BRMS product streams for OCP.
	echo.
  echo Trying again.
	echo.
  call oc create -n openshift -f https://raw.githubusercontent.com/jboss-openshift/application-templates/master/decisionserver/decisionserver63-basic-s2i.json
	
	if %ERRORLEVELS% NEQ 0 (
		echo Failed again, exiting, check output messages and network connectivity before running install again.
		echo.
    call docker-machine rm -f openshift
		GOTO :EOF
  )
)

echo.
echo Updating RHEL 7 image streams...
echo.
call oc delete -n openshift -f https://raw.githubusercontent.com/openshift/openshift-ansible/master/roles/openshift_examples/files/examples/v1.4/image-streams/image-streams-rhel7.json
call oc create -n openshift -f https://raw.githubusercontent.com/openshift/openshift-ansible/master/roles/openshift_examples/files/examples/v1.4/image-streams/image-streams-rhel7.json

if %ERRORLEVEL% NEQ 0 (
	echo.
	echo Problem with accessing RHEL product streams for OCP.
	echo.
  echo Trying again.
	echo.
  call oc delete -n openshift -f https://raw.githubusercontent.com/openshift/openshift-ansible/master/roles/openshift_examples/files/examples/v1.4/image-streams/image-streams-rhel7.json
  call oc create -n openshift -f https://raw.githubusercontent.com/openshift/openshift-ansible/master/roles/openshift_examples/files/examples/v1.4/image-streams/image-streams-rhel7.json
	
	if %ERRORLEVELS% NEQ 0 (
		echo Failed again, exiting, check output messages and network connectivity before running install again.
		echo.
    call docker-machine rm -f openshift
		GOTO :EOF
  )
)


echo.
echo Update .Net image streams...
echo.
call oc create -n openshift -f https://raw.githubusercontent.com/redhat-developer/s2i-dotnetcore/master/dotnet_imagestreams.json

if %ERRORLEVEL% NEQ 0 (
	echo.
	echo Problem with accessing .Net image streams for OCP.
	echo.
  echo Trying again.
	echo.
  call oc create -n openshift -f https://raw.githubusercontent.com/redhat-developer/s2i-dotnetcore/master/dotnet_imagestreams.json
	
	if %ERRORLEVELS% NEQ 0 (
		echo Failed again, exiting, check output messages and network connectivity before running install again.
		echo.
    call docker-machine rm -f openshift
		GOTO :EOF
  )
)

echo.
echo ====================================================
echo =                                                  =
echo = Install complete, get ready to rock your Cloud.  =
echo = Look for information at end of OSE install.      =
echo =                                                  =
echo =  The server is accessible via web console at:    =
echo =                                                  =
echo =	  %OCP_IP%               =
echo =                                                  =
echo =  Log in as user: openshift-dev                   =
echo =        password: devel                           =
echo =                                                  =
echo =  Admin log in as: admin                          =
echo =         password: admin                          =
echo =                                                  =
echo =  Now get your Red Hat Demo Central example       =
echo =  projects here:                                  =
echo =                                                  =
echo =     https://github.com/redhatdemocentral         =
echo =                                                  =
echo =  To stop and restart your OCP cluster with       =
echo =  installed containers, see Readme.md in the      =
echo =  NOTES section for details.                      =
echo =                                                  =
echo =  When finished, clean up your demo with:         =
echo =                                                  =
echo =     $ docker-machine rm -f openshift             =
echo =                                                  =
echo ====================================================
