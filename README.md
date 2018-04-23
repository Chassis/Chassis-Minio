# Minio
A Chassis extension to install and configure the Minio server and client on your Chassis server.

[Minio](https://www.minio.io/) is an open source self-hosted alternative to Amazon S3 with a compatible API.

## Usage
1. Add this extension to your extensions directory `git clone git@github.com:Chassis/Chassis-Minio.git extensions/chassis-minio`
2. Run `vagrant provision`.
3. Copy the `minio-mu-plugin.php` file to your `mu-plugins` directory to get S3 Uploads working.

Your existing uploads will be synced to the Minio server automatically.

After provisioning you can browse to http://vagrant.local:4571/ to view the web interface and explore your bucket contents.

![](https://raw.githubusercontent.com/minio/minio/master/docs/screenshots/minio-browser.png)

## Configuration options
You can configure the port used by Minio server in your chassis config file.
```yaml
minio:
  port: 1234
```

Depending on how you connect to S3 you may need to set the S3 server path and region.

Check the `local-config.php` for the settings you can define.

Constants are already configured to work with the [S3 Uploads plugin](https://github.com/humanmade/S3-Uploads) so if you use that then there's nothing further to do!
