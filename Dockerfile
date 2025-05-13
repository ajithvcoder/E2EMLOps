FROM pytorch/pytorch:2.6.0-cuda12.4-cudnn9-runtime

WORKDIR /workspace
COPY . .
RUN pip install -r requirements.gpu.txt

# CMD ["python", "src/train.py"]
CMD ["tail", "-f", "/dev/null"]

