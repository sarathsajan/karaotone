import subprocess
from flask import Flask, request
from werkzeug.utils import secure_filename

app = Flask(__name__)

app.config["SECRET_KEY"] = "my_super_secret_key"

GCS_BUCKET_NAME_AUDIO_UPLOAD = "karaotone-prod-media-audio-upload"
GCS_BUCKET_NAME_AUDIO_PROCESSED = "karaotone-prod-media-audio-processed"


def process_and_move_blob(filename, source_bucket, destination_bucket):
    subprocess.run(
        [
            "gcloud",
            "storage",
            "mv",
            f"gs://{source_bucket}/{filename}",
            f"gs://{destination_bucket}/processed_{filename}",
        ],
        check=True,
    )


@app.route("/", methods=["GET", "POST"])
def audio_separator():
    if request.method == "POST":
        # pubsub will send the filename in the 'filename' field
        process_and_move_blob(safe_filename, GCS_BUCKET_NAME_AUDIO_UPLOAD, GCS_BUCKET_NAME_AUDIO_PROCESSED)
    return "started processing", 202
