<?php

namespace Heroku\Buildpack\PHP;

use Composer\Downloader\DownloaderInterface;
use Composer\IO\IOInterface;
use Composer\DependencyResolver\Operation\InstallOperation;
use Composer\Package\PackageInterface;
use React\Promise\PromiseInterface;

class NoopDownloader implements DownloaderInterface
{
	protected $io;
	protected $installMessageFormatter;
	protected $humanMessageFormatter;
	protected $humanIo;
	
	public function __construct(IOInterface $io, $installMessageFormatter = null, $humanMessageFormatter = null, IOInterface $humanIo)
	{
		$this->io = $io;
		$this->installMessageFormatter = $installMessageFormatter ?? function(PackageInterface $package, $path) { return InstallOperation::format($package); };
		$this->humanMessageFormatter = $humanMessageFormatter ?? function(PackageInterface $package, $path) { return InstallOperation::format($package); };
		$this->humanIo = $humanIo;
	}
	
	public function getInstallationSource(): string
	{
		return "dist";
	}
	
	public function download(PackageInterface $package, string $path, ?PackageInterface $prevPackage = null): PromiseInterface
	{
		return \React\Promise\resolve(null);
	}
	
	public function prepare(string $type, PackageInterface $package, string $path, ?PackageInterface $prevPackage = null): PromiseInterface
	{
		return \React\Promise\resolve(null);
	}
	
	public function install(PackageInterface $package, string $path): PromiseInterface
	{
		$this->humanIo->write(sprintf("  - %s", ($this->humanMessageFormatter)($package, $path)));
		$this->io->writeError(sprintf("  - %s", ($this->installMessageFormatter)($package, $path)));
		return \React\Promise\resolve(null);
	}
	
	public function update(PackageInterface $initial, PackageInterface $target, string $path): PromiseInterface
	{
		return \React\Promise\resolve(null);
	}
	
	public function remove(PackageInterface $package, string $path): PromiseInterface
	{
		return \React\Promise\resolve(null);
	}
	
	public function cleanup(string $type, PackageInterface $package, string $path, ?PackageInterface $prevPackage = null): PromiseInterface
	{
		return \React\Promise\resolve(null);
	}
}
