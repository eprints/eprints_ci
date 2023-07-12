# EPrints Continuous Integration Environment
**Instructions need to be upgraded to describe new way of running CI against EPrints 3.5.**

EPrints Continuous Integration Environment is a framework for deploying automated testing of EPrints repositories.  It is intended to allow changes to the [EPrints codebase](https://github.com/eprints/eprints3.4) to be comprehensively tested to ensure they cause no unexpected side effects.  The framework in built around [Selenium IDE](https://www.selenium.dev/selenium-ide/) for building and running user acceptance tests and [Jenkins](https://www.jenkins.io/) for automating building, testing and evaluating EPrints.  The instructions that follow have been tested on a CentOS 7 Linux operating system.

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

7. Deploy the Systemd units ```cfg/xvfb-55.service``` and ```cfg/firefox-headless.service``` 

    ```
    cp cfg/*.service /etc/systemd/system/
    systemctl enable xvfb-55
    systemctl start xvfb-55
    systemctl enable firefox-headless
    systemctl start firefox-headless
    ```

8. Now you can run a Selenium SIDE file to run tests against EPrints:

    ```selenium-side-runner -c "browserName=firefox" sides/eprints.side```
    
## Making SIDE Templates from Working Copies
Run the ```bin/make_side_template``` script to write a deployed SIDE file as a template that can be committed back to version control:

    bin/make_side_template sides/eprints.side

Replace the only parameter with the file path of the deployed SIDE file you want to write as a template.
    
## Integrating with Jenkins

### Installing EPrints 
Before you can integrate with Jenkins you need to have an EPrints installation in place.  This needs to be installed via [GitHub](https://github.com/eprints/eprints3.4) following these [instructions](https://wiki.eprints.org/w/Installing_EPrints_on_RHEL/Fedora/CentOS#Installing_EPrints_3.4.x_from_Source).  

### Create a new EPrints archive
Now EPrints is installed and your have [created a new archive](https://wiki.eprints.org/w/Getting_Started_with_EPrints_3) (for these instructions will be know as **test_archive**), you need to deploy the test data by running the ```testdata/bin/import_test_data``` script against your archive:
    testdata/bin/import_test_data test_archive

### Installing Jenkins
Once installed you can then [install Jenkins](https://www.jenkins.io/doc/book/installing/linux/#red-hat-centos).  Before creating your EPrints project and build pipeline you need to make a few system level configuration changes:

1. Clone or move this Git repository to: ```/usr/local/share/eprints_ci``` and make sure all files are owned by eprints with group write permssions:
    chown -R eprints:eprints /usr/local/share/eprints_ci
    chmod -R g+w /usr/local/share/eprints_ci
2. Ensure EPrints parent directory (i.e. ```/opt```) is owned and belongs to the eprints group:
    chown epring:eprints /opt 
3. Copy ```cfg/eprints_ci_sudoers``` to ```/etc/sudoers.d/eprints_ci```
    cp /usr/local/share/eprints_ci/cfg/eprints_ci_sudoers /etc/sudoers.d/eprints_ci
4. Add the ```eprints``` user to the ```jenkins``` group and vice-versa
    usermod -a -G jenkins eprints
    usermod -a -G eprints jenkins

### Building an EPrints archive template
Now you need to build the template for you generated archive.  There are several steps to this:

1. Ensure that there are no tasks in the EPrints event queue.  If there are this may lead to tests producing on reliable results.  If there are test outstanding.  Make sure these have all run successfully and retry any failed tasks.
2. Stop the EPrints indexer (as the eprints user) and webserver
    bin/indexer stop
    systemctl stop httpd
3. Take a backup of the database to the ```templates/databases/``` directory:
    mysqldump -u root test\_archive > /usr/local/share/eprints_ci/templates/databases/test\_archive.sql
4. Move the archive to the ```templates/archives/``` directory:
    mv archives/test\_archive  /usr/local/share/eprints_ci/templates/archives/
5. Delete or move the EPrints directory (i.e. ```/opt/eprints3/```) out of the way.  (Jenkins will clone this from [GitHub](https://github.com/eprints/eprints3.4), each time a build is run).

### Creating and configuring an EPrints project in Jenkins
Now you have an EPrints archive templates you have all the elements you need to create an EPrints project in Jenkins and configure a build pipeline.
1.  Click on **New Item** and add a new **Freestyle project** called *eprints* and click on **OK**.
2.  On the page that loads add a basic **Description**.
3.  Check the **Discard old builds** checkbox set the **Strategy** as *Log Rotation* and set the **Max # of builds** to *10*.
4. Under the **Source Code Management** section select *Git* and set the **Repository URL** to *https://github.com/eprints/eprints* under **Branches to build** set the **Branch Specifier** to *\*/master*.  You may want to change thiese later if you want to test your own fork/branch of EPrints.
5. Under the **Build Triggers** you can choose what is most suitable for you.  The easiest to configure is **Build periodically**.  The following will run a build once a day at 8am:
    0 8 * * * *
6. Under the **Build Environment** section check the **Delete workspace before build starts**, **Abort the build if it's stuck** and **Add timestamps to Console Output** checkboxes.  For the second of these set the **Time-out strategy** to *Absolute* and the **Timeout minutes** to *30*.
7. Under the **Build** section add an **Execute shell** stage.  This stage is for restoring the EPrints archive template and requires the following commands.  (If you wany yo test a zero Ensure you set the correct sed replacement for ARCHIVE\_NAME and parameters for the ```restore_eprints_template``` script are set appropriately. (${WORKSPACE} should not be changed and this is a Jenkins environment variable):
    chmod -R g+w ${WORKSPACE}
    sudo /usr/bin/chown -R eprints:eprints ${WORKSPACE}/*
    mkdir ${WORKSPACE}/results
    cat /usr/local/share/eprints_ci/cfg/selenium.xhtml.tmpl | sed "s/ARCHIVE_NAME/EPrints/" > /usr/local/share/eprints_ci/cfg/selenium.xhtml
    sudo -u eprints /usr/local/share/eprints_ci/bin/restore_eprints_template test_archive ${WORKSPACE} http://example.eprints.org eprints34_pub
8. Add a second **Execute shell** stage under the **Build** section.  This is stage is for running tests for an EPrints publications archive under the ```selenium-side-runner```, using a headless version of Firefox.  If you want to run tests against a zero archive then switch *eprints34_pub.side* for *eprints34_zero.side*.
    export DISPLAY=:55
    cd ${WORKSPACE}
    selenium-side-runner --config-file=/usr/local/share/eprints_ci/cfg/side.yml --output-directory=results --output-format=junit /usr/local/share/eprints_ci/sides/eprints34_pub.side  
9. Under the **Post-build Action** add a **Publish JUnit test result report** stage and set the **Test report XMLs** to ```results/*.xml```.
10. You may also want to set up some notifications.  Email is the easiest to set up by you could try [Slack notifications](https://medium.com/appgambit/integrating-jenkins-with-slack-notifications-4f14d1ce9c7a).
11. Finally click on **Save** and you will be taken back to the project's homepage and you can **Build Now**.
    
## Files

### bin/ (scripts)

* ```deploy_config_and_sides <EPRINTS_PATH> <EPRINTS_URL>```
  * Generates runnable Selenium SIDE files from templates and deploys Selenium configuration web page to EPrints repository to load configuration variables into Selenium tests.
  * **EPRINTS\_PATH** - The filesystem path of the EPrints repository to deploy Selenium configuration web page.
  * **EPRINTS\_URL** - The base URL of the EPrints repository.
  * **SELENIUM_PROJECT** - The Selenium project (i.e. SIDE file without the .side) you want to deploy.

* ```make_side_template <SIDE_FILEPATH>```
  * Takes configured (i.e. base URL set) Selenium SIDE file and converts it into a template of itself.
  * **SIDE\_FILEPATH** - The location of the Selenium SIDE file to be used to update its template equivalent.

* ```restore_eprints_template <ARCHIVE> <LOCATION> <URL> <PROJECT>```
  * Restores a backup template of archive files (code, configuration and documents) and database on the EPrints path.  It is assumed that EPrints was originally installed in /opt/eprints3.
  * **ARCHIVE** - The ID of the archive to be restored from ```templates/``` directory.
  * **LOCATION** - Where EPrints is installed by Jenkins during a build (typically /var/lib/jenkins/workspace/<PROJECT_NAME>).
  * **URL** - The URL from where the EPrints repository can be accessed in a web browser.
  * **PROJECT** - The Selenium project (i.e. SIDE file without the .side) you want to deploy.


### cfg/ (configuration)

* ```eprints_ci_sudoers```
  * Contains sudoers configuration to allow scripts to run automatically.
  * Needs to be copied to ```/etc/sudoers.d/``` before running  ```deploy_config_and_sides``` or ```restore_eprints_template```
* ```firefox-headless.service```
  * Systemd unit for running Firefox in headless mode 
* ```get_user_pin```
  * CGI script for getting pin that would be sent in user account activation email.
* ```selenium.xhtml.tmpl```
  * Contains configurable options for Selenium tests.  
  * Needs to be copied to ```selenium.xhtml``` and any modifications made to that file before running ```deploy_config_and_sides```
* ```test.pdf```
  * A PDF to upload from a URL for testing purposes.  
* ```side.yml.tmpl```
  * Contains configuration settings for running SIDE files with ```selenium-side-runner```.
  * Should be copied to ```side.yml``` before making any modifications.
* ```xvfb-55.service```
  * Systemd unit for running ```Xvfb``` on ```DISPLAY=:55``` 

### sides/
This directory will initially contain no files as the ```bin/deploy_config_and_sides``` needs to be run to convert the template SIDE files in the ```templates/``` sub-directory into this directory.

#### sides/template/
* ```dummy.side.tmpl``` - Single dummy test for an EPrints repository.  Useful for checking that CI environment can handle Selenium test results.
* ```eprints34_pub.side.tmpl``` - All tests for a publication flavour EPrints repository.
* ```eprints34_zero.side.tmpl``` - All tests for a no flavour (zero) EPrints repository.
* ```test.yml``` Like the dummy test but intended as a scratchpad for debugging issues, (e.g. different behaviours between Selenium IDE on FireFox and the Selenium Side Runner.


### templates/
This directory contains templates, effectively backups of EPrints archives that can be restored using the ```restore_eprints_template``` script.  This directory contains two (initially empty) separate directories:
* ```databases/``` - MySQL dumps of EPrints archives.
* ```archives/``` - archive sub-directory that would have been installed under EPrints' ```archives/``` directory.


