FROM runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04

RUN apt-get update && apt-get install -y git ninja-build && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    "git+https://github.com/facebookresearch/pytorch3d.git@stable"

RUN git clone https://github.com/ruihangzhang97/proxypose.git /opt/proxypose && \
    cd /opt/proxypose && pip install --no-cache-dir -e .

RUN pip install --no-cache-dir gradio huggingface_hub diffusers transformers accelerate imageio imageio-ffmpeg

WORKDIR /workspace
RUN pip install --no-cache-dir jupyterlab

CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''"]
