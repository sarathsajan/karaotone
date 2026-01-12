# use the official lightweight Python base image
FROM python:3.11-slim

# create and move into the working directory
WORKDIR /app

# copy the requirements file
COPY requirements.txt requirements.txt

# install the dependencies from the requirements file
RUN pip install -r requirements.txt

# copy the rest of the files into the working directory
COPY . .

# Cloud Run automatically sets the PORT environment variable.
# We need to expose the port (standard practice)
EXPOSE 8080

# Use Gunicorn to serve the Flask app ('app_audioseparator:app') 
# and bind it to 0.0.0.0 using the $PORT environment variable provided by Cloud Run.
# The 'exec' ensures signals are handled correctly by the process.
CMD exec gunicorn --bind 0.0.0.0:$PORT --workers 1 --threads 1 --timeout 0 app_audioseparator:app