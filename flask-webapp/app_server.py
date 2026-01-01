# references:
# https://flask.palletsprojects.com/en/stable/patterns/fileuploads/
# https://docs.cloud.google.com/storage/docs/uploading-objects#storage-upload-object-python

import os
from flask import Flask, render_template, request, flash, redirect, url_for
from werkzeug.utils import secure_filename
from google.cloud import storage

app = Flask(__name__)

app.config["SECRET_KEY"] = "my_super_secret_key"
app.config["MAX_CONTENT_LENGTH"] = 30 * 1000 * 1000 # 30 MB limit

GCS_BUCKET_NAME_AUDIO_UPLOAD = "karaotone-prod-media-audio-upload"

def allowed_file(filename):
    ALLOWED_EXTENSIONS = {"mp3", "wav", "flac", "m4a"}
    if "." in filename:
        ext = filename.rsplit(".", 1)[1].lower()
        if ext in ALLOWED_EXTENSIONS:
            return True


def upload_blob(source_file_name, source_file):
    storage_client = storage.Client()
    bucket = storage_client.bucket(GCS_BUCKET_NAME_AUDIO_UPLOAD)
    blob = bucket.blob(source_file_name)
    blob.upload_from_file(source_file, content_type=source_file.content_type)
    print(f"File {source_file_name} uploaded to {GCS_BUCKET_NAME_AUDIO_UPLOAD}.")


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
                safe_filename = secure_filename(file.filename)
                upload_blob(safe_filename, file)
                flash("file successfully uploaded")
                return redirect(url_for("audio_download", filename=safe_filename))
    return render_template("page_layouts/audio_upload.html")


@app.route("/audio_download/<filename>")
def audio_download(filename):
    return render_template("page_layouts/audio_download.html", filename=filename)
