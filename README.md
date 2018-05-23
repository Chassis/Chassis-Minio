# Minio
A Chassis extension to install and configure the Minio server and client on your Chassis server.

[Minio](https://www.minio.io/) is an open source self-hosted alternative to Amazon S3 with a compatible API.

## Installation

Via Chassis config:

```
extensions:
 - chassis/chassis-minio
```

Or clone into your extensions directory using git:

```
git clone --recursive git@github.com:Chassis/Chassis-Minio.git chassis-minio
```

Run `vagrant provision`.

Your existing uploads will be synced to the Minio server automatically.

## Usage

### File Browser

After provisioning you can browse to [http://vagrant.local/minio/](http://vagrant.local/minio/) to view the web interface and explore your bucket contents.

![](https://raw.githubusercontent.com/minio/minio/master/docs/screenshots/minio-browser.png)

### Synchronising Minio and file system uploads 

You can sync Minio and your file system uploads directory at any time by re-provisioning the VM.

Alternatively you can run:

```
vagrant ssh -c 'mc mirror local/chassis/uploads /vagrant/content/uploads'
```

To learn more about the commands available to interact with Minio check out the [Minio Client documentation](https://docs.minio.io/docs/minio-client-complete-guide).

## Configuration options
You can configure the port used by Minio server in your chassis config file.
```yaml
minio:
  port: 1234
```

Depending on how you connect to S3 you may need to set the S3 server path and region.

Check the `local-config.php` for the settings you can define.

Constants are already configured to work with the [S3 Uploads plugin](https://github.com/humanmade/S3-Uploads) so if you use that then there's nothing further to do!
