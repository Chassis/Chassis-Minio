<?php
/**
 * Filter parameters for S3 Uploads Client.
 */

add_filter( 's3_uploads_s3_client_params', function( $params ) {
	$params['endpoint'] = AWS_S3_ENDPOINT;
	$params['use_path_style_endpoint'] = true;
	$params['debug'] = false; // Useful if things aren't working to double check IPs etc
	return $params;
} );
