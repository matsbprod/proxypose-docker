FROM runpod/pytorch:2.1.1-py3.10-cuda12.1.1-devel-ubuntu22.04

RUN apt-get update && apt-get install -y git ninja-build && rm -rf /var/lib/apt/lists/*

# Uppgradera torch till 2.4.0 cu121
RUN pip install --no-cache-dir \
    torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 \
    --index-url https://download.pytorch.org/whl/cu121

# Klona och installera ProxyPose (pytorch3d installeras vid start istället)
RUN git clone https://github.com/ruihangzhang97/proxypose.git /opt/proxypose && \
    cd /opt/proxypose && pip install --no-cache-dir -e . --no-deps && \
    pip install --no-cache-dir \
        transformers==4.44.0 \
        gradio \
        huggingface_hub \
        diffusers \
        accelerate \
        imageio \
        imageio-ffmpeg \
        jupyterlab \
        ipykernel \
        einops \
        omegaconf

# Fixa config för lokala modellvikter
RUN sed -i 's|local_model_path: ~/.cache/proxypose/|local_model_path: /workspace/models/|' \
    /opt/proxypose/configs/generation/default.yaml && \
    sed -i 's|model_id: Wan-AI/Wan2.1-T2V-14B|model_id: Wan2.1-T2V-14B|' \
    /opt/proxypose/configs/generation/default.yaml && \
    sed -i 's|offload_text_encoder: false|offload_text_encoder: true|' \
    /opt/proxypose/configs/generation/default.yaml

ENV HF_HOME=/workspace/hf_cache
ENV HUGGINGFACE_HUB_CACHE=/workspace/hf_cache
ENV TMPDIR=/workspace/tmp

COPY start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /workspace

CMD ["/start.sh"]
