# eprints\_ci
EPrints Continuous Integration environment

## Deploying Templates and Coniguration
Run the **deploy.sh** script as the eprints user on the server hosting the EPrints repository you want to test:

    ```./deploy.sh /opt/eprints3/ http://example.eprints.org```

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
    Xvfb :99 &
    export DISPLAY=:99
    firefox --headless &
    ```

8. Now you can run a Selenium SIDE file to run tests against EPrints:

    ```selenium-side-runner -c "browserName=firefox" sides/eprints.side```
    
## Updating SIDE Template for working copies
Run the **update_side_template.sh** script to write changes to a deployed SIDE file back to the template:

    ```./update_side_template.sh sides/eprints.side```

Replace the only parameter with the file path of the deployed SIDE file you want to write back to a template.
    
## Integrating with Jenkins
**To be written**

## Files

### Scripts

```deploy.sh EPRINTS\_PATH EPRINTS\_URL```
: Generates runnable Selenium SIDE files from templates
: Deploys Selenium configuration web page to EPrints repository to load configuration variables into Selenium tests.
: EPRINTS\_PATH - The filesystem path of the EPrints repository to deploy Selenium configuration web page.
: EPRINTS\_URL - The base URL of the EPrints repository.

```update\_side\_template.sh SIDE\_FILEPATH```
: Takes configured (i.e. base URL set) Selenium SIDE file and converts it into a template of itself.
: SIDE\_FILEPATH - The location of the Selenium SIDE file to be used to update its template equivalent.

### Configuration

selenium.xpage
: Contains configurable options for Selenium tests that we
