# Contributing

1. List one head Dolibarr version for each Major release in the file `versions.sh`.
2. Keep only one Dockerfile.template file, use `sed` value replacement in `update.sh`
3. Keep most up to date PHP version that matches each [Dolibarr releases](https://wiki.dolibarr.org/index.php/Versions).
4. Be careful about [supported PHP versions](https://www.php.net/supported-versions.php), try to avoid deprecated PHP version, but only if it doesn't break rule #3.
5. Run the `update.sh` script to generate all the files rquired to build each Docker images.
6. Check the `README.md`, to ensure it is well formatted (on some environment `Supported Tags` could be broken) 
7. Commit all content in `images` directory
8. Open a pull request with a polite and well described content ^_^


# How to create images

All is done through the `update.sh` script, Dolibarr versions to build are stored in `versions.sh`
Ensure that the var `DOLIBARR_VERSIONS` in `versions.sh` is having all versions you want to build.
Just run the script update.sh.

## Tips
You can ask the script to build and push version for you: just add `DOCKER_BUILD=1` and `DOCKER_PUSH=1` in command line.
```bash
$> DOCKER_BUILD=1 DOCKER_PUSH=1 ./update.sh
```


# Test your local copy before PR

For convenience, you can use the `test.sh` script, it will build and run containers based on existing Dockerfile in `images` directory. (You'd better run `update.sh` before)
```bash
$> sudo ./test.sh <DOLIBARR_VERSION> <PHP_VERSION>
```
* DOLIBARR_VERSION : (Mandatory) the version you want to build and run.
* PHP_VERSION : (Optional) the Dolibarr version with this PHP version you want to run specifically, if omitted it will use the most up to date PHP version.

If you want to run Dolibarr 14.0.3 with PHP 7.4
```bash
$> sudo ./test.sh 14.0.3 7.4
```
If you want to run Dolibarr 14.0.3 with most up-to-date PHP version
```bash
$> sudo ./test.sh 14.0.3
```

If you want to run Dolibarr develop with most up-to-date PHP version
```bash
$> sudo ./test.sh develop
```

Here are links for running containers :
* [http://localhost/](http://localhost/) => Dolibarr instance
