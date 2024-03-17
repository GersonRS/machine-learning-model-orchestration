locals {
  minio_config = {
    policies = [
      {
        name = "loki-policy"
        statements = [
          {
            resources = ["arn:aws:s3:::loki-bucket"]
            actions   = ["s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
          },
          {
            resources = ["arn:aws:s3:::loki-bucket/*"]
            actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
          }
        ]
      },
      {
        name = "thanos-policy"
        statements = [
          {
            resources = ["arn:aws:s3:::thanos-bucket"]
            actions   = ["s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
          },
          {
            resources = ["arn:aws:s3:::thanos-bucket/*"]
            actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
          }
        ]
      },
      {
        name = "mlflow-policy"
        statements = [
          {
            resources = ["arn:aws:s3:::mlflow"]
            actions   = ["s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
          },
          {
            resources = ["arn:aws:s3:::mlflow/*"]
            actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
          }
        ]
      },
      {
        name = "jupyterhub-policy"
        statements = [
          {
            resources = ["arn:aws:s3:::mlflow"]
            actions   = ["s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
          },
          {
            resources = ["arn:aws:s3:::mlflow/*"]
            actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
          }
        ]
      },
      {
        name = "airflow-policy"
        statements = [
          {
            resources = ["arn:aws:s3:::airflow"]
            actions   = ["s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
          },
          {
            resources = ["arn:aws:s3:::airflow/*"]
            actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
          }
        ]
      }
    ],
    users = [
      {
        accessKey = "loki-user"
        secretKey = random_password.minio_root_secretkey.result
        policy    = "loki-policy"
      },
      {
        accessKey = "thanos-user"
        secretKey = random_password.minio_root_secretkey.result
        policy    = "thanos-policy"
      },
      {
        accessKey = "mlflow-user"
        secretKey = random_password.minio_root_secretkey.result
        policy    = "mlflow-policy"
      },
      {
        accessKey = "airflow-user"
        secretKey = random_password.minio_root_secretkey.result
        policy    = "airflow-policy"
      },
      {
        accessKey = "jupterhub-user"
        secretKey = random_password.minio_root_secretkey.result
        policy    = "jupterhub-policy"
      }
    ],
    buckets = [
      {
        name = "loki-bucket"
      },
      {
        name = "thanos-bucket"
      },
      {
        name = "mlflow"
      },
      {
        name = "airflow"
      },
      {
        name = "landing"
      },
      {
        name = "processing"
      },
      {
        name = "curated"
      },
      {
        name = "bronze"
      },
      {
        name = "silver"
      },
      {
        name = "gold"
      }
    ]
  }
}
