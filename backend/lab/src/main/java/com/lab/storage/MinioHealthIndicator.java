package com.lab.storage;

import io.minio.BucketExistsArgs;
import io.minio.MinioClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.health.contributor.Health;
import org.springframework.boot.health.contributor.HealthIndicator;
import org.springframework.stereotype.Component;

/**
 * Aparece como componente "minio" no /actuator/health. Verifica conectividade
 * e a existência do bucket de artigos (ADR-005). Se o MinIO cair, o backend
 * fica DOWN e o healthcheck do compose sinaliza o problema.
 */
@Component("minio")
public class MinioHealthIndicator implements HealthIndicator {

	private final MinioClient minioClient;
	private final String bucket;

	public MinioHealthIndicator(MinioClient minioClient, @Value("${minio.bucket}") String bucket) {
		this.minioClient = minioClient;
		this.bucket = bucket;
	}

	@Override
	public Health health() {
		try {
			boolean existe = minioClient.bucketExists(BucketExistsArgs.builder().bucket(bucket).build());
			if (existe) {
				return Health.up().withDetail("bucket", bucket).build();
			}
			return Health.down().withDetail("bucket", bucket).withDetail("motivo", "bucket inexistente").build();
		} catch (Exception e) {
			return Health.down(e).build();
		}
	}
}
