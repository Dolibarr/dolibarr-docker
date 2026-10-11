<?php
/*
 * Remove stale entries from the Composer metadata (vendor/composer/installed.json)
 * of the libraries bundled with Dolibarr.
 *
 * Dolibarr ships some libraries (e.g. webklex/php-imap) with a trimmed vendor
 * directory: the dev/test packages (phpunit, ...) and unused runtime packages
 * are deleted, but installed.json still lists them. Security scanners read this
 * file and report vulnerabilities for code that is not in the image.
 *
 * This script drops every package whose install path does not exist on disk.
 *
 * Usage: php docker-clean-vendor.php <directory>
 */

if ($argc < 2 || !is_dir($argv[1])) {
	fwrite(STDERR, "Usage: php ".$argv[0]." <directory>\n");
	exit(1);
}

$iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($argv[1], FilesystemIterator::SKIP_DOTS));
foreach ($iterator as $file) {
	if ($file->getFilename() !== 'installed.json' || basename($file->getPath()) !== 'composer') {
		continue;
	}
	$path = $file->getPathname();
	$composerDir = $file->getPath();

	$json = json_decode(file_get_contents($path), true);
	if (!is_array($json)) {
		continue;
	}
	// Composer 2 wraps the list into "packages", Composer 1 uses a plain list
	$isComposer2 = isset($json['packages']);
	$packages = $isComposer2 ? $json['packages'] : $json;

	$kept = array();
	$removed = array();
	foreach ($packages as $package) {
		$installPath = isset($package['install-path']) ? $package['install-path'] : '../'.$package['name'];
		if (is_dir($composerDir.'/'.$installPath)) {
			$kept[] = $package;
		} else {
			$removed[] = $package['name'];
		}
	}

	if (empty($removed)) {
		continue;
	}

	if ($isComposer2) {
		$json['packages'] = $kept;
		if (isset($json['dev-package-names'])) {
			$json['dev-package-names'] = array_values(array_diff($json['dev-package-names'], $removed));
		}
	} else {
		$json = $kept;
	}

	file_put_contents($path, json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE)."\n");
	echo $path.": removed ".count($removed)." missing package(s): ".implode(', ', $removed)."\n";
}
