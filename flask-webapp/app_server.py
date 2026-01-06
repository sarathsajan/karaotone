# references:
# https://flask.palletsprojects.com/en/stable/patterns/fileuploads/
# https://docs.cloud.google.com/storage/docs/uploading-objects#storage-upload-object-python

import datetime
from flask import Flask, render_template, request, flash, redirect, url_for
from werkzeug.utils import secure_filename
from google.cloud import storage, pubsub_v1
from datetime import datetime
import json

app = Flask(__name__)

app.config["SECRET_KEY"] = "my_super_secret_key"
app.config["MAX_CONTENT_LENGTH"] = 30 * 1000 * 1000  # 30 MB limit

PROJECT_ID = "karaotone-prod"
GCS_BUCKET_NAME_AUDIO_UPLOAD = "karaotone-prod-media-audio-upload"
PUBSUB_TOPIC_ID = "audio-processing-requests"


def allowed_file(filename):
    ALLOWED_EXTENSIONS = {"mp3", "wav", "flac", "m4a"}
    if "." in filename:
        ext = filename.rsplit(".", 1)[1].lower()
        if ext in ALLOWED_EXTENSIONS:
            return True
    return False


def upload_blob(source_file_name, source_file):
    storage_client = storage.Client()
    bucket = storage_client.bucket(GCS_BUCKET_NAME_AUDIO_UPLOAD)
    blob = bucket.blob(source_file_name)
    blob.upload_from_file(source_file, content_type=source_file.content_type)
    print(f"File {source_file_name} uploaded to {GCS_BUCKET_NAME_AUDIO_UPLOAD}.")
    flash("file successfully uploaded")


def publish_to_pubsub_topic(filename):
    # Implementation for publishing to Pub/Sub topic
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(PROJECT_ID, PUBSUB_TOPIC_ID)
    message_json = json.dumps({"filename": filename}).encode()
    try:
        future = publisher.publish(topic_path, data=message_json)
        future.result(timeout=10)   # Verify the publish succeeded
        print(f"Published message to {PUBSUB_TOPIC_ID}: {filename}")
        flash("file sent for processing")
    except Exception as e:
        print(f"Failed to publish message to {PUBSUB_TOPIC_ID}: {e}")
        flash("failed to send file for processing")


@app.route("/")
def home():
    return render_template("page_layouts/home.html")


@app.route("/devlog")
def devlog():
    return render_template("page_layouts/devlog.html")


@app.route("/techstack")
def techstack():
    return render_template("page_layouts/techstack.html")


@app.route("/techstack/bsroformer")
def techstack_individual():
    return render_template("page_layouts/techstack_bsroformer.html")


@app.route("/ref_layout")
def ref_layout():
    return render_template("reference_layout.html")


@app.route("/audio_upload", methods=["GET", "POST"])
def audio_upload():
    if request.method == "POST":
        # check if the post request has the file part
        if "file" not in request.files:
            flash("no file part")
            return redirect(request.url)
        file = request.files["file"]
        # if the user does not select a file, the browser submits an empty file without a filename.
        if file:
            if file.filename == "":
                flash("no file selected")
                return redirect(request.url)
            if not allowed_file(file.filename):
                flash("file type not allowed")
                return redirect(request.url)
            if allowed_file(file.filename):
                safe_filename = (datetime.now().strftime("%Y%m%d%H%M%S%f")+ "_"+ secure_filename(file.filename))
                processed_safe_filename = "processed_" + safe_filename
                upload_blob(safe_filename, file)
                publish_to_pubsub_topic(safe_filename)
                return redirect(url_for("audio_download", filename=processed_safe_filename))
    return render_template("page_layouts/audio_upload.html")


@app.route("/audio_download/<filename>")
def audio_download(filename):
    return render_template("page_layouts/audio_download.html", filename=filename)
