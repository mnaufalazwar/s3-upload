from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    aws_access_key_id: str | None = None
    aws_secret_access_key: str | None = None
    aws_region: str = "ap-southeast-1"
    s3_bucket_name: str

    class Config:
        env_file = ".env"

settings = Settings()