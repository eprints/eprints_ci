# eprints\_ci
EPrints Continuous Integration environment

## Deploying Selenium Side Runner
'''To be written'''

## Integrating with Jenkins
'''To be written'''

## Files

### Scripts

deploy.sh EPRINTS\_PATH EPRINTS\_URL
: Generates runnable Selenium SIDE files from templates
: Deploys Selenium configuration web page to EPrints repository to load configuration variables into Selenium tests.
: EPRINTS\_PATH - The filesystem path of the EPrints repository to deploy Selenium configuration web page.
: EPRINTS\_URL - The base URL of the EPrints repository.

update\_side\_template.sh SIDE\_FILEPATH
: Takes configured (i.e. base URL set) Selenium SIDE file and converts it into a template of itself.
: SIDiE\_FILEPATH - The location of the Selenium SIDE file to be used to update its template equivalent.

### Configuration

selenium.xpage
: Contains configurable options for Selenium tests that we
