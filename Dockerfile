FROM python:3.8-slim
EXPOSE 5000/tcp
RUN mkdir /api_python
ADD . /api_python
WORKDIR /api_python
RUN pip3 install -r requirements.txt
ENV FLASK_APP api_python
CMD ["flask", "run", "--host", "0.0.0.0"]
