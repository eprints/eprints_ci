# EPrints Continuous Integration Environment
EPrints Continuous Integration Environment is a framework for deploying automated testing of EPrints repositories.  It is intended to allow changes to the EPrints codebase to be comprehensively tested to ensure they cause no unexpected side effects.  The framework in built around [Selenium IDE](https://www.selenium.dev/selenium-ide/) for building and running user acceptance tests and [Jenkins](https://www.jenkins.io/) for automating building, testing and evaluating EPrints.  The instructionsthat follow have been tested on a CentOS 7 Linux operating system.

## Deploying Configuration and SIDE Files 
Run the **bin/deploy_config_and_sides** script as the eprints user on the server hosting the EPrints repository you want to test:

    bin/deploy_config_and_sides /opt/eprints3/ http://example.eprints.org

Replace the first parameter with the path where EPrints is installed on your server and the second parameter with the base URL of your repository (no trailing '/' required).

## Deploying Selenium Side Runner
These instructions are based on those required for RHEL/CentOS 7.  It may be possible to install packages from standard package repositories if you are running later versions or different flavours of Linux.
1. As root, Install packages needed to make NodeJS LTS RPM

    ```yum install -y gcc-c++ make```

2. Auto-generate NodeJS LTS RPM from rpm.nodesource.com

    ```curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -```

3. As root, now install nodejs RPM

    ```yum install -y nodejs```

4. As root, Use npm to install selenium-side-runner

    ```npm install -g selenium-side-runner```

5. As root, Use npm to install geckodriver

    ```npm install -g geckodriver  --unsafe-perm=true --allow-root```

6. As root, install Firefox and Xvfb to it can be run in headless mode

    ```yum install -y firefox xorg-x11-server-Xvfb```

7. Not as root, start an Xvfb instance and run Firefox headless in it

    ```
    Xvfb :55 &
    export DISPLAY=:55
    firefox --headless &
    ```

8. Now you can run a Selenium SIDE file to run tests against EPrints:

    ```selenium-side-runner -c "browserName=firefox" sides/eprints.side```
    
## Making SIDE Templates from Working Copies
Run the ```bin/make_side_template``` script to write a deployed SIDE file as a template that can be committed back to version control:

    bin/make_side_template sides/eprints.side

Replace the only parameter with the file path of the deployed SIDE file you want to write as a template.
    
## Integrating with Jenkins
**To be written**

## Files

### bin (scripts)

* ```deploy_config_and_sides <EPRINTS_PATH> <EPRINTS_URL>```
  * Generates runnable Selenium SIDE files from templates and deploys Selenium configuration web page to EPrints repository to load configuration variables into Selenium tests.
  * **EPRINTS\_PATH** - The filesystem path of the EPrints repository to deploy Selenium configuration web page.
  * **EPRINTS\_URL** - The base URL of the EPrints repository.

* ```make_side_template <SIDE_FILEPATH>```
  * Takes configured (i.e. base URL set) Selenium SIDE file and converts it into a template of itself.
  * **SIDE\_FILEPATH** - The location of the Selenium SIDE file to be used to update its template equivalent.

* ```restore_eprints_template <ARCHIVE> <LOCATION> <URL>```
  * Restores a backup template of archive files (code, configuration and documents) and database on the EPrints path.  It is assumed that EPrints was originally installed in /opt/eprints3.
  * **ARCHIVE** - The ID of the archive to be restored from ```templates/``` directory.
  * **LOCATION** - Where EPrints is installed by Jenkins during a build (typically /var/lib/jenkins/workspace/<PROJECT_NAME>).
  * **URL** - The URL from where the EPrints repository can be accessed in a web browser.


### cfg (configuration)

* ```eprints_ci_sudoers```
  * Contains sudoers configuration to allow scripts to run automatically.
  * Needs to be copied to ```/etc/sudoers.d/``` before running  ```deploy_config_and_sides``` or ```restore_eprints_template```
* ```selenium.xhtml.tmpl```
  * Contains configurable options for Selenium tests.  
  * Needs to be copied to ```selenium.xhtml``` and any modifications made to that file before running ```deploy_config_and_sides```
* ```side.yml.tmpl```
  * Contains configuration settings for running SIDE files with ```selenium-side-runner```.
  * Should be copied to ```side.yml``` before making any modifications.


### sides/
This directory will initially contain no files as the ```bin/deploy_config_and_sides``` needs to be run to convert the template SIDE files in the ```templates/``` sub-directory into this directory.

#### sides/template/
* ```eprints.side``` - All EPrints tests.  Currently just for public-facing pages.  Likely to be broken up into several SIDE fiels as more tests are added.


### templates/
This directory contains templates, effectively backups of EPrints archives that can be restored using the ```restore_eprints_template``` script.  This directory contains two (initially empty) separate directories:
* ```databases/``` - MySQL dumps of EPrints archives.
* ```archives/``` - archive sub-directory that would have been installed under EPrints' ```archives/``` directory.


