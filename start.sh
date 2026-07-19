#!/bin/bash

# ============================================================
# KRITISKA ENV-VARIABLER — måste sättas innan allt annat
# för att undvika att container-disken (20GB) fylls
# ============================================================
export HF_HOME=/workspace/hf_cache
export HUGGINGFACE_HUB_CACHE=/workspace/hf_cache
export TRANSFORMERS_CACHE=/workspace/hf_cache
export TMPDIR=/workspace/tmp
export XDG_CACHE_HOME=/workspace/cache

mkdir -p /workspace/hf_cache /workspace/tmp /workspace/cache /workspace/models /workspace/video

# ============================================================
# FIXA CONFIG — pekar på lokala modellvikter
# ============================================================
sed -i 's|local_model_path: ~/.cache/proxypose/|local_model_path: /workspace/models/|' \
    /opt/proxypose/configs/generation/default.yaml 2>/dev/null
sed -i 's|model_id: Wan-AI/Wan2.1-T2V-14B|model_id: Wan2.1-T2V-14B|' \
    /opt/proxypose/configs/generation/default.yaml 2>/dev/null
sed -i 's|offload_text_encoder: false|offload_text_encoder: true|' \
    /opt/proxypose/configs/generation/default.yaml 2>/dev/null

# ============================================================
# LADDA NER WAN2.1 MODELL om den saknas
# ============================================================
if [ ! -f "/workspace/models/Wan2.1-T2V-14B/diffusion_pytorch_model-00001-of-00006.safetensors" ]; then
    echo "Laddar ner Wan2.1-T2V-14B (~55GB) till /workspace/models/..."
    huggingface-cli download Wan-AI/Wan2.1-T2V-14B \
        --local-dir /workspace/models/Wan2.1-T2V-14B
    echo "Modell nedladdad."
else
    echo "Wan2.1-T2V-14B redan nedladdad."
fi

# ============================================================
# LADDA NER VIDEOFILER från Google Drive
# ============================================================
echo "Synkar videofiler från Google Drive..."
pip install gdown --upgrade --quiet 2>/dev/null
gdown --folder "https://drive.google.com/drive/folders/1uzOTk29f-J3LvyCenyyGw2RO6W1aKZTE" \
    -O /workspace/video/ 2>/dev/null || echo "gdown misslyckades, hoppar över."

# ============================================================
# INSTALLERA SAKNADE PYTHON-PAKET
# ============================================================
python -c "import cv2" 2>/dev/null || pip install opencv-python-headless --quiet
python -c "import decord" 2>/dev/null || pip install decord --quiet
python -c "import scipy" 2>/dev/null || pip install scipy --quiet
python -c "import diffsynth" 2>/dev/null || pip install diffsynth --quiet

# ============================================================
# BYGG/INSTALLERA PYTORCH3D (sparas till /workspace)
# ============================================================
if ! python -c "import pytorch3d" 2>/dev/null; then
    if [ -d "/workspace/pytorch3d_wheel" ] && ls /workspace/pytorch3d_wheel/*.whl 2>/dev/null; then
        echo "Installerar pytorch3d från sparad wheel..."
        pip install --no-index --find-links=/workspace/pytorch3d_wheel pytorch3d
    else
        echo "Bygger pytorch3d från source (tar ~15 min)..."
        mkdir -p /workspace/pytorch3d_wheel
        FORCE_CUDA=1 pip wheel --no-cache-dir --no-build-isolation \
            "git+https://github.com/facebookresearch/pytorch3d.git@stable" \
            -w /workspace/pytorch3d_wheel
        pip install --no-index --find-links=/workspace/pytorch3d_wheel pytorch3d
        echo "pytorch3d sparad till /workspace/pytorch3d_wheel"
    fi
fi

echo "=== Setup klar. Startar Jupyter... ==="

# Starta Jupyter
exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token=''
